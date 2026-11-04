# =============================================================================
#  Bước 3 — Tỉ lệ chia tải r(i, j, a) của từng kỳ
#
#  Segment i → j: lưu lượng đi từ i đến j theo các đường ngắn nhất. Hai cách chia:
#    rule = :pathcount  (calculating_r.pdf, dùng chính) — mỗi ĐƯỜNG ngắn nhất nhận phần bằng nhau
#    rule = :ecmp       (đề bài §2, checker chính thức) — tại mỗi ĐỈNH, chia đều cho các cung
#                        ra khỏi đỉnh đó nằm trên đường ngắn nhất
#  Hai cách cho cùng tập cung có r > 0; giá trị chỉ khác khi có nhiều đường ngắn nhất.
#
#  Tên biến trong code        Ký hiệu trong PDF / báo cáo
#    dist[i, j]               d_ij      độ dài đường ngắn nhất i → j
#    path_count[i, j]         σ_ij      số đường ngắn nhất i → j
#    inst.metric[a]           ω(a)      độ dài cung a
#    ratios[i, j]             r_ija     danh sách (a, r) với r > 0 (lưu thưa)
#  Chỉ số: i, j = đầu/cuối segment; a = cung, u → v = đầu/cuối cung a; p = kỳ (p = t + 1).
#
#  Cung a = (u → v) nằm trên một đường ngắn nhất i → j
#      ⇔  dist[i,u] + metric[a] + dist[v,j] = dist[i,j]
#  Path count:  r = path_count[i,u] * path_count[v,j] / path_count[i,j]
#               (số đường ngắn nhất đi qua a  /  tổng số đường ngắn nhất).
#
#  Dùng từ file khác / REPL : include("split_ratios.jl")    → chỉ nạp các hàm, không in gì
#  Chạy phần kiểm tra cuối file (trong thư mục code/):  julia --project=. split_ratios.jl   (REPL: check_split_ratios())
# =============================================================================

@isdefined(json_to_instance) || include("read_instance.jl")

# Metric của họ CO là số thực: so khoảng cách bằng isapprox, KHÔNG dùng ==
const RTOL = 1e-9

"dist[i, j] = độ dài đường ngắn nhất i → j (Dijkstra từ mọi đỉnh)."
function shortest_distances(graph, metric_matrix)
    n = nv(graph)
    dist = zeros(n, n)
    for i in 1:n
        dist[i, :] = dijkstra_shortest_paths(graph, i, metric_matrix).dists
    end
    return dist
end

"arcs_into[v] / arcs_out[u] = các cung còn hoạt động ở kỳ p đi vào v / đi ra khỏi u."
function active_arcs(inst::Instance, p)
    arcs_into = [Int[] for _ in 1:inst.n]
    arcs_out = [Int[] for _ in 1:inst.n]
    for a in eachindex(inst.arc_from)
        a in inst.down[p] && continue
        push!(arcs_into[inst.arc_to[a]], a)
        push!(arcs_out[inst.arc_from[a]], a)
    end
    return arcs_into, arcs_out
end

"""
path_count[i, v] = số đường ngắn nhất i → v, đếm lại từ `dist` với dung sai RTOL.

Không dùng `state.pathcounts` của Graphs.jl (cách trong calculating_r.pdf): hàm đó so
`alt == dists[v]`, mà với metric số thực thì hai đường dài bằng nhau có thể ra
0.919 và 0.9189999999999999 → đếm thiếu → r sai (setA-08, setA-14 ra tổng r = 2).
"""
function count_shortest_paths(inst::Instance, p, dist)
    n = inst.n
    arcs_into, _ = active_arcs(inst, p)
    path_count = zeros(n, n)
    for i in 1:n
        path_count[i, i] = 1.0
        for v in sortperm(dist[i, :])         # gần i trước: các đỉnh đứng trước v đã đếm xong
            v == i && continue
            for a in arcs_into[v]
                u = inst.arc_from[a]
                if isapprox(dist[i, u] + inst.metric[a], dist[i, v]; rtol = RTOL)
                    path_count[i, v] += path_count[i, u]
                end
            end
        end
    end
    return path_count
end

"Biến thể 1 — path count: ratios[i, j] = [(a, r), ...]."
function pathcount_ratios(inst::Instance, p, dist)
    path_count = count_shortest_paths(inst, p, dist)
    n = inst.n
    ratios = [Tuple{Int,Float64}[] for _ in 1:n, _ in 1:n]
    reach = vec(maximum(dist; dims = 2))          # reach[i] = max_j dist[i, j]
    for a in eachindex(inst.arc_from)
        a in inst.down[p] && continue
        u, v = inst.arc_from[a], inst.arc_to[a]
        # a nằm trên một đường ngắn nhất i → j nào đó thì dist[i,u] + ω(a) = dist[i,v]: lọc trước theo i, chỉ
        # duyệt j cho các i đó (m·n² phép isapprox → m·n + phần còn lại; kết quả và thứ tự không đổi).
        # Dung sai 2·RTOL·reach[i] ≥ mọi chênh lệch mà phép isapprox bên dưới còn chấp nhận.
        sources = [i for i in 1:n if dist[i, u] + inst.metric[a] - dist[i, v] <= 2 * RTOL * reach[i]]
        for j in 1:n, i in sources
            i == j && continue
            if isapprox(dist[i, u] + inst.metric[a] + dist[v, j], dist[i, j]; rtol = RTOL)
                push!(ratios[i, j], (a, path_count[i, u] * path_count[v, j] / path_count[i, j]))
            end
        end
    end
    return ratios
