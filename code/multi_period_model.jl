# =============================================================================
#  Step 7–8 (readme) — Mô hình nhiều kỳ có ràng buộc budget (4). Step 9 dùng t = 0, 1.
#
#  Step 7: dữ liệu kỳ t = 1 = model_data(inst, 2): G_1 bỏ các cung q(1), r tính lại trên G_1,
#          lưu lượng v(d, 1); thêm budget κ(1) = inst.budget[2] (kỳ đầu không có budget: Inf).
#  Step 8: biến (k = p = t + 1 là chỉ số kỳ trong code)
#    x[d, k, i, j] ∈ {0,1}   x^{d,t}_{ij}     định tuyến của kỳ k
#    mlu ≥ 0                 λ                 utilization lớn nhất trên MỌI cung, MỌI kỳ
#    added[d, k, i, j] ≥ 0                     = 1 nếu segment i → j được THÊM vào đường của d ở kỳ k
#    changes[d, k] ≥ 0                         số thay đổi của demand d ở kỳ k (vế trái của (4) tách theo d)
#
#    min  mlu
#    (1)–(3) cho từng kỳ k với dữ liệu của kỳ k            (utilization(a, k) ≤ mlu  ∀ a ∈ A(k))
#    (4)  Σ_d Σ_{i≠j} |x[d,k,i,j] − x[d,k−1,i,j]| ≤ κ(k)  ∀ k ≥ 2
#  Tuyến tính hoá (4) bằng |a| = 2·max(0, a) − a  (một ràng buộc cho mỗi (d, i, j), thay vì hai
#  ràng buộc z ≥ ±a như cách quen thuộc — mô hình 2 kỳ rất lớn nên đỡ được nhiều RAM):
#    added[d,k,i,j] ≥ x[d,k,i,j] − x[d,k−1,i,j]
#    changes[d,k] = 2 Σ_{i≠j} added[d,k,i,j] − Σ_{i≠j} (x[d,k,i,j] − x[d,k−1,i,j])      ∀ d
#    Σ_d changes[d,k] ≤ κ(k)
#  (Viết (4) thành MỘT hàng chứa mọi biến x, added thì presolve HiGHS chạy hàng giờ, bỏ qua time limit:
#   Step 9 setA-04 mất 23 794 s presolve. Tách theo demand: presolve 89 s, cùng tập nghiệm.)
#  (added nhỏ nhất có thể = max(0, a) cho đúng Σ|a|; added lớn hơn chỉ làm vế trái lớn hơn.)
#
#  Dùng từ file khác / REPL : include("multi_period_model.jl")    → chỉ nạp các hàm
#  Chạy phần kiểm tra cuối file (trong thư mục code/):
#    julia --project=. multi_period_model.jl   (REPL: check_multi_period_model())
# =============================================================================

@isdefined(build_model) || include("segment_routing_model.jl")

"Step 7: Section Data của các kỳ p ∈ periods và budget κ của từng kỳ (kỳ đầu: Inf)."
multi_period_data(inst::Instance, periods = 1:2; rule = :pathcount) =
    ([model_data(inst, p; rule) for p in periods], inst.budget[periods])

"Ràng buộc (1)–(3) của một kỳ; x_period[d, i, j] là biến x của kỳ đó."
function add_period_constraints!(model, x_period, mlu, data)
    V, D = data.vertices, data.demands
    @constraint(model, [d in D, i in V],
        sum(x_period[d, i, j] for j in V if j != i) - sum(x_period[d, j, i] for j in V if j != i) ==
        (i == data.src[d] ? 1 : i == data.dst[d] ? -1 : 0))
    @constraint(model, [d in D], sum(x_period[d, i, j] for i in V, j in V if i != j) <= data.max_segments)
    # (3) dựng TỪNG cung: biểu thức của cung a đưa vào HiGHS rồi bỏ ngay, thay vì giữ biểu thức
    # của mọi cung cùng lúc như Step 5 (phần đó chiếm phần lớn RAM khi dựng mô hình 2 kỳ).
    pairs_on = [Tuple{Int,Int,Float64}[] for _ in eachindex(data.capacity)]   # pairs_on[a] = [(i, j, r), ...]
    for j in V, i in V, (a, r) in data.ratios[i, j]
        push!(pairs_on[a], (i, j, r))
    end
    for a in data.arcs
        utilization = AffExpr(0.0)
        for (i, j, r) in pairs_on[a], d in D
            iszero(data.volume[d]) && continue
            add_to_expression!(utilization, r * data.volume[d] / data.capacity[a], x_period[d, i, j])
        end
        @constraint(model, utilization <= mlu)
    end
    return nothing
end

