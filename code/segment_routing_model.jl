# =============================================================================
#  Step 5 (readme) — Mô hình cho MỘT kỳ (t = 0), không có ràng buộc budget (4)
#
#  Biến (tên trong code ↔ ký hiệu trong đề):
#    x[d, i, j] ∈ {0,1}   x^{d,t}_{ij}   1 nếu đường segment của demand d dùng segment i → j
#    mlu ≥ 0              λ               utilization của cung nặng nhất (MLU)
#
#  min  mlu
#  (1)  Σ_j x[d,i,j] − Σ_j x[d,j,i] = 1 nếu i = s_d, −1 nếu i = t_d, 0 nếu khác   ∀ d, i
#  (2)  Σ_{i,j} x[d,i,j] ≤ MaxSeg                                                 ∀ d
#  (3)  Σ_d Σ_{i,j} r(i,j,a) v(d) x[d,i,j] ≤ mlu · c(a)                           ∀ a ∈ A(t)
#       (code chia hai vế cho c(a): hệ số r·v/c nhỏ, cùng cỡ → HiGHS ổn định số hơn)
#  Hàm mục tiêu của đề là lex-min mọi tải; min mlu là bậc đầu tiên của lex-min.
#
#  Dùng từ file khác / REPL : include("segment_routing_model.jl")    → chỉ nạp các hàm
#  Chạy phần kiểm tra cuối file (trong thư mục code/):
#    julia --project=. segment_routing_model.jl   (REPL: check_segment_routing_model())
# =============================================================================

@isdefined(baseline_mlu) || include("baseline_mlu.jl")
using JuMP, HiGHS

"Dựng mô hình Step 5 từ Section Data `data` = model_data(inst, p). Trả về (model, x, mlu)."
function build_model(data)
    V, D = data.vertices, data.demands
    # direct_model: JuMP ghi thẳng vào HiGHS, không giữ thêm một bản sao (đỡ một nửa RAM)
    model = direct_model(HiGHS.Optimizer())
    set_string_names_on_creation(model, false)   # không tạo tên "x[1,2,3]" cho hàng triệu biến

    @variable(model, x[d in D, i in V, j in V], Bin)
    for d in D, i in V
        fix(x[d, i, i], 0; force = true)         # đề chỉ có x[d,i,j] với i ≠ j
    end
    @variable(model, mlu >= 0)
    @objective(model, Min, 1.0 * mlu)   # "1.0 *": direct_model không chuyển được mục tiêu dạng một biến đơn

    # (1) bảo toàn luồng
    @constraint(model, [d in D, i in V],
        sum(x[d, i, j] for j in V if j != i) - sum(x[d, j, i] for j in V if j != i) ==
        (i == data.src[d] ? 1 : i == data.dst[d] ? -1 : 0))
    # (2) số segment
    @constraint(model, [d in D], sum(x[d, i, j] for i in V, j in V if i != j) <= data.max_segments)
    # (3) tải: utilization[a] = Σ r·v/c · x  ≤  mlu
    utilization = Dict(a => AffExpr(0.0) for a in data.arcs)
    for j in V, i in V, (a, r) in data.ratios[i, j], d in D
        iszero(data.volume[d]) && continue
        add_to_expression!(utilization[a], r * data.volume[d] / data.capacity[a], x[d, i, j])
    end
    for a in data.arcs
        @constraint(model, utilization[a] <= mlu)
    end
    return model, x, mlu
end

"""
Nghiệm xuất phát cho HiGHS: mọi demand đi thẳng s_d → t_d (không waypoint) — luôn khả thi,
mlu = MLU baseline. Nhờ vậy ngay từ đầu đã có best ≤ baseline và gap tính được, kể cả khi
HiGHS không tự tìm ra nghiệm nào trong giới hạn thời gian (setA-04 trở đi).
"""
function start_from_baseline!(x, mlu, data)
    for d in data.demands, i in data.vertices, j in data.vertices
        set_start_value(x[d, i, j], (i, j) == (data.src[d], data.dst[d]) ? 1.0 : 0.0)
    end
    set_start_value(mlu, first(baseline_mlu(data)))
    return nothing
