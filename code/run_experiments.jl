# =============================================================================
#  Step 6 / Step 9 (readme) — Thí nghiệm cho MỘT instance. Ghi từng lần chạy ra
#  <result_dir>/<instance>.csv và log HiGHS của từng lần ra <result_dir>/logs/.
#    periods = 1:1 : Step 6, chỉ kỳ t = 0, mô hình Step 5 (segment_routing_model.jl)
#    periods = 1:2 : Step 9, kỳ t = 0, 1 + budget, mô hình Step 8 (multi_period_model.jl);
#                    thêm cột budget, budget_used (số thay đổi thực tế), mlu_by_period (MLU từng kỳ)
#    periods = 2:2 : mô hình Step 5 cho riêng kỳ t = 1 (tối ưu riêng kỳ đó = Step 9 với κ = ∞)
#    start = :none     : không cho HiGHS nghiệm xuất phát nào (HiGHS thuần)
#    start = :baseline : mọi lần chạy bắt đầu từ nghiệm baseline (không waypoint)
#    start = :greedy   : bắt đầu từ nghiệm greedy (greedy_waypoints.jl), tính một lần cho instance;
#                        thêm cột start_mlu, start_seconds. Instance quá lớn cho MIP vẫn ghi kết quả greedy
#                        vào file .skipped.
#  Cấu hình thêm (so sánh cấu hình, results/deep/): max_segments (MaxSeg thay cho giá trị của đề),
#    budget (κ thay cho giá trị của đề ở mọi kỳ t ≥ 1), solver_options (tuỳ chọn HiGHS, ví dụ mip_heuristic_effort).
#
#  Số lần chạy (quyết định của nhóm vì giới hạn thời gian máy), theo lần chạy đầu tiên:
#    OPTIMAL trong < SHORT_RUN_SECONDS  → run ngắn → tổng RUNS_SHORT lần (seed 0..9)
#    còn lại (lâu hơn, kể cả hết giờ)   →            tổng RUNS_OTHER lần (seed 0..4), Step 9: RUNS_OTHER_MULTI (0..2)
#  Mỗi lần: dựng lại mô hình (không tính giờ), bắt đầu từ nghiệm baseline, giải tối đa time_limit giây.
#  Chạy tiếp: nếu <instance>.csv đã có k lần thì chỉ chạy các lần k+1, k+2, ... còn thiếu.
#
#  Chạy (trong thư mục code/):
#    julia --project=. run_experiments.jl ../setA/setA-04                     (1800 s, ../results/step6)
#    julia --project=. run_experiments.jl ../setA/setA-04 60 ../results/test  (thử nhanh)
#    julia --project=. run_experiments.jl ../setA/setA-04 1800 ../results/step9 2   (Step 9)
#    julia --project=. run_experiments.jl ../setA/setA-04 1800 ../results/step6_greedy 1 greedy
#    julia --project=. run_experiments.jl ../setA/setA-04 1800 ../results/deep/step6_t1 2:2 greedy
#    julia --project=. run_experiments.jl ../setA/setA-04 1800 ../results/deep/step9_kappa0 2 greedy budget=0
#    (thêm: maxseg=2, effort=0.3, runs=1 — chặn trên số lần chạy, ví dụ chỉ 1 lần cho instance lớn)
# =============================================================================

@isdefined(greedy_plan) || include("greedy_waypoints.jl")

const SHORT_RUN_SECONDS = 60.0
const RUNS_SHORT = 10
const RUNS_OTHER = 5
const RUNS_OTHER_MULTI = 3   # Step 9 (nhiều kỳ): mỗi lần tới 3600 s nên chỉ 3 lần (quyết định của nhóm, 22/10)
# Phép thử trên server: setA-12 (88 triệu số hạng trong (3)) dùng 23,4 GB; setA-10 (116 triệu) vượt 24 GB.
# Với giới hạn 28 GB, instance ước tính trên 100 triệu số hạng bị bỏ qua thay vì dựng hàng giờ rồi hết RAM.
const MAX_LOAD_TERMS = 100_000_000
const GREEDY_TIME_LIMIT = 300.0   # giây cho greedy của mỗi kỳ (chỉ instance rất lớn mới chạm tới)

