# =============================================================================
#  Step 4 (readme) — Section Data: mọi tham số của mô hình cho một kỳ, tính từ 3 file JSON
#
#  Tên trong code              Ký hiệu trong mô hình     Lấy từ
#    data.vertices             V                         net file
#    data.arcs                 A(t)  (bỏ cung bị ngắt)   net + scenario file
#    data.demands              D                         tm file
#    data.src[d], data.dst[d]  s_d, t_d                  tm file
#    data.ratios[i, j]         r(i, j, a, t)             net file (split_ratios.jl)
#    data.capacity[a]          c(a)                      net file
#    data.volume[d]            v(d, t)                   tm file
#    data.max_segments         MaxSeg                    scenario file
#  Kỳ p = t + 1: model_data(inst, 1) là t = 0 (Step 4–6), model_data(inst, 2) là t = 1 (Step 7).
#
#  Dùng từ file khác / REPL : include("model_data.jl")    → chỉ nạp các hàm, không in gì
#  Chạy phần kiểm tra cuối file (trong thư mục code/):  julia --project=. model_data.jl   (REPL: check_model_data())
# =============================================================================

@isdefined(split_ratios) || include("split_ratios.jl")

"Section Data của kỳ p. `rule` = :pathcount (mặc định) hoặc :ecmp, xem split_ratios.jl."
function model_data(inst::Instance, p; rule = :pathcount)
    ratios, _ = split_ratios(inst, p; rule)
    return (
        vertices = 1:inst.n,
        arcs = [a for a in eachindex(inst.arc_from) if !(a in inst.down[p])],
        demands = eachindex(inst.src),
        src = inst.src,
        dst = inst.dst,
        ratios = ratios,
        capacity = inst.capacity,
        volume = inst.volume[:, p],
        max_segments = inst.max_segments,
    )
end

# ---------------------------------------------------------------- kiểm tra
# Hàm riêng để mọi biến là biến cục bộ (không đụng biến cùng tên trong REPL).
"Kiểm tra nhanh file model_data.jl."
function check_model_data()
    for prefix in ("../toy/toy", "../setA/setA-01", "../setA/setA-05")
        inst = json_to_instance(prefix)
        data = model_data(inst, 1)
        d = first(data.demands)
        println(inst.name, " (t = 0): |V| = ", length(data.vertices), ", |A| = ", length(data.arcs),
                ", |D| = ", length(data.demands), ", số phần tử r > 0 = ", sum(length, data.ratios),
                ", MaxSeg = ", data.max_segments)
        println("    demand ", d, ": ", data.src[d], " → ", data.dst[d], ", v = ", data.volume[d],
                ";  cung 1: c = ", data.capacity[1])
    end
end

# Gọi thẳng file này (julia --project=. model_data.jl) thì chạy kiểm tra; include thì không.
if abspath(PROGRAM_FILE) == @__FILE__
    check_model_data()
end