end

"""
Giải và trả về đúng các cột readme cần: status, giá trị tốt nhất (best), cận dưới (bound),
gap = 1 − bound/best, số node B&B, thời gian của riêng optimize! (giây).
"""
function solve_model!(model; time_limit = 1800.0, seed = 0, silent = false)
    set_time_limit_sec(model, time_limit)
    set_attribute(model, "random_seed", seed)
    silent && set_silent(model)
    seconds = @elapsed optimize!(model)
    has_solution = primal_status(model) == FEASIBLE_POINT
    best = has_solution ? objective_value(model) : NaN
    bound = objective_bound(model)
    return (
        status = termination_status(model),
        best = best,
        bound = bound,
        gap = has_solution ? 1 - bound / best : NaN,
        nodes = MOI.get(model, MOI.NodeCount()),
        seconds = seconds,
    )
end

"Đường segment của mỗi demand đọc từ nghiệm: paths[d] = [s_d, waypoint..., t_d]."
function segment_paths(x, data)
    x_value = value.(x)
    paths = Vector{Vector{Int}}()
    for d in data.demands
        path = [data.src[d]]
        used = Set{Tuple{Int,Int}}()
        while path[end] != data.dst[d]
            length(path) - 1 >= data.max_segments && error("demand $d: đã dùng MaxSeg segment mà chưa tới đích")
            i = path[end]
            j = findfirst(j -> j != i && x_value[d, i, j] > 0.5 && !((i, j) in used), data.vertices)
            j === nothing && error("demand $d: không có segment nào ra khỏi đỉnh $i")
            push!(used, (i, j))
            push!(path, j)
        end
        push!(paths, path)
    end
    return paths
end

"MLU tính lại từ các đường segment (độc lập với biến mlu của mô hình) — để kiểm tra mô hình."
function routing_mlu(data, paths)
    load = zeros(length(data.capacity))
    for d in data.demands, k in 1:length(paths[d])-1
        for (a, r) in data.ratios[paths[d][k], paths[d][k+1]]
            load[a] += data.volume[d] * r
        end
    end
    return first(max_utilization(load, data.capacity, data.arcs))
end

# ---------------------------------------------------------------- kiểm tra
# Hàm riêng để mọi biến là biến cục bộ (không đụng biến cùng tên trong REPL).
"Kiểm tra nhanh: toy và setA-01..03 ở t = 0, giới hạn 60 s mỗi instance."
function check_segment_routing_model()
    for prefix in ("../toy/toy", "../setA/setA-01", "../setA/setA-02", "../setA/setA-03")
        inst = json_to_instance(prefix)
        data = model_data(inst, 1)
        build_seconds = @elapsed (model, x, mlu) = build_model(data)
        result = solve_model!(model; time_limit = 60.0, silent = true)
        paths = segment_paths(x, data)
        println(inst.name, " (t = 0): |V| = ", length(data.vertices), ", |A| = ", length(data.arcs),
                ", |D| = ", length(data.demands), ", dựng mô hình ", round(build_seconds; digits = 1), " s")
        println("    ", result.status, ": best = ", round(result.best; digits = 4),
                ", bound = ", round(result.bound; digits = 4), ", gap = ", round(result.gap; digits = 4),
                ", nodes = ", result.nodes, ", optimize! = ", round(result.seconds; digits = 2), " s")
        println("    baseline = ", round(first(baseline_mlu(data)); digits = 4),
                ",  MLU tính lại từ đường segment = ", round(routing_mlu(data, paths); digits = 4),
                ",  số demand dùng waypoint = ", count(p -> length(p) > 2, paths))
        inst.name == "toy" && for d in data.demands
            println("    demand ", d, ": ", join(('A' + v - 1 for v in paths[d]), " → "))
        end
    end
end

# Gọi thẳng file này (julia --project=. segment_routing_model.jl) thì chạy kiểm tra; include thì không.
if abspath(PROGRAM_FILE) == @__FILE__
    check_segment_routing_model()
end
