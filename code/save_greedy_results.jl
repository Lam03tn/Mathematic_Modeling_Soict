# =============================================================================
#  Greedy (greedy_waypoints.jl) cho instance NHIỀU kỳ mà MIP không dựng nổi (setB, setC):
#  greedy riêng từng kỳ, rồi chọn phương án thỏa budget (4) cho mọi kỳ (best_plan). Ghi MỘT file Markdown.
#  Dữ liệu được tính và bỏ đi TỪNG KỲ (setC: n tới 3902, 24 kỳ — giữ mọi kỳ cùng lúc thì hết RAM).
#
#  Chạy (trong thư mục code/):
#    julia --project=. save_greedy_results.jl ../results/greedy_setB.md ../setB/setB-01 ../setB/setB-02
#    julia --project=. save_greedy_results.jl ../results/greedy_setB.md 5 ../setB/setB-01 ...   (greedy 5 lần)
#  Greedy tất định: mọi lần chạy cho cùng đường đi (có kiểm tra) — chạy nhiều lần chỉ để đo thời gian.
# =============================================================================

@isdefined(best_plan) || include("greedy_waypoints.jl")
using Printf

const GREEDY_TIME_LIMIT = 300.0   # giây cho greedy của mỗi kỳ

"Dữ liệu kỳ p tính khi được hỏi, không giữ lại (best_plan đọc mỗi kỳ một lần)."
struct PeriodData
    inst::Instance
end
Base.getindex(periods::PeriodData, p) = (GC.gc(); model_data(periods.inst, p))

"Tên phương án best_plan đã chọn."
function plan_name(plan, greedy)
    plan == greedy && return "greedy riêng từng kỳ"
    k = findfirst(==(plan[1]), greedy)
    k === nothing ? "baseline mọi kỳ" : "greedy t = $(k - 1) cho mọi kỳ"
end

function write_instance(io_summary, io_periods, prefix, runs)
    inst = json_to_instance(prefix)
    T, budgets = size(inst.volume, 2), inst.budget
    baseline, per_period, greedy = zeros(T), zeros(T), Vector{Vector{Vector{Int}}}(undef, T)
    greedy_seconds = zeros(runs)           # greedy_seconds[run] = tổng thời gian greedy mọi kỳ ở lần chạy run
    total_seconds = @elapsed for p in 1:T
        data = PeriodData(inst)[p]
        baseline[p] = first(baseline_mlu(data))
        for run in 1:runs
            greedy_seconds[run] += @elapsed paths = first(greedy_waypoints(data; time_limit = GREEDY_TIME_LIMIT))
            run == 1 && (greedy[p] = paths)
            paths == greedy[p] || @warn "$(inst.name) kỳ $p: greedy lần $run ra đường khác lần 1 (chạm giới hạn thời gian?)"
        end
        per_period[p] = routing_mlu(data, greedy[p])
    end
    total_seconds += @elapsed (plan, plan_mlu) = best_plan(PeriodData(inst), budgets, greedy)
    changes = [count_changes(plan[k - 1], plan[k]) for k in 2:T]
    greedy_changes = [count_changes(greedy[k - 1], greedy[k]) for k in 2:T]
    println(io_summary, "| ", join((inst.name, inst.n, length(inst.arc_from), length(inst.src), T,
                                    format_range(Int.(budgets[2:end])),
                                    @sprintf("%.4f", maximum(baseline)), @sprintf("%.4f", plan_mlu),
                                    @sprintf("%.1f%%", 100 * (maximum(baseline) - plan_mlu) / maximum(baseline)),
                                    plan_name(plan, greedy), maximum(changes), maximum(greedy_changes),
                                    @sprintf("%.4f", maximum(per_period)),
                                    format_seconds(greedy_seconds)), " | "), " |")
    println(io_periods, "| ", inst.name, " | ",
            join((@sprintf("%.3f → %.3f", baseline[k], per_period[k]) for k in 1:T), " | "), " |")
    flush(io_summary); flush(io_periods)
    println(inst.name, ": tổng ", round(total_seconds; digits = 1), " s (greedy ", format_seconds(greedy_seconds),
            " s), baseline ", round(maximum(baseline); digits = 4), " → ", round(plan_mlu; digits = 4))
    flush(stdout)
end

"Thời gian: một lần → \"1.8\"; nhiều lần → \"TB (min–max)\"."
format_seconds(seconds) = length(seconds) == 1 ? @sprintf("%.1f", seconds[1]) :
    @sprintf("%.1f (%.1f–%.1f)", sum(seconds) / length(seconds), minimum(seconds), maximum(seconds))

format_range(values) = minimum(values) == maximum(values) ? string(minimum(values)) :
                       "$(minimum(values))–$(maximum(values))"

function save_greedy_results(output_file, prefixes; runs = 1)
    greedy_waypoints(model_data(json_to_instance("../toy/toy"), 1))   # biên dịch trước: lần đo đầu không tính JIT
    summary, periods = IOBuffer(), IOBuffer()
    T_max = maximum(size(json_to_instance(prefix).volume, 2) for prefix in prefixes)
    println(summary, "| Instance | n | m | Số demand | T | κ | Baseline max_t | Greedy (thỏa budget) | Giảm | ",
                     "Phương án chọn | Thay đổi max/kỳ | Thay đổi max nếu greedy từng kỳ | Greedy từng kỳ max_t | Greedy (s) |")
    println(summary, "|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|---:|")
    println(periods, "| Instance | ", join(("t = $t" for t in 0:T_max-1), " | "), " |")
    println(periods, "|---|", repeat("---:|", T_max))
    for prefix in prefixes
        write_instance(summary, periods, prefix, runs)
        open(output_file, "w") do io      # ghi lại cả file sau mỗi instance: dừng giữa chừng vẫn có kết quả
            println(io, "# Greedy waypoint trên instance nhiều kỳ (MIP không dựng nổi)\n")
            println(io, "- Greedy riêng từng kỳ: lặp lại đổi đường các demand qua cung nặng nhất thành s → w → t ",
                        "(`greedy_waypoints.jl`), tối đa ", GREEDY_TIME_LIMIT, " s mỗi kỳ.")
            println(io, "- Greedy (thỏa budget): phương án tốt nhất trong {baseline mọi kỳ; greedy kỳ k cho mọi kỳ; ",
                        "greedy riêng từng kỳ nếu mọi bước chuyển kỳ có số thay đổi ≤ κ}, đánh giá bằng max_t MLU.")
            println(io, "- Greedy (s): tổng thời gian greedy của mọi kỳ, máy laptop (4 nhân, 15 GB)",
                        runs == 1 ? "." : "; chạy $runs lần: TB (min–max). Greedy tất định: mọi lần cùng đường đi.")
            println(io, "- Tạo bởi: `julia --project=. save_greedy_results.jl ", output_file, " ", runs == 1 ? "" : "$runs ",
                        join(prefixes, " "), "`.\n")
            println(io, String(take!(copy(summary))))
            println(io, "\nMLU từng kỳ: baseline → greedy riêng kỳ đó (chưa xét budget)\n")
            println(io, String(take!(copy(periods))))
        end
    end
    println("Đã lưu ", output_file)
end

if abspath(PROGRAM_FILE) == @__FILE__
    length(ARGS) < 2 && error("cách dùng: julia --project=. save_greedy_results.jl ../results/greedy_setB.md [số lần] ../setB/setB-01 ...")
    runs = tryparse(Int, ARGS[2])
    runs === nothing ? save_greedy_results(ARGS[1], ARGS[2:end]) : save_greedy_results(ARGS[1], ARGS[3:end]; runs)
end
