# =============================================================================
#  Đo lại greedy ở t = 0 (phiên bản cuối của greedy_waypoints.jl) trên mọi instance setA, cho Bảng 3 của báo cáo.
#  Thời gian đo giống run_experiments.jl: chỉ lời gọi greedy, không tính đọc dữ liệu và tính hệ số r.
#
#  Chạy (trong thư mục code/):
#    julia --project=. greedy_times.jl ../results/greedy_setA_t0.md
# =============================================================================
include("run_experiments.jl")

open(ARGS[1], "w") do io
    println(io, "| Instance | MLU baseline | MLU greedy | Thời gian greedy (s) |\n|---|---|---|---|")
    for k in 1:20
        name = "setA-" * lpad(k, 2, '0')
        datas, _ = multi_period_data(json_to_instance("../setA/" * name), 1:1)
        seconds = @elapsed (_, mlu) = greedy_waypoints(datas[1]; time_limit = GREEDY_TIME_LIMIT)
        row = "| $name | $(round(first(baseline_mlu(datas[1])); digits = 4)) | $(round(mlu; digits = 4)) | $(round(seconds; digits = 1)) |"
        println(io, row); flush(io)
        println(row)
    end
end
