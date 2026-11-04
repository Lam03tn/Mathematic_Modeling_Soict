# Greedy waypoint trên instance nhiều kỳ (MIP không dựng nổi)

- Greedy riêng từng kỳ: lặp lại đổi đường các demand qua cung nặng nhất thành s → w → t (`greedy_waypoints.jl`), tối đa 300.0 s mỗi kỳ.
- Greedy (thỏa budget): phương án tốt nhất trong {baseline mọi kỳ; greedy kỳ k cho mọi kỳ; greedy riêng từng kỳ nếu mọi bước chuyển kỳ có số thay đổi ≤ κ}, đánh giá bằng max_t MLU.
- Greedy (s): tổng thời gian greedy của mọi kỳ, máy desktop i5-12400 (6 nhân, 31 GB), 8 instance chạy song song — chạy lại 23/10.
- Tạo bởi: `julia --project=. save_greedy_results.jl ../results/greedy_setB_final/setB-06.md ../setB/setB-06`.

| Instance | n | m | Số demand | T | κ | Baseline max_t | Greedy (thỏa budget) | Giảm | Phương án chọn | Thay đổi max/kỳ | Thay đổi max nếu greedy từng kỳ | Greedy từng kỳ max_t | Greedy (s) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|---:|
| setB-06 | 598 | 1740 | 6985 | 12 | 10 | 1.0000 | 1.0000 | 0.0% | greedy riêng từng kỳ | 0 | 0 | 1.0000 | 0.5 |


MLU từng kỳ: baseline → greedy riêng kỳ đó (chưa xét budget)

| Instance | t = 0 | t = 1 | t = 2 | t = 3 | t = 4 | t = 5 | t = 6 | t = 7 | t = 8 | t = 9 | t = 10 | t = 11 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| setB-06 | 0.546 → 0.546 | 0.835 → 0.835 | 0.680 → 0.680 | 0.743 → 0.743 | 0.696 → 0.696 | 1.000 → 1.000 | 0.707 → 0.707 | 0.667 → 0.667 | 0.590 → 0.590 | 0.602 → 0.602 | 0.602 → 0.602 | 0.571 → 0.571 |

