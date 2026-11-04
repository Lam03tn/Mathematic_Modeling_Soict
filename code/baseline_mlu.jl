# =============================================================================
#  MLU baseline — mọi demand đi thẳng s_d → t_d, không dùng waypoint
#  (định tuyến đường ngắn nhất mặc định của mạng). Không phải bước trong readme,
#  dùng để:
#    1) kiểm tra Section Data: toy phải ra 0.4167 (path count) / 0.4375 (ECMP, Figure 4 của đề);
#    2) cận trên cho mô hình: "không waypoint" là một nghiệm khả thi ⇒ λ* ≤ MLU baseline;
#    3) báo cáo: mô hình giảm MLU được bao nhiêu % so với baseline.
#
#    load(a) = Σ_d v(d) · r(s_d, t_d, a)          MLU = max_{a ∈ A(t)} load(a) / c(a)
#
#  Dùng từ file khác / REPL : include("baseline_mlu.jl")    → chỉ nạp các hàm, không in gì
#  Chạy phần kiểm tra cuối file (trong thư mục code/):  julia --project=. baseline_mlu.jl   (REPL: check_baseline_mlu())
# =============================================================================

@isdefined(model_data) || include("model_data.jl")

"load[a] = tải trên cung a khi mọi demand đi thẳng s_d → t_d."
function baseline_loads(data)
    load = zeros(length(data.capacity))
    for d in data.demands, (a, r) in data.ratios[data.src[d], data.dst[d]]
        load[a] += data.volume[d] * r
    end
    return load
end

"MLU = max_{a ∈ arcs} load[a] / capacity[a]. Trả về (mlu, cung có utilization lớn nhất)."
function max_utilization(load, capacity, arcs)
    utilization = [load[a] / capacity[a] for a in arcs]
    k = argmax(utilization)
    return utilization[k], arcs[k]
end

"MLU baseline của Section Data `data`. Trả về (mlu, cung có utilization lớn nhất)."
baseline_mlu(data) = max_utilization(baseline_loads(data), data.capacity, data.arcs)

"""
Giống `baseline_loads(model_data(inst, p; rule))` nhưng KHÔNG cần ratios cho mọi cặp (i, j)
(setB/setC quá lớn: n = 3902 → ~15 triệu cặp, nhiều GB RAM).

Với mỗi đích j: đặt v(d) của mọi demand về j tại nguồn s_d, rồi cho chảy về j theo đường
ngắn nhất, xử lý đỉnh xa j trước. Tại đỉnh u, lưu lượng chia cho các cung ra u → v trên
đường ngắn nhất u → j:
  :pathcount  theo tỉ lệ  count_to[v] / count_to[u]   (count_to[u] = số đường ngắn nhất u → j;
              tương đương r = path_count[i,u]·path_count[v,j]/path_count[i,j])
  :ecmp       chia đều.
"""
function baseline_loads_by_destination(inst::Instance, p; rule = :pathcount)
    rule in (:pathcount, :ecmp) || error("rule phải là :pathcount hoặc :ecmp, không phải $rule")
    graph, metric_matrix = period_graph(inst, p)
    is_strongly_connected(graph) || error("G_$(p - 1) không liên thông mạnh")
    reverse_graph, reverse_metric = reverse(graph), permutedims(metric_matrix)
    _, arcs_out = active_arcs(inst, p)
    demands_to = [Int[] for _ in 1:inst.n]
    for d in eachindex(inst.dst)
        push!(demands_to[inst.dst[d]], d)
    end

    load = zeros(length(inst.arc_from))
    flow = zeros(inst.n)
    count_to = zeros(inst.n)
    for j in 1:inst.n
        isempty(demands_to[j]) && continue
        dist_to = dijkstra_shortest_paths(reverse_graph, j, reverse_metric).dists   # dist_to[u] = dist u → j
        next_hops = [[a for a in arcs_out[u]
                      if isapprox(inst.metric[a] + dist_to[inst.arc_to[a]], dist_to[u]; rtol = RTOL)]
                     for u in 1:inst.n]
        order = sortperm(dist_to)                 # gần j trước
        fill!(count_to, 0.0)
        count_to[j] = 1.0
        for u in order
            u == j || (count_to[u] = sum(count_to[inst.arc_to[a]] for a in next_hops[u]))
        end
        fill!(flow, 0.0)
        for d in demands_to[j]
            flow[inst.src[d]] += inst.volume[d, p]
        end
        for u in Iterators.reverse(order)         # xa j trước
            (u == j || flow[u] == 0.0) && continue
            for a in next_hops[u]
                share = rule == :ecmp ? flow[u] / length(next_hops[u]) :
                        flow[u] * count_to[inst.arc_to[a]] / count_to[u]
                load[a] += share
                flow[inst.arc_to[a]] += share
            end
        end
    end
    return load
end

# ---------------------------------------------------------------- kiểm tra
# Hàm riêng để mọi biến là biến cục bộ (không đụng biến cùng tên trong REPL).
"Kiểm tra nhanh file baseline_mlu.jl."
function check_baseline_mlu()
    # 1) toy, t = 0: cung nặng nhất là D → F (đỉnh 4 → 6), 0.4167 (path count) và 0.4375 (ECMP)
    toy = json_to_instance("../toy/toy")
    for rule in (:pathcount, :ecmp)
        mlu, a = baseline_mlu(model_data(toy, 1; rule))
        println("toy ", rpad(rule, 10), ": MLU baseline = ", round(mlu; digits = 4),
                " tại cung ", toy.arc_from[a], " → ", toy.arc_to[a])
    end

    # 2) setA-01..05, cả 2 kỳ
    for k in 1:5
        inst = json_to_instance("../setA/setA-0$k")
        values = [round(first(baseline_mlu(model_data(inst, p))); digits = 4) for p in 1:size(inst.volume, 2)]
        println(inst.name, ": MLU baseline theo kỳ t = 0, 1: ", values)
    end

    # 3) Hai cách tính tải phải trùng nhau (sai lệch ~ 1e-12)
    for prefix in ("../toy/toy", "../setA/setA-01", "../setA/setA-05", "../setA/setA-08"), rule in (:pathcount, :ecmp)
        inst = json_to_instance(prefix)
        diff = maximum(maximum(abs.(baseline_loads(model_data(inst, p; rule)) .-
                                    baseline_loads_by_destination(inst, p; rule)))
                       for p in 1:size(inst.volume, 2))
        println(inst.name, " ", rpad(rule, 10), ": sai lệch lớn nhất giữa 2 cách tính tải = ", diff)
    end
end

# Gọi thẳng file này (julia --project=. baseline_mlu.jl) thì chạy kiểm tra; include thì không.
if abspath(PROGRAM_FILE) == @__FILE__
    check_baseline_mlu()
end
