# =============================================================================
#  Lưu MLU baseline (không waypoint) của mọi instance, mọi kỳ, ra MỘT file Markdown
#  (bảng đọc được trên GitHub / VS Code). Mỗi bộ một bảng, mỗi instance một dòng, mỗi kỳ một cột.
#  Tính cả 2 cách chia (path count, ECMP) bằng baseline_loads_by_destination (đủ nhẹ cho setB/setC).
#
#  Chạy (trong thư mục code/):
#    julia --project=. save_baseline_mlu.jl setA setB          → ../results/baseline_mlu.md
# =============================================================================

@isdefined(baseline_loads_by_destination) || include("baseline_mlu.jl")
using Printf

const OUTPUT_FILE = "../results/baseline_mlu.md"
const OVERLOAD = 1.001      # > 1 thật sự; 1.0000x chỉ do lưu lượng trong JSON làm tròn 4 chữ số

"Các tiền tố instance của một bộ, ví dụ \"setA\" → [\"../setA/setA-01\", ...]."
instance_prefixes(set_name) =
    sort([joinpath("..", set_name, replace(f, "-net.json" => ""))
          for f in readdir(joinpath("..", set_name)) if endswith(f, "-net.json")])

"MLU baseline của mọi kỳ: (pathcount = [...], ecmp = [...])."
function baseline_by_period(inst::Instance)
    mlu(p, rule) = first(max_utilization(baseline_loads_by_destination(inst, p; rule), inst.capacity,
                                         [a for a in eachindex(inst.arc_from) if !(a in inst.down[p])]))
    T = size(inst.volume, 2)
    return (pathcount = [mlu(p, :pathcount) for p in 1:T], ecmp = [mlu(p, :ecmp) for p in 1:T])
end

"Một ô của bảng: giá trị path count; thêm ECMP nếu khác; in đậm nếu quá tải."
function format_cell(pathcount, ecmp)
    text = @sprintf("%.4f", pathcount)
    isapprox(pathcount, ecmp; atol = 1e-9) || (text *= @sprintf(" / %.4f", ecmp))
    return pathcount > OVERLOAD ? "**$text**" : text
end

"Khoảng giá trị dạng \"3\" hoặc \"0–8\"."
format_range(values) = minimum(values) == maximum(values) ? string(minimum(values)) :
                       "$(minimum(values))–$(maximum(values))"

function write_set_table(io, set_name)
    prefixes = instance_prefixes(set_name)
    T_max = maximum(size(json_to_instance(prefix).volume, 2) for prefix in prefixes)
    println(io, "\n## ", set_name, "\n")
    println(io, "| Instance | n | m | Số demand | Cung ngắt/kỳ | ", join(("t = $t" for t in 0:T_max-1), " | "), " |")
    println(io, "|---|---:|---:|---:|---:|", repeat("---:|", T_max))
    for prefix in prefixes
        inst = json_to_instance(prefix)
        seconds = @elapsed values = baseline_by_period(inst)
        T = length(values.pathcount)
        cells = [format_cell(values.pathcount[p], values.ecmp[p]) for p in 1:T]
        append!(cells, fill("", T_max - T))
        println(io, "| ", join((inst.name, inst.n, length(inst.arc_from), length(inst.src),
                                format_range(length.(inst.down[2:end])), cells...), " | "), " |")
        println(inst.name, ": ", T, " kỳ, ", round(seconds; digits = 1), " s")
        flush(io)
    end
end

function save_baseline_mlu(set_names)
    mkpath(dirname(OUTPUT_FILE))
    open(OUTPUT_FILE, "w") do io
        println(io, "# MLU baseline (không waypoint: mọi demand đi thẳng s → t theo đường ngắn nhất)\n")
        println(io, "- Mỗi ô: MLU = max_a load(a) / c(a) của kỳ t, chia tải theo **path count**. ",
                    "Nếu ECMP cho giá trị khác thì ô ghi `path count / ECMP`.")
        println(io, "- **In đậm**: quá tải thật (> ", OVERLOAD, "). Giá trị 1.0000x chỉ do lưu lượng trong JSON làm tròn.")
        println(io, "- Cung ngắt/kỳ: số cung bị ngắt ở các kỳ t ≥ 1 (kỳ t = 0 không có).")
        println(io, "- Tạo bởi: `julia --project=. save_baseline_mlu.jl ", join(set_names, " "), "` (trong `code/`).")
        for set_name in set_names
            write_set_table(io, set_name)
        end
    end
    println("Đã lưu ", OUTPUT_FILE)
end

if abspath(PROGRAM_FILE) == @__FILE__
    isempty(ARGS) && error("cách dùng: julia --project=. save_baseline_mlu.jl setA setB")
    save_baseline_mlu(ARGS)
end