const COLUMNS = ("instance", "run", "seed", "n", "m", "demands", "status", "best", "bound", "gap",
                 "nodes", "seconds", "build_seconds", "baseline", "recomputed_mlu", "max_rss_gb")

"Số hạng trong ràng buộc (3) = Σ_{d: v(d) > 0} Σ_{i,j} |ratios[i,j]| — thước đo cỡ mô hình (RAM)."
load_terms(data) = count(!iszero, data.volume) * sum(length, data.ratios)

"Ghi log HiGHS ra file và đặt các tuỳ chọn HiGHS của cấu hình."
function set_solver_options!(model, log_file, solver_options)
    set_attribute(model, "log_file", log_file)
    set_attribute(model, "log_to_console", false)
    foreach(((name, value),) -> set_attribute(model, name, value), solver_options)
end

"Một lần chạy: dựng mô hình, đặt nghiệm xuất phát theo `start`, giải; kiểm tra lại MLU từ đường segment."
function run_once(data, seed, time_limit, log_file, start, plan, solver_options)
    build_seconds = @elapsed (model, x, mlu) = build_model(data)
    start == :baseline && start_from_baseline!(x, mlu, data)
    start == :greedy && start_from_paths!(x, mlu, data, plan[1])
    set_solver_options!(model, log_file, solver_options)
    result = solve_model!(model; time_limit, seed)
    recomputed = isnan(result.best) ? NaN : routing_mlu(data, segment_paths(x, data))
    return merge(result, (build_seconds = build_seconds, recomputed_mlu = recomputed))
end

"Tổng số lần chạy, quyết định từ lần chạy đầu tiên (status, thời gian optimize!); single = mô hình một kỳ."
planned_runs(first_status, first_seconds, single) =
    first_status == "OPTIMAL" && first_seconds < SHORT_RUN_SECONDS ? RUNS_SHORT : single ? RUNS_OTHER : RUNS_OTHER_MULTI

"Một lần chạy Step 9: mô hình nhiều kỳ, nghiệm xuất phát theo `start` ở mọi kỳ; kiểm tra lại MLU và budget."
function run_once_multi(datas, budgets, seed, time_limit, log_file, start, plan, solver_options)
    build_seconds = @elapsed (model, x, added, mlu) = build_multi_period_model(datas, budgets)
    start == :baseline && start_all_periods_from_baseline!(x, added, mlu, datas)
    start == :greedy && start_all_periods_from_plan!(x, added, mlu, datas, plan)
    set_solver_options!(model, log_file, solver_options)
    result = solve_model!(model; time_limit, seed)
    per_period = isnan(result.best) ? fill(NaN, length(datas)) : mlu_by_period(x, datas)
    used = isnan(result.best) ? [-1] : budget_used(x, length(datas))
    return merge(result, (build_seconds = build_seconds, recomputed_mlu = maximum(per_period),
                          budget_used = join(used, ";"), mlu_by_period = join(per_period, ";")))
end

