# Greedy waypoint trên instance nhiều kỳ (MIP không dựng nổi)

- Greedy riêng từng kỳ: lặp lại đổi đường các demand qua cung nặng nhất thành s → w → t (`greedy_waypoints.jl`), tối đa 300.0 s mỗi kỳ.
- Greedy (thỏa budget): phương án tốt nhất trong {baseline mọi kỳ; greedy kỳ k cho mọi kỳ; greedy riêng từng kỳ nếu mọi bước chuyển kỳ có số thay đổi ≤ κ}, đánh giá bằng max_t MLU.
- Greedy (s): tổng thời gian greedy của mọi kỳ, máy desktop i5-12400 (6 nhân, 31 GB), 8 instance chạy song song — chạy lại 23/10.
- Tạo bởi: `julia --project=. save_greedy_results.jl ../results/greedy_setB_final/setB-07.md ../setB/setB-07`.

| Instance | n | m | Số demand | T | κ | Baseline max_t | Greedy (thỏa budget) | Giảm | Phương án chọn | Thay đổi max/kỳ | Thay đổi max nếu greedy từng kỳ | Greedy từng kỳ max_t | Greedy (s) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|---:|
| setB-07 | 615 | 2444 | 2546 | 12 | 26 | 1.0000 | 0.7472 | 25.3% | greedy t = 11 cho mọi kỳ | 0 | 93 | 0.6649 | 1.7 |


MLU từng kỳ: baseline → greedy riêng kỳ đó (chưa xét budget)

| Instance | t = 0 | t = 1 | t = 2 | t = 3 | t = 4 | t = 5 | t = 6 | t = 7 | t = 8 | t = 9 | t = 10 | t = 11 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| setB-07 | 0.681 → 0.394 | 0.602 → 0.404 | 0.786 → 0.512 | 0.870 → 0.404 | 0.780 → 0.538 | 0.572 → 0.423 | 0.684 → 0.435 | 0.762 → 0.555 | 0.691 → 0.665 | 0.506 → 0.340 | 0.648 → 0.498 | 1.000 → 0.373 |

