# =============================================================================
#  Heuristic tham lam (greedy) tạo nghiệm xuất phát cho MIP — cấu hình thứ hai, thay cho baseline.
#
#  Lặp lại: lấy cung có utilization lớn nhất (worst); với mỗi demand d có tải trên worst, thử đổi
#  đường của d thành s → w → t (một waypoint w, thử mọi w) hoặc s → t; thực hiện nước đi làm
#  (MLU, utilization của worst) giảm nhiều nhất. Dừng khi không còn nước đi nào làm giảm,
#  hoặc hết time_limit giây. Mỗi đường có ≤ 2 segment ≤ MaxSeg nên nghiệm luôn thỏa (1)–(3).
#
#  Step 9 (nhiều kỳ): lấy phương án có max MLU các kỳ nhỏ nhất trong
#    - baseline (đi thẳng) ở mọi kỳ;
#    - greedy của kỳ k dùng cho MỌI kỳ (0 thay đổi, luôn thỏa budget), với từng k;
#    - mỗi kỳ dùng greedy của chính nó (chỉ khi số thay đổi ≤ κ).
#
#  Dùng từ file khác / REPL : include("greedy_waypoints.jl")
#  Chạy phần kiểm tra cuối file (trong thư mục code/):
#    julia --project=. greedy_waypoints.jl   (REPL: check_greedy_waypoints())
# =============================================================================

@isdefined(build_multi_period_model) || include("multi_period_model.jl")

"Cộng (sign = +1) hoặc trừ (sign = −1) utilization do đường segment `path` chở lưu lượng v gây ra."
function add_path!(util, data, path, v, sign)
    for k in 1:length(path)-1, (a, r) in data.ratios[path[k], path[k+1]]
        util[a] += sign * r * v / data.capacity[a]
    end
end


path_arcs(data, path) = (a for k in 1:length(path)-1 for (a, _) in data.ratios[path[k], path[k+1]])

"Utilization lớn nhất trên các cung mà đường `path` đi qua."
path_max(util, data, path) = maximum((util[a] for a in path_arcs(data, path)); init = 0.0)

"Giá trị util hiện tại trên các cung của `path`, để khôi phục ĐÚNG TỪNG BIT (cộng rồi trừ lại thì lệch 1 ulp)."
saved_util(util, data, path) = [(a, util[a]) for a in path_arcs(data, path)]
restore_util!(util, saved) = foreach(((a, u),) -> util[a] = u, saved)

"Nghiệm greedy của một kỳ: paths[d] = [s_d, (waypoint), t_d] và MLU của nó (tính lại bằng routing_mlu)."
function greedy_waypoints(data; time_limit = 300.0)
    deadline = time() + time_limit
    D = [d for d in data.demands if !iszero(data.volume[d])]
    paths = [[data.src[d], data.dst[d]] for d in data.demands]
    util = zeros(length(data.capacity))
    foreach(d -> add_path!(util, data, paths[d], data.volume[d], 1), D)
    current_max() = maximum(util[a] for a in data.arcs)
    while time() < deadline
        worst = data.arcs[argmax(util[data.arcs])]
        best_key, best_move = (current_max(), util[worst]), nothing
        for d in D
            any(==(worst), path_arcs(data, paths[d])) || continue
            s, t, v = data.src[d], data.dst[d], data.volume[d]
            saved_current = saved_util(util, data, paths[d])
            add_path!(util, data, paths[d], v, -1)
            # Thêm candidate chỉ làm TĂNG tải trên các cung của nó, các cung khác giữ nguyên ⇒
            # MLU sau khi thêm = max(others, max trên cung của candidate): O(cung của candidate) thay vì O(m).
            others = current_max()
            for w in data.vertices
                w == t && continue
                # "Đường hầm ma": segment không có đường đi thì ratios rỗng → tải 0, greedy sẽ chọn nhầm.
                # split_ratios đã báo lỗi khi G_t không liên thông mạnh; dòng này giữ greedy đúng cả khi bỏ kiểm tra đó.
                w != s && (isempty(data.ratios[s, w]) || isempty(data.ratios[w, t])) && continue
                candidate = w == s ? [s, t] : [s, w, t]          # w = s: đi thẳng
                saved = saved_util(util, data, candidate)
                add_path!(util, data, candidate, v, 1)
                key = (max(others, path_max(util, data, candidate)), util[worst])
                key < best_key && ((best_key, best_move) = (key, (d, candidate)))
                restore_util!(util, saved)
            end
            restore_util!(util, saved_current)
        end
        best_move === nothing && break
        d, candidate = best_move
        add_path!(util, data, paths[d], data.volume[d], -1)
        paths[d] = candidate
        add_path!(util, data, paths[d], data.volume[d], 1)
    end
    return paths, routing_mlu(data, paths)
end

path_segments(path) = [(path[k], path[k+1]) for k in 1:length(path)-1]

