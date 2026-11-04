# Greedy waypoint trên instance nhiều kỳ (MIP không dựng nổi)

- Greedy riêng từng kỳ: lặp lại đổi đường các demand qua cung nặng nhất thành s → w → t (`greedy_waypoints.jl`), tối đa 300.0 s mỗi kỳ.
- Greedy (thỏa budget): phương án tốt nhất trong {baseline mọi kỳ; greedy kỳ k cho mọi kỳ; greedy riêng từng kỳ nếu mọi bước chuyển kỳ có số thay đổi ≤ κ}, đánh giá bằng max_t MLU.
- Greedy (s): tổng thời gian greedy của mọi kỳ, máy desktop i5-12400 (6 nhân, 31 GB), 8 instance chạy song song — chạy lại 23/10.
- Tạo bởi: `julia --project=. save_greedy_results.jl ../results/greedy_setB_final/setB-12.md ../setB/setB-12`.

| Instance | n | m | Số demand | T | κ | Baseline max_t | Greedy (thỏa budget) | Giảm | Phương án chọn | Thay đổi max/kỳ | Thay đổi max nếu greedy từng kỳ | Greedy từng kỳ max_t | Greedy (s) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|---:|
| setB-12 | 1263 | 4454 | 15000 | 12 | 10 | 1.0000 | 0.6297 | 37.0% | greedy t = 4 cho mọi kỳ | 0 | 7 | 0.6501 | 0.7 |


MLU từng kỳ: baseline → greedy riêng kỳ đó (chưa xét budget)

| Instance | t = 0 | t = 1 | t = 2 | t = 3 | t = 4 | t = 5 | t = 6 | t = 7 | t = 8 | t = 9 | t = 10 | t = 11 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| setB-12 | 0.433 → 0.230 | 0.260 → 0.159 | 0.336 → 0.181 | 0.545 → 0.394 | 1.000 → 0.587 | 0.925 → 0.602 | 0.868 → 0.609 | 0.965 → 0.650 | 0.780 → 0.519 | 0.751 → 0.475 | 0.729 → 0.436 | 0.416 → 0.243 |