"Step 8: dựng mô hình nhiều kỳ. Trả về (model, x, added, mlu)."
function build_multi_period_model(datas, budgets)
    V, D, P = datas[1].vertices, datas[1].demands, length(datas)
    n = length(V)
    model = direct_model(HiGHS.Optimizer())
    set_string_names_on_creation(model, false)

    # Viết thẳng "1:n" (không dùng biến V) để JuMP tạo mảng Julia thường — view(x, :, k, :, :) mới dùng được value.()
    @variable(model, x[d in D, k in 1:P, i in 1:n, j in 1:n], Bin)
    for d in D, k in 1:P, i in V
        fix(x[d, k, i, i], 0; force = true)
    end
    @variable(model, mlu >= 0)
    @objective(model, Min, 1.0 * mlu)
    for k in 1:P
        add_period_constraints!(model, view(x, :, k, :, :), mlu, datas[k])
    end

    # (4) budget. added[d, k, i, i] không dùng tới (cột rỗng, HiGHS presolve tự bỏ).
    @variable(model, added[d in D, k in 2:P, i in V, j in V] >= 0)
    @variable(model, changes[d in D, k in 2:P] >= 0)
    for k in 2:P
        isfinite(budgets[k]) || continue
        for d in D, i in V, j in V
            i == j && continue
            @constraint(model, added[d, k, i, j] >= x[d, k, i, j] - x[d, k - 1, i, j])
        end
        for d in D
            @constraint(model, changes[d, k] == 2 * sum(added[d, k, i, j] for i in V, j in V if i != j) -
                                                sum(x[d, k, i, j] - x[d, k - 1, i, j] for i in V, j in V if i != j))
        end
        @constraint(model, sum(changes[d, k] for d in D) <= budgets[k])
    end
    return model, x, added, mlu
end

"Nghiệm xuất phát: mọi kỳ đều đi thẳng s_d → t_d (cùng định tuyến ⇒ không tốn budget, luôn khả thi)."
function start_all_periods_from_baseline!(x, added, mlu, datas)
    D, V = datas[1].demands, datas[1].vertices
    for d in D, k in eachindex(datas), i in V, j in V
        set_start_value(x[d, k, i, j], (i, j) == (datas[k].src[d], datas[k].dst[d]) ? 1.0 : 0.0)
    end
    foreach(v -> set_start_value(v, 0.0), added)
    foreach(v -> set_start_value(v, 0.0), owner_model(mlu)[:changes])
    set_start_value(mlu, maximum(first(baseline_mlu(data)) for data in datas))
    return nothing
end

"Số thay đổi Σ_{d,i≠j} |x_k − x_{k−1}| thực tế trong nghiệm, cho từng kỳ k ≥ 2."
function budget_used(x, P)
    x_value = round.(Int, value.(x))
    return [sum(abs.(x_value[:, k, :, :] .- x_value[:, k - 1, :, :])) for k in 2:P]
end

"MLU của từng kỳ, tính lại từ đường segment của nghiệm (độc lập với biến mlu)."
mlu_by_period(x, datas) = [routing_mlu(datas[k], segment_paths(view(x, :, k, :, :), datas[k])) for k in eachindex(datas)]

# ---------------------------------------------------------------- kiểm tra
"""
Kiểm tra trên toy, setA-01..03 (t = 0, 1), giới hạn 120 s:
  - MLU tính lại từng kỳ, max của chúng = best;  số thay đổi thực tế ≤ κ;
  - best ≥ max(tối ưu riêng t = 0, tối ưu riêng t = 1)  (tách riêng từng kỳ là bài nới lỏng);
  - setA-01 với κ ép = 1: không demand nào được đổi đường ⇒ 0 thay đổi, hai kỳ cùng định tuyến.
"""
function check_multi_period_model()
    cases = (("../toy/toy", nothing), ("../setA/setA-01", nothing), ("../setA/setA-01", 1.0),
             ("../setA/setA-02", nothing), ("../setA/setA-03", nothing))
    for (prefix, forced_budget) in cases
        inst = json_to_instance(prefix)
        datas, budgets = multi_period_data(inst)
        forced_budget === nothing || (budgets = [Inf, forced_budget])
        build_seconds = @elapsed (model, x, added, mlu) = build_multi_period_model(datas, budgets)
        start_all_periods_from_baseline!(x, added, mlu, datas)
        r = solve_model!(model; time_limit = 120.0, silent = true)
        per_period = mlu_by_period(x, datas)
        used = budget_used(x, length(datas))
        same_routing = segment_paths(view(x, :, 1, :, :), datas[1]) == segment_paths(view(x, :, 2, :, :), datas[2])
        separate = map(datas) do data                       # tối ưu riêng từng kỳ (mô hình Step 5)
            m, xs, ms = build_model(data)
            start_from_baseline!(xs, ms, data)
            solve_model!(m; time_limit = 120.0, silent = true).best
        end
        println(inst.name, " (t = 0, 1), κ(1) = ", budgets[2], ": ", r.status, ", best = ", round(r.best; digits = 4),
                ", gap = ", round(r.gap; digits = 4), ", optimize! = ", round(r.seconds; digits = 1),
                " s, dựng = ", round(build_seconds; digits = 1), " s")
        println("    MLU từng kỳ (tính lại) = ", round.(per_period; digits = 4),
                ",  tối ưu riêng từng kỳ = ", round.(separate; digits = 4),
                ",  baseline = ", round.([first(baseline_mlu(data)) for data in datas]; digits = 4))
        println("    số thay đổi = ", used, " ≤ κ = ", budgets[2], ": ", all(used .<= budgets[2]),
                ",  hai kỳ cùng định tuyến: ", same_routing,
                ",  max(MLU từng kỳ) = best: ", isapprox(maximum(per_period), r.best; atol = 1e-6))
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    check_multi_period_model()
end
