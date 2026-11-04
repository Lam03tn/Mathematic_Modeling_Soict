# =============================================================================
#  Gom các file <result_dir>/<instance>.csv (run_experiments.jl) thành MỘT bảng Markdown:
#  trung bình theo các lần chạy, đúng các cột readme yêu cầu (Step 6).
#  Thư mục start greedy (cột start_mlu): thêm cột Greedy, Greedy (s).
#  Thư mục Step 9 (cột budget): thêm cột κ(1), Thay đổi TB (số thay đổi thực tế, vế trái (4)).
#
#  Chạy (trong thư mục code/):
#    julia --project=. summarize_results.jl                       (../results/step6 → ../results/step6_results.md)
#    julia --project=. summarize_results.jl ../results/test ../results/test_results.md
# =============================================================================

using Printf

"Đọc một file kết quả (CSV do run_experiments.jl ghi, không có dấu phẩy trong ô): Dict cột → vector chuỗi."
function read_runs(file)
    lines = split.(readlines(file), ',')
    header = first(lines)
    return Dict(String(header[k]) => [String(line[k]) for line in lines[2:end]] for k in eachindex(header))
end

numbers(values) = parse.(Float64, values)
mean(x) = sum(x) / length(x)

format_number(x; digits = 4) = isnan(x) ? "—" : @sprintf("%.*f", digits, x)

"Ví dụ: [\"OPTIMAL\", \"OPTIMAL\"] → \"OPTIMAL ×2\"."
format_status(statuses) = join(("$s ×$(count(==(s), statuses))" for s in unique(statuses)), ", ")

function summarize_results(result_dir, output_file)
    names = sort(unique(first(splitext(f)) for f in readdir(result_dir)
                        if endswith(f, ".csv") || endswith(f, ".skipped") || endswith(f, ".failed")))
    runs = Dict(name => read_runs(joinpath(result_dir, name * ".csv")) for name in names
                if isfile(joinpath(result_dir, name * ".csv")))
    has_greedy = any(haskey(r, "start_mlu") for r in values(runs))
    has_budget = any(haskey(r, "budget") for r in values(runs))
    open(output_file, "w") do io
        println(io, "# Kết quả thí nghiệm (", result_dir, ")\n")
        println(io, "- Trung bình theo các lần chạy (seed khác nhau). CPU time = thời gian riêng `optimize!`.")
        println(io, "- Gap = 1 − bound / best. Mọi lần chạy bắt đầu từ nghiệm ", has_greedy ? "greedy" : "baseline",
                    " nên Best ≤ ", has_greedy ? "Greedy" : "Baseline", ".")
        println(io, "- Giảm = (baseline − best TB) / baseline.\n")
        println(io, "| Instance | n | m | Số demand | Số lần | Baseline | ", has_greedy ? "Greedy | Greedy (s) | " : "",
                    "Best TB | Best min | Giảm | Status | CPU time TB (s) | Gap TB | Nodes TB |", has_budget ? " κ(1) | Thay đổi TB |" : "")
        println(io, "|---|---:|---:|---:|---:|---:|", has_greedy ? "---:|---:|" : "", "---:|---:|---:|---|---:|---:|---:|",
                    has_budget ? "---:|---:|" : "")
        for name in names
            csv = joinpath(result_dir, name * ".csv")
            if !isfile(csv)
                reason_file = first(f for f in (joinpath(result_dir, name * ".skipped"), joinpath(result_dir, name * ".failed")) if isfile(f))
                println(io, "| ", name, " | | | | 0 | | | | | ", strip(read(reason_file, String)), " | | | |")
                continue
            end
            r = runs[name]
            best = numbers(r["best"])
            baseline = numbers(r["baseline"])[1]
            greedy = has_greedy ? (format_number(numbers(r["start_mlu"])[1]), format_number(numbers(r["start_seconds"])[1]; digits = 1)) : ()
            budget = ()
            if has_budget
                changes = filter(>=(0), numbers(r["budget_used"]))   # −1: lần chạy không có nghiệm
                budget = (format_number(numbers(r["budget"])[1]; digits = 0),
                          isempty(changes) ? "—" : format_number(mean(changes); digits = 1))
            end
            println(io, "| ", join((name, r["n"][1], r["m"][1], r["demands"][1], length(best),
                                    format_number(baseline), greedy..., format_number(mean(best)), format_number(minimum(best)),
                                    @sprintf("%.1f%%", 100 * max(0.0, (baseline - mean(best)) / baseline)),
                                    format_status(r["status"]),
                                    format_number(mean(numbers(r["seconds"])); digits = 1),
                                    format_number(mean(numbers(r["gap"]))),
                                    format_number(mean(numbers(r["nodes"])); digits = 0), budget...), " | "), " |")
        end
    end
    println("Đã lưu ", output_file)
end

if abspath(PROGRAM_FILE) == @__FILE__
    summarize_results(length(ARGS) >= 1 ? ARGS[1] : "../results/step6",
                      length(ARGS) >= 2 ? ARGS[2] : "../results/step6_results.md")
end