"Số thay đổi Σ_d Σ_{i≠j} |x_k − x_{k−1}| giữa hai định tuyến (vế trái của (4))."
count_changes(paths_a, paths_b) = sum(length(symdiff(path_segments(p), path_segments(q))) for (p, q) in zip(paths_a, paths_b))

"Phương án xuất phát cho mọi kỳ: plan[k] = paths của kỳ k. Trả về (plan, max MLU các kỳ)."
greedy_plan(datas, budgets; time_limit = 300.0) =
    best_plan(datas, budgets, [first(greedy_waypoints(data; time_limit)) for data in datas])

"""
Phương án tốt nhất khi đã có greedy[k] = nghiệm greedy riêng của kỳ k. Mỗi datas[k] chỉ được đọc MỘT lần
(kỳ ở vòng ngoài), nên datas có thể tính dữ liệu từng kỳ khi được hỏi (xem save_greedy_results.jl).
"""
function best_plan(datas, budgets, greedy)
    direct = [[path[1], path[end]] for path in greedy[1]]
    candidates = [fill(paths, length(greedy)) for paths in [greedy; [direct]]]
    all(count_changes(greedy[k - 1], greedy[k]) <= budgets[k] for k in 2:length(greedy)) && push!(candidates, greedy)
    worst = zeros(length(candidates))                  # worst[c] = max MLU các kỳ của phương án c
    for k in eachindex(greedy)
        data = datas[k]
        worst .= max.(worst, [routing_mlu(data, plan[k]) for plan in candidates])
    end
    best = argmin(worst)
    return candidates[best], worst[best]
end

"x_period[d, i, j] = 1 nếu i → j là một segment của paths[d], ngược lại 0."
function set_path_start!(x_period, data, paths)
    for d in data.demands
        on_path = Set(path_segments(paths[d]))
        for i in data.vertices, j in data.vertices
            set_start_value(x_period[d, i, j], (i, j) in on_path ? 1.0 : 0.0)
        end
    end
end

"Step 5: bắt đầu từ paths (thay cho start_from_baseline!)."
function start_from_paths!(x, mlu, data, paths)
    set_path_start!(x, data, paths)
    set_start_value(mlu, routing_mlu(data, paths))
    return nothing
end

"Step 8: bắt đầu từ plan (thay cho start_all_periods_from_baseline!); added = segment được thêm ở kỳ k."
function start_all_periods_from_plan!(x, added, mlu, datas, plan)
    for k in eachindex(datas)
        set_path_start!(view(x, :, k, :, :), datas[k], plan[k])
    end
    V = datas[1].vertices
    for d in datas[1].demands, k in 2:length(datas)
        new_segments = Set(setdiff(path_segments(plan[k][d]), path_segments(plan[k - 1][d])))
        for i in V, j in V
            set_start_value(added[d, k, i, j], (i, j) in new_segments ? 1.0 : 0.0)
        end
    end
    changes = owner_model(mlu)[:changes]
    for d in datas[1].demands, k in 2:length(datas)
        set_start_value(changes[d, k], length(symdiff(path_segments(plan[k][d]), path_segments(plan[k - 1][d]))))
    end
    set_start_value(mlu, maximum(routing_mlu(datas[k], plan[k]) for k in eachindex(datas)))
    return nothing
end

# ---------------------------------------------------------------- kiểm tra
"""
Kiểm tra trên toy, setA-01..03: greedy ≥ tối ưu đã biết (Step 6), số thay đổi ≤ κ, và nghiệm
xuất phát thỏa MỌI ràng buộc (primal_feasibility_report rỗng) của cả mô hình 1 kỳ lẫn 2 kỳ.
"""
function check_greedy_waypoints()
    optimum = Dict("toy" => 0.375, "setA-01" => 0.9294, "setA-02" => 0.5486, "setA-03" => 0.9435)
    for prefix in ("../toy/toy", "../setA/setA-01", "../setA/setA-02", "../setA/setA-03")
        inst = json_to_instance(prefix)
        datas, budgets = multi_period_data(inst)
        seconds = @elapsed (plan, plan_mlu) = greedy_plan(datas, budgets)
        paths, single_mlu = greedy_waypoints(datas[1])
        model, x, mlu = build_model(datas[1])
        start_from_paths!(x, mlu, datas[1], paths)
        single_ok = isempty(primal_feasibility_report(start_value, model; atol = 1e-7))
        model, x, added, mlu = build_multi_period_model(datas, budgets)
        start_all_periods_from_plan!(x, added, mlu, datas, plan)
        multi_ok = isempty(primal_feasibility_report(start_value, model; atol = 1e-7))
        changes = count_changes(plan[1], plan[2])
        println(inst.name, ": greedy t=0 ", round(single_mlu; digits = 4), " (tối ưu ", optimum[inst.name], ")",
                ", start khả thi: ", single_ok,
                " | 2 kỳ: ", round(plan_mlu; digits = 4), ", thay đổi ", changes, " ≤ κ = ", budgets[2], ": ", changes <= budgets[2],
                ", start khả thi: ", multi_ok, " | greedy ", round(seconds; digits = 2), " s")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    check_greedy_waypoints()
end
