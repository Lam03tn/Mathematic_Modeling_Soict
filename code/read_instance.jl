# =============================================================================
#  Bước 1–2 — Đọc một instance và dựng đồ thị G_t của từng kỳ
#
#  Một instance gồm 3 file cùng tiền tố (prefix), ví dụ "../setA/setA-01":
#    prefix-net.json       : đồ thị — nodes, links (from, to, metric = ω, capacity = c)
#    prefix-tm.json        : ma trận lưu lượng — mỗi demand có s, t, v = [ν(d,0), ν(d,1), ...]
#    prefix-scenario.json  : max_segments, budget κ(t), interventions q(t)
#
#  Quy ước đánh số và tên gọi giống notebook json_to_multigraph_pluto.jl của thầy:
#    đỉnh  v = 1..n  theo thứ tự trong "nodes"  (id JSON có thể giảm dần: 99, 98, ...)
#    cung  a = 1..m  theo thứ tự trong "links"
#    vertex_to_id / id_to_vertex, id_to_arc, arc_from / arc_to, metric, capacity
#  Thêm so với notebook: demand (tm.json), kịch bản (scenario.json), kỳ p = 1..T với p = t + 1.
#
#  Dùng từ file khác / REPL : include("read_instance.jl")    → chỉ nạp các hàm, không in gì
#  Chạy phần kiểm tra cuối file (trong thư mục code/):  julia --project=. read_instance.jl   (REPL: check_read_instance())
# =============================================================================

using JSON3, Graphs

"Đọc 3 file JSON của instance `prefix` và trả về (net, tm, sc)."
function read_json_files(prefix)
    net = JSON3.read(read(prefix * "-net.json", String))
    tm = JSON3.read(read(prefix * "-tm.json", String))
    sc = JSON3.read(read(prefix * "-scenario.json", String))
    return net, tm, sc
end

"Dữ liệu của một instance, đã đổi sang đánh số Julia."
struct Instance
    name::String
    n::Int                      # số đỉnh
    vertex_to_id::Vector{Int}   # vertex_to_id[v] = id JSON của đỉnh v (để ghi kết quả ra file)
    arc_from::Vector{Int}       # arc_from[a] = đỉnh đầu của cung a
    arc_to::Vector{Int}         # arc_to[a]   = đỉnh cuối của cung a
    metric::Vector{Float64}     # ω(a): độ dài dùng để tính đường ngắn nhất
    capacity::Vector{Float64}   # c(a)
    src::Vector{Int}            # src[d] = đỉnh nguồn s của demand d
    dst::Vector{Int}            # dst[d] = đỉnh đích t của demand d
    volume::Matrix{Float64}     # volume[d, p] = ν(d, t) với p = t + 1
    max_segments::Int           # maxSeg
    budget::Vector{Float64}     # budget[p] = κ(t); kỳ p = 1 (t = 0) không giới hạn: Inf
    down::Vector{Vector{Int}}   # down[p] = các cung bị ngắt ở kỳ p, tức q(t)
end

"Đọc instance `prefix` và đổi mọi id JSON sang số đỉnh/cung của Julia."
function json_to_instance(prefix)
    net, tm, sc = read_json_files(prefix)

    vertex_to_id = [Int(node.id) for node in net.nodes]
    id_to_vertex = Dict(id => v for (v, id) in enumerate(vertex_to_id))
    id_to_arc = Dict(Int(link.id) => a for (a, link) in enumerate(net.links))

    T = Int(tm.num_time_slots)
    budget = fill(Inf, T)
    for b in sc.budget
        budget[Int(b.t)+1] = b.value
    end
    down = [Int[] for _ in 1:T]
    for iv in sc.interventions
        down[Int(iv.t)+1] = [id_to_arc[Int(id)] for id in iv.links]
    end

    return Instance(
        basename(prefix),
        length(vertex_to_id),
        vertex_to_id,
        [id_to_vertex[Int(link.from)] for link in net.links],
        [id_to_vertex[Int(link.to)] for link in net.links],
        [Float64(link.metric) for link in net.links],
        [Float64(link.capacity) for link in net.links],
        [id_to_vertex[Int(d.s)] for d in tm.demands],
        [id_to_vertex[Int(d.t)] for d in tm.demands],
        [Float64(d.v[p]) for d in tm.demands, p in 1:T],
        Int(sc.max_segments),
        budget,
        down,
    )
end

"""
Đồ thị G_t của kỳ p (đã bỏ các cung bị ngắt q(t)) và ma trận độ dài
metric_matrix[u, v] = ω(u → v) (như `W = metric_matrix(network)` của thầy), dùng cho Dijkstra.
"""
function period_graph(inst::Instance, p)
    graph = SimpleDiGraph(inst.n)
    metric_matrix = zeros(inst.n, inst.n)
    for a in eachindex(inst.arc_from)
        a in inst.down[p] && continue
        u, v = inst.arc_from[a], inst.arc_to[a]
        add_edge!(graph, u, v) || error("có 2 cung song song $u → $v")  # setA/B/C không có
        metric_matrix[u, v] = inst.metric[a]
    end
    return graph, metric_matrix
end

# ---------------------------------------------------------------- kiểm tra
# Hàm riêng để mọi biến là biến cục bộ (không đụng biến cùng tên trong REPL).
"Kiểm tra nhanh file read_instance.jl."
function check_read_instance()
    inst = json_to_instance("../setA/setA-05")
    println(inst.name, ": n = ", inst.n, ", m = ", length(inst.arc_from), ", |D| = ", length(inst.src))
    println("cung 1  : đỉnh ", inst.arc_from[1], " → ", inst.arc_to[1],
            "   (id JSON ", inst.vertex_to_id[inst.arc_from[1]], " → ", inst.vertex_to_id[inst.arc_to[1]], ")")
    println("demand 1: đỉnh ", inst.src[1], " → ", inst.dst[1],
            "   (id JSON ", inst.vertex_to_id[inst.src[1]], " → ", inst.vertex_to_id[inst.dst[1]], ")",
            "   ν = ", inst.volume[1, :])
    println("budget  : ", inst.budget, "   cung bị ngắt mỗi kỳ: ", inst.down)
    for p in 1:size(inst.volume, 2)
        graph, _ = period_graph(inst, p)
        println("G_", p - 1, ": ", nv(graph), " đỉnh, ", ne(graph), " cung, liên thông mạnh = ", is_strongly_connected(graph))
    end
end

# Gọi thẳng file này (julia --project=. read_instance.jl) thì chạy kiểm tra; include thì không.
if abspath(PROGRAM_FILE) == @__FILE__
    check_read_instance()
end
