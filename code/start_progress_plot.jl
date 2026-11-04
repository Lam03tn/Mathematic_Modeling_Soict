# =============================================================================
#  Hình cho báo cáo: best (nghiệm tốt nhất) TRUNG BÌNH qua các lần chạy theo thời gian, đọc từ log HiGHS,
#  HiGHS bắt đầu từ baseline so với bắt đầu từ greedy; LP bound vẽ thành một đường ngang.
#  Giá trị ở 1800 s đúng bằng cột "Best avg" của Bảng 2 (các lần chạy quá giờ bị cắt ở 1800 s).
#  Ghi ra ../report/start_progress.tex: một groupplot pgfplots, main.tex \input file này.
#
#  Chạy (trong thư mục code/, sau khi kéo results/step6 và results/step6_greedy về):
#    julia --project=. start_progress_plot.jl setA-04 setA-05
# =============================================================================

using Printf
include("compare_start_logs.jl")      # progress(log_file) → [(time, bound, best)], CONFIGS

const TIME_LIMIT = 1800.0
const STYLES = Dict("Baseline" => "blue!70!black", "Greedy" => "orange!90!black")

"Đường bậc thang của một giá trị: chỉ giữ các điểm mà giá trị thay đổi, thời gian trong [0, TIME_LIMIT]."
function steps(points, value)
    kept = Tuple{Float64,Float64}[]
    for p in points
        v = value(p)
        (isfinite(v) && v > 0 && p[1] <= TIME_LIMIT) || continue
        (isempty(kept) || v != last(kept)[2]) && push!(kept, (p[1], v))
    end
    return kept
end

"Giá trị bậc thang tại thời điểm t (trước điểm đầu tiên: giá trị đầu tiên)."
value_at(pts, t) = (i = findlast(p -> p[1] <= t, pts); i === nothing ? pts[1][2] : pts[i][2])

"Trung bình của các đường bậc thang (mỗi lần chạy một đường) — cũng là một đường bậc thang."
function mean_steps(runs)
    kept = Tuple{Float64,Float64}[]
    for t in sort(unique([0.0; [t for pts in runs for (t, _) in pts]]))
        v = sum(value_at(pts, t) for pts in runs) / length(runs)
        (isempty(kept) || !isapprox(v, last(kept)[2]; rtol = 1e-12)) && push!(kept, (t, v))
    end
    push!(kept, (TIME_LIMIT, last(kept)[2]))
    return kept
end

coordinates(pts) = join((@sprintf("(%.1f,%.4f)", t, v) for (t, v) in pts), " ")

function start_progress_plot(output_file, instances)
    open(output_file, "w") do io
        println(io, "% Tạo bởi code/start_progress_plot.jl từ log HiGHS — không sửa tay.")
        println(io, "\\begin{tikzpicture}")
        println(io, "\\begin{groupplot}[group style={group size=$(length(instances)) by 1, horizontal sep=1.6cm},")
        println(io, "  width=0.48\\textwidth, height=3.6cm, xmin=0, xmax=$(Int(TIME_LIMIT)), xtick={0,600,1200,1800},")
        println(io, "  enlarge y limits=0.12, xlabel={time (s)}, ylabel={MLU}, tick label style={font=\\footnotesize},")
        println(io, "  label style={font=\\small}, title style={font=\\small}, legend style={font=\\footnotesize},\n  /pgf/number format/1000 sep={}]")
        for (k, instance) in enumerate(instances)
            println(io, "\\nextgroupplot[title={$instance}", k == 1 ? ", legend to name=startlegend, legend columns=3" : "", "]")
            bound = -Inf
            for (name, dir) in CONFIGS
                logs = sort(filter(f -> startswith(f, instance * "_run"), readdir(joinpath(dir, "logs"))))
                runs = [progress(joinpath(dir, "logs", f)) for f in logs]
                bound = max(bound, maximum(last(steps(r, p -> p[2]))[2] for r in runs))
                mean = mean_steps([steps(r, p -> p[3]) for r in runs])
                println(io, "\\addplot[const plot, very thick, $(STYLES[name])] coordinates {", coordinates(mean), "};")
                k == 1 && println(io, "\\addlegendentry{$(lowercase(name)) start}")
                @printf("%s %s: %d lần chạy, best trung bình ở %d s = %.4f\n", instance, name, length(runs), TIME_LIMIT, last(mean)[2])
            end
            println(io, "\\addplot[densely dashed, thick, black, domain=0:$(Int(TIME_LIMIT))] {$(@sprintf("%.4f", bound))};")
            k == 1 && println(io, "\\addlegendentry{LP bound}")
            @printf("%s LP bound = %.4f\n", instance, bound)
        end
        println(io, "\\end{groupplot}")
        println(io, "\\end{tikzpicture}")
    end
    println("Đã lưu ", output_file)
end

if abspath(PROGRAM_FILE) == @__FILE__
    start_progress_plot("../report/start_progress.tex", isempty(ARGS) ? ["setA-04", "setA-05"] : ARGS)
end
