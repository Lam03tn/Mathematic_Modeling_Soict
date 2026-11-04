# =============================================================================
#  Minh hoạ: HiGHS bắt đầu từ baseline (không greedy) so với bắt đầu từ greedy, cùng máy, cùng 1800 s,
#  cùng seed. Đọc bảng tiến trình B&B trong log HiGHS (results/<step>/logs/<instance>_run<k>.log) và ghi
#  best / bound tại các mốc thời gian ra MỘT file Markdown.
#
#  Chạy (trong thư mục code/, sau khi kéo results/step6 và results/step6_greedy từ server về):
#    julia --project=. compare_start_logs.jl ../results/start_comparison.md setA-05 setA-04
# =============================================================================

using Printf

const CHECKPOINTS = (60, 300, 600, 1200, 1800)            # giây (đồng hồ của HiGHS, tính cả presolve)
const CONFIGS = ("Baseline" => "../results/step6", "Greedy" => "../results/step6_greedy")

"Các điểm (time, bound, best) của một log; điểm đầu (0, −Inf, start) là nghiệm xuất phát."
function progress(log_file)
    lines = readlines(log_file)
    start = parse(Float64, match(r"MIP start solution is feasible, objective value is (\S+)",
                                 join(lines, "\n")).captures[1])
    points = [(0.0, -Inf, start)]
    for line in lines
        m = match(r"^\s*[A-Za-z]?\s+\d+\s+\d+\s+\d+\s+\S+%\s+(\S+)\s+(\S+)\s+.*\s(\d+\.\d+)s\s*$", line)
        m === nothing && continue
        bound, best, time = (parse(Float64, replace(c, "inf" => "Inf")) for c in m.captures)
        push!(points, (time, bound, best))
    end
    return points
end

"Giá trị (bound, best) tại thời điểm t: điểm cuối cùng có time ≤ t."
value_at(points, t) = points[findlast(p -> p[1] <= t, points)][2:3]

"Thời điểm best đạt giá trị cuối cùng của lần chạy (lần đầu tìm ra nghiệm tốt nhất)."
time_of_final_best(points) = points[findfirst(p -> p[3] <= last(points)[3] + 1e-9, points)][1]

mean(x) = sum(x) / length(x)
fmt(x) = isfinite(x) ? @sprintf("%.4f", x) : "—"

function compare_start_logs(output_file, instances)
    open(output_file, "w") do io
        println(io, "# HiGHS bắt đầu từ baseline so với bắt đầu từ greedy (Step 6, t = 0)\n")
        println(io, "- Cùng máy server (i5-12400), cùng giới hạn 1800 s, cùng seed 0–4; số liệu đọc từ log HiGHS.")
        println(io, "- Mỗi ô: trung bình 5 lần chạy của **best** (nghiệm tốt nhất, càng nhỏ càng tốt) / **bound** (cận dưới).")
        println(io, "- Thời gian là đồng hồ của HiGHS (tính cả presolve). \"—\": chưa có cận (LP gốc chưa giải xong).\n")
        for instance in instances
            println(io, "## ", instance, "\n")
            println(io, "| Bắt đầu từ | t = 0 (start) | ", join(("$t s" for t in CHECKPOINTS), " | "),
                        " | Tìm ra best cuối lúc (TB, s) | OPTIMAL |")
            println(io, "|---|---:|", repeat("---:|", length(CHECKPOINTS)), "---:|---:|")
            for (name, dir) in CONFIGS
                logs = sort(filter(f -> startswith(f, instance * "_run"), readdir(joinpath(dir, "logs"))))
                runs = [progress(joinpath(dir, "logs", f)) for f in logs]
                cell(t) = string(fmt(mean(last(value_at(p, t)) for p in runs)), " / ",
                                 fmt(mean(first(value_at(p, t)) for p in runs)))
                optimal = count(f -> occursin("Status            Optimal", read(joinpath(dir, "logs", f), String)), logs)
                println(io, "| ", name, " (", length(runs), " lần) | ", fmt(mean(last(first(p)) for p in runs)), " | ",
                        join((cell(t) for t in CHECKPOINTS), " | "), " | ",
                        @sprintf("%.0f", mean(time_of_final_best(p) for p in runs)), " | ", optimal, "/", length(runs), " |")
            end
            println(io)
        end
    end
    println("Đã lưu ", output_file)
end

if abspath(PROGRAM_FILE) == @__FILE__
    length(ARGS) < 2 && error("cách dùng: julia --project=. compare_start_logs.jl ../results/start_comparison.md setA-05 setA-04")
    compare_start_logs(ARGS[1], ARGS[2:end])
end