end

"""
Biến thể 2 — ECMP: thả 1 đơn vị lưu lượng tại i rồi cho chảy về j; tại mỗi đỉnh u,
lưu lượng đang có chia đều cho next_hops[u] (các cung ra khỏi u trên đường ngắn nhất u → j).
"""
function ecmp_ratios(inst::Instance, p, dist)
    n = inst.n
    _, arcs_out = active_arcs(inst, p)
    ratios = [Tuple{Int,Float64}[] for _ in 1:n, _ in 1:n]
    flow = zeros(n)                           # flow[u] = lưu lượng (từ i) đang đến u
    for j in 1:n
        next_hops = [[a for a in arcs_out[u]
                      if isapprox(inst.metric[a] + dist[inst.arc_to[a], j], dist[u, j]; rtol = RTOL)]
                     for u in 1:n]
        order = sortperm(dist[:, j]; rev = true)   # xa j trước: mọi đỉnh đổ vào u đã xử lý xong
        for i in 1:n
            i == j && continue
            fill!(flow, 0.0)
            flow[i] = 1.0
            for u in order
                (u == j || flow[u] == 0.0) && continue   # 0.0 đúng tuyệt đối: u chưa nhận gì
                share = flow[u] / length(next_hops[u])
                for a in next_hops[u]
                    push!(ratios[i, j], (a, share))
                    flow[inst.arc_to[a]] += share
                end
            end
        end
    end
    return ratios
end

"Tỉ lệ r của kỳ p theo `rule` (:pathcount hoặc :ecmp). Trả về (ratios, dist)."
function split_ratios(inst::Instance, p; rule = :pathcount)
    graph, metric_matrix = period_graph(inst, p)
    # Không liên thông mạnh thì có cặp (i, j) không có đường: r = 0 ở mọi cung,
    # segment i → j thành "dịch chuyển tức thời miễn phí" trong mô hình.
    is_strongly_connected(graph) || error("G_$(p - 1) không liên thông mạnh")
    dist = shortest_distances(graph, metric_matrix)
    ratios = rule == :pathcount ? pathcount_ratios(inst, p, dist) :
             rule == :ecmp ? ecmp_ratios(inst, p, dist) :
             error("rule phải là :pathcount hoặc :ecmp, không phải $rule")
    return ratios, dist
end

"Kiểm tra: với mọi cặp i ≠ j, tổng r trên các cung đi RA khỏi i phải bằng 1."
function check_ratios(inst::Instance, ratios)
    for i in 1:inst.n, j in 1:inst.n
        i == j && continue
        total = sum((r for (a, r) in ratios[i, j] if inst.arc_from[a] == i); init = 0.0)
        isapprox(total, 1.0; atol = 1e-9) || error("cặp ($i, $j): tổng r ra khỏi $i = $total ≠ 1")
    end
    return true
end

# ---------------------------------------------------------------- kiểm tra
# 1) Ví dụ nhỏ trong đề (Figure 1, đỉnh A..G = 1..7). Từ A đến F có 3 đường ngắn nhất,
#    cùng dài 400: A-B-D-F, A-B-E-D-F, A-B-E-G-F. Tại B: 1 đường đi B→D, 2 đường đi B→E.
#    Path count: B→D = 1/3, B→E = 2/3.   ECMP: B có 2 cung ra → 1/2, 1/2; E có 2 cung ra → 1/4, 1/4.
# Hàm riêng để mọi biến là biến cục bộ (không đụng biến cùng tên trong REPL).
"Kiểm tra nhanh file split_ratios.jl."
function check_split_ratios()
    toy = json_to_instance("../toy/toy")
    A, B, D, E, F, G = 1, 2, 4, 5, 6, 7
    arc(u, v) = findfirst(a -> toy.arc_from[a] == u && toy.arc_to[a] == v, eachindex(toy.arc_from))
    ratio(ratios, i, j, a) = sum((r for (b, r) in ratios[i, j] if b == a); init = 0.0)
    for rule in (:pathcount, :ecmp)
        ratios, dist = split_ratios(toy, 1; rule)
        println("toy ", rpad(rule, 10), ": r(A,F, B→D) = ", round(ratio(ratios, A, F, arc(B, D)); digits = 4),
                ",  r(A,F, B→E) = ", round(ratio(ratios, A, F, arc(B, E)); digits = 4),
                ",  r(A,F, E→G) = ", round(ratio(ratios, A, F, arc(E, G)); digits = 4),
                ",  kiểm tra tổng = ", check_ratios(toy, ratios))
    end

    # 2) Một instance thật, cả 2 kỳ, cả 2 cách chia
    inst = json_to_instance("../setA/setA-05")
    for p in 1:size(inst.volume, 2), rule in (:pathcount, :ecmp)
        seconds = @elapsed (period_ratios, _) = split_ratios(inst, p; rule)
        println(inst.name, " G_", p - 1, " ", rpad(rule, 10), ": ", round(seconds; digits = 2), " s, ",
                "số phần tử r > 0 = ", sum(length, period_ratios),
                ",  kiểm tra tổng = ", check_ratios(inst, period_ratios))
    end
end

# Gọi thẳng file này (julia --project=. split_ratios.jl) thì chạy kiểm tra; include thì không.
if abspath(PROGRAM_FILE) == @__FILE__
    check_split_ratios()
end
