# T-Adaptive Segment Routing: a MILP model and a waypoint heuristic

Course project, Mathematical Modelling, SoICT – Hanoi University of Science and Technology, October 2026.

The problem is the Orange subject of the EURO/ROADEF Challenge 2026
([official repository](https://gitlab.com/Orange-OpenSource/network-optimization-tools/challenge-roadef-2026)):
choose a segment path for every traffic demand in every period of a network with planned link failures,
under a budget on the routing changes between periods, so that the maximum link utilization (MLU) is minimal.

The report and the slides are submitted separately; the tables and figures cited below are those of the report.

## Repository layout

```
code/      Julia code: data, MILP models, greedy heuristic, experiment and summary scripts
setA/ setB/ setC/ toy/   instances (three JSON files each: -net, -tm, -scenario)
results/   every run used in the report: one CSV per instance, HiGHS log of every run, summary tables
```

## Code

| File | Role |
|---|---|
| `read_instance.jl` | reads the three JSON files of an instance |
| `split_ratios.jl` | split coefficients `r(i,j,a,t)`: shortest-path counting with Dijkstra, no path enumeration |
| `model_data.jl` | model data of one period (graph `G_t`, volumes, capacities, coefficients) |
| `baseline_mlu.jl` | MLU of the baseline routing (no waypoint), path counting and ECMP |
| `segment_routing_model.jl` | MILP for one period, constraints (1)–(3) |
| `multi_period_model.jl` | MILP for several periods with the change budget (4a)–(4c) |
| `greedy_waypoints.jl` | greedy waypoint heuristic, multi-period plan, MIP starts |
| `run_experiments.jl` | runs one instance several times with different HiGHS seeds, writes CSV and logs |
| `summarize_results.jl` | averages the CSV files of a folder into a Markdown table |
| `save_greedy_results.jl` | heuristic on multi-period instances (setB, setC) |
| `save_baseline_mlu.jl`, `greedy_times.jl` | baseline MLU table, greedy table on setA |
| `compare_start_logs.jl`, `start_progress_plot.jl` | best solution over time from the HiGHS logs, Figure 1 (writes `../report/start_progress.tex`) |

Code comments and progress messages are in Vietnamese.

### Running

Julia 1.13.2; JuMP 1.32.1, HiGHS.jl 1.26.0 (HiGHS 1.15.1), Graphs.jl 1.15.0, JSON3 (versions pinned in
`code/Manifest.toml`). All commands run inside `code/`:

```bash
cd code
julia --project=. -e 'using Pkg; Pkg.instantiate()'

# self-checks on toy and setA-01..03 (greedy vs known optima, MIP starts feasible for both models)
julia --project=. greedy_waypoints.jl

# exact model, one period (t = 0), 1800 s, start from the baseline or from the greedy solution
julia --project=. run_experiments.jl ../setA/setA-04 1800 ../results/step6 1 baseline
julia --project=. run_experiments.jl ../setA/setA-04 1800 ../results/step6_greedy 1 greedy

# two periods (t = 0, 1) with the change budget, 3600 s
julia --project=. run_experiments.jl ../setA/setA-04 3600 ../results/step9_greedy 2 greedy

# variants: budget=0 | budget=Inf, maxseg=2, effort=0.3 (HiGHS mip_heuristic_effort), runs=k;
# periods "2:2" solves period t = 1 alone; start "none" gives HiGHS no starting solution
julia --project=. run_experiments.jl ../setA/setA-04 3600 ../results/deep/step9_kappa0 2 greedy budget=0

# heuristic on setB / setC, summary table of a result folder
julia --project=. save_greedy_results.jl ../results/greedy_setB.md ../setB/setB-01 ../setB/setB-02
julia --project=. summarize_results.jl ../results/step6 ../results/step6_results.md
```

`run_experiments.jl` resumes: if `<instance>.csv` already has k runs, only the missing runs are made.
The exact model fits in memory up to setA-09 (about 14 GB); larger instances are skipped with a `.skipped`
file that records the reason.

## Results

Each folder holds `<instance>.csv` (one row per run: status, best MLU, LP bound, gap, nodes, time, memory,
and the MLU recomputed independently from the decoded paths) and `logs/<instance>_runK.log`, the full HiGHS
log of run K: presolve, root LP, best bound and best solution over time, final report. The `*.log` and
`*_results.md` files next to a folder are the progress log and the summary table of that experiment.
The folder names follow the steps of the course assignment (Step 6: one period, Step 9: two periods).

| Report | Folder in `results/` | Runs per instance |
|---|---|---|
| Table 2, exact model at t = 0 | `step6` (baseline start), `step6_greedy` (greedy start) | 10 (setA-01–03), 5 (04, 05), 2 to 5 (06–09) |
| Table 3, heuristic on setA | `greedy_setA_t0.md`, `greedy_times.log` | deterministic |
| Figure 1, best MLU over time | `start_comparison.md`, logs of `step6`, `step6_greedy` | |
| Table 4, solver and model settings | `deep/step6_none`, `deep/step6_maxseg2`, `deep/step6_effort03` | 10 or 5 |
| Table 5, two periods | `step9`, `step9_greedy` | 10 (setA-01), 2 or 3 (02–05) |
| Table 6, change budget | `deep/step9_kappa0`, `deep/step9_kappainf`, `step9_greedy`; period t = 1 alone: `deep/step6_t1` | 10 or 2–3 |
| Section 2.6, budget as one dense row (presolve 23 794 s) | `deep/step9_dense_budget` | 1 |
| Table 7, setB and setC | `greedy_setB.md`, `greedy_setC_*.md`, per instance in `greedy_setB_final`, `greedy_setC_final` | deterministic |
| Baseline MLU of every period (Section 3.1) | `baseline_mlu.md` | |

`setA09_greedy.log` and `step6_greedy/setA-09.csv` come from a run made after the report (setA-09 from the
greedy start, 2 seeds): HiGHS stops at the time limit without improving the greedy value 0.5376. It is not in the
report.

Machine: Intel Core i5-12400 (6 cores, 12 threads), 31 GB, Linux; several jobs ran in parallel as far as
memory allowed.