function run_experiments(prefix; time_limit = 1800.0, result_dir = "../results/step6", periods = 1:1, start = :baseline,
                         max_segments = nothing, budget = nothing, solver_options = Dict{String,Any}(),
                         max_runs = nothing)
    start in (:none, :baseline, :greedy) || error("start phải là :none, :baseline hoặc :greedy, không phải $start")
    inst = json_to_instance(prefix)
    datas, budgets = multi_period_data(inst, periods)
    max_segments === nothing || (datas = [merge(d, (max_segments = max_segments,)) for d in datas])
    budget === nothing || (budgets = [k == 1 ? Inf : Float64(budget) for k in eachindex(budgets)])
    single = length(periods) == 1           # một kỳ: mô hình Step 5; nhiều kỳ: mô hình Step 8
    data = datas[1]
    mkpath(joinpath(result_dir, "logs"))
    plan, start_columns, start_values = nothing, (), ()
    if start == :greedy
        start_seconds = @elapsed (plan, start_mlu) = greedy_plan(datas, budgets; time_limit = GREEDY_TIME_LIMIT)
        start_columns, start_values = ("start_mlu", "start_seconds"), (start_mlu, start_seconds)
    end
    terms = sum(load_terms, datas)
    if terms > MAX_LOAD_TERMS
        msg = "không dựng: ước tính $(round(terms / 1e6; digits = 0)) triệu số hạng trong (3) > $(MAX_LOAD_TERMS ÷ 1_000_000) triệu (RAM)"
        start == :greedy && (msg *= "; chỉ có greedy: MLU = $(round(start_values[1]; digits = 4)) trong $(round(start_values[2]; digits = 1)) s")
        write(joinpath(result_dir, inst.name * ".skipped"), msg * "\n")
        println(inst.name, ": ", msg)
        return
    end
    baseline = maximum(first(baseline_mlu(d)) for d in datas)
    columns = (COLUMNS..., (single ? () : ("budget", "budget_used", "mlu_by_period"))..., start_columns...)
    csv = joinpath(result_dir, inst.name * ".csv")
    done = isfile(csv) ? split.(readlines(csv)[2:end], ',') : Vector{SubString{String}}[]
    isfile(csv) || write(csv, join(columns, ",") * "\n")
    capped(r) = max_runs === nothing ? r : min(r, max_runs)
    runs = capped(isempty(done) ? (single ? RUNS_OTHER : RUNS_OTHER_MULTI) : planned_runs(done[1][7], parse(Float64, done[1][12]), single))
    open(csv, "a") do io
        run = length(done) + 1
        while run <= runs
            seed = run - 1
            log_file = joinpath(result_dir, "logs", "$(inst.name)_run$(run).log")
            r = single ? run_once(data, seed, time_limit, log_file, start, plan, solver_options) :
                         run_once_multi(datas, budgets, seed, time_limit, log_file, start, plan, solver_options)
            extra = single ? () : (budgets[end], r.budget_used, r.mlu_by_period)
            run == 1 && (runs = capped(planned_runs(string(r.status), r.seconds, single)))
            println(io, join((inst.name, run, seed, inst.n, length(data.arcs), length(data.demands),
                              r.status, r.best, r.bound, r.gap, r.nodes, r.seconds, r.build_seconds,
                              baseline, r.recomputed_mlu, round(Sys.maxrss() / 2^30; digits = 2), extra..., start_values...), ","))
            flush(io)
            println(inst.name, " lần ", run, "/", runs, ": ", r.status, ", best = ", round(r.best; digits = 4),
                    ", gap = ", round(r.gap; digits = 4), ", optimize! = ", round(r.seconds; digits = 1), " s")
            GC.gc()
            run += 1
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    isempty(ARGS) && error("cách dùng: julia --project=. run_experiments.jl ../setA/setA-04 [time_limit] [result_dir] " *
                           "[periods: 1 | 2 | 2:2] [none|baseline|greedy] [maxseg=2] [budget=0] [effort=0.3] [runs=1]")
    # "2" → 1:2 (số kỳ), "2:2" → 2:2 (khoảng kỳ)
    parse_periods(s) = occursin(':', s) ? UnitRange(parse.(Int, split(s, ':'))...) : 1:parse(Int, s)
    options = Dict(split(a, '=')[1] => split(a, '=')[2] for a in ARGS[6:end])
    issubset(keys(options), ("maxseg", "budget", "effort", "runs")) || error("tuỳ chọn không hỗ trợ: $(keys(options))")
    run_experiments(ARGS[1];
        time_limit = length(ARGS) >= 2 ? parse(Float64, ARGS[2]) : 1800.0,
        result_dir = length(ARGS) >= 3 ? ARGS[3] : "../results/step6",
        periods = length(ARGS) >= 4 ? parse_periods(ARGS[4]) : 1:1,
        start = length(ARGS) >= 5 ? Symbol(ARGS[5]) : :baseline,
        max_segments = haskey(options, "maxseg") ? parse(Int, options["maxseg"]) : nothing,
        budget = haskey(options, "budget") ? parse(Float64, options["budget"]) : nothing,
        solver_options = haskey(options, "effort") ?
            Dict{String,Any}("mip_heuristic_effort" => parse(Float64, options["effort"])) : Dict{String,Any}(),
        max_runs = haskey(options, "runs") ? parse(Int, options["runs"]) : nothing)
end
