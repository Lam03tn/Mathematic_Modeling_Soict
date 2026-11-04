# Greedy waypoint trên instance nhiều kỳ (MIP không dựng nổi)

- Greedy riêng từng kỳ: lặp lại đổi đường các demand qua cung nặng nhất thành s → w → t (`greedy_waypoints.jl`), tối đa 300.0 s mỗi kỳ.
- Greedy (thỏa budget): phương án tốt nhất trong {baseline mọi kỳ; greedy kỳ k cho mọi kỳ; greedy riêng từng kỳ nếu mọi bước chuyển kỳ có số thay đổi ≤ κ}, đánh giá bằng max_t MLU.
- Greedy (s): tổng thời gian greedy của mọi kỳ, máy laptop (4 nhân, 15 GB).
- Tạo bởi: `julia --project=. save_greedy_results.jl ../results/greedy_setC_2.md ../setC/setC-01 ../setC/setC-04 ../setC/setC-03 ../setC/setC-12`.

| Instance | n | m | Số demand | T | κ | Baseline max_t | Greedy (thỏa budget) | Giảm | Phương án chọn | Thay đổi max/kỳ | Thay đổi max nếu greedy từng kỳ | Greedy từng kỳ max_t | Greedy (s) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|---:|
| setC-01 | 1372 | 5178 | 6649 | 24 | 2 | 2.0000 | 1.5532 | 22.3% | greedy t = 6 cho mọi kỳ | 0 | 85 | 1.6516 | 7236.4 |
| setC-04 | 1566 | 5214 | 5217 | 24 | 2 | 2.0000 | 1.1058 | 44.7% | greedy riêng từng kỳ | 0 | 0 | 1.1058 | 1158.3 |


MLU từng kỳ: baseline → greedy riêng kỳ đó (chưa xét budget)

| Instance | t = 0 | t = 1 | t = 2 | t = 3 | t = 4 | t = 5 | t = 6 | t = 7 | t = 8 | t = 9 | t = 10 | t = 11 | t = 12 | t = 13 | t = 14 | t = 15 | t = 16 | t = 17 | t = 18 | t = 19 | t = 20 | t = 21 | t = 22 | t = 23 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| setC-01 | 2.000 → 1.630 | 2.000 → 1.554 | 2.000 → 1.554 | 2.000 → 1.630 | 2.000 → 1.562 | 2.000 → 1.630 | 2.000 → 1.553 | 2.000 → 1.617 | 2.000 → 1.562 | 2.000 → 1.630 | 2.000 → 1.564 | 2.000 → 1.639 | 2.000 → 1.567 | 2.000 → 1.637 | 2.000 → 1.567 | 2.000 → 1.652 | 2.000 → 1.572 | 2.000 → 1.639 | 2.000 → 1.567 | 2.000 → 1.572 | 2.000 → 1.567 | 2.000 → 1.647 | 2.000 → 1.652 | 2.000 → 1.626 |
| setC-04 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 | 2.000 → 1.106 |

