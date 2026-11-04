# Greedy waypoint trên instance nhiều kỳ (MIP không dựng nổi)

- Greedy riêng từng kỳ: lặp lại đổi đường các demand qua cung nặng nhất thành s → w → t (`greedy_waypoints.jl`), tối đa 300.0 s mỗi kỳ.
- Greedy (thỏa budget): phương án tốt nhất trong {baseline mọi kỳ; greedy kỳ k cho mọi kỳ; greedy riêng từng kỳ nếu mọi bước chuyển kỳ có số thay đổi ≤ κ}, đánh giá bằng max_t MLU.
- Greedy (s): tổng thời gian greedy của mọi kỳ, máy desktop i5-12400 (6 nhân, 31 GB), 8 instance chạy song song — chạy lại 23/10.
- Tạo bởi: `julia --project=. save_greedy_results.jl ../results/greedy_setB_final/setB-11.md ../setB/setB-11`.

| Instance | n | m | Số demand | T | κ | Baseline max_t | Greedy (thỏa budget) | Giảm | Phương án chọn | Thay đổi max/kỳ | Thay đổi max nếu greedy từng kỳ | Greedy từng kỳ max_t | Greedy (s) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|---:|
| setB-11 | 1260 | 5036 | 14908 | 12 | 41 | 1.0000 | 0.5279 | 47.2% | greedy t = 4 cho mọi kỳ | 0 | 571 | 0.3636 | 82.7 |


MLU từng kỳ: baseline → greedy riêng kỳ đó (chưa xét budget)

| Instance | t = 0 | t = 1 | t = 2 | t = 3 | t = 4 | t = 5 | t = 6 | t = 7 | t = 8 | t = 9 | t = 10 | t = 11 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| setB-11 | 0.570 → 0.269 | 0.531 → 0.319 | 0.561 → 0.363 | 0.515 → 0.304 | 1.000 → 0.296 | 0.530 → 0.292 | 0.564 → 0.287 | 0.577 → 0.345 | 0.588 → 0.364 | 0.578 → 0.342 | 0.572 → 0.345 | 0.624 → 0.354 |

