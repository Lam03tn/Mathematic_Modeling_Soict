# Greedy waypoint trên instance nhiều kỳ (MIP không dựng nổi)

- Greedy riêng từng kỳ: lặp lại đổi đường các demand qua cung nặng nhất thành s → w → t (`greedy_waypoints.jl`), tối đa 300.0 s mỗi kỳ.
- Greedy (thỏa budget): phương án tốt nhất trong {baseline mọi kỳ; greedy kỳ k cho mọi kỳ; greedy riêng từng kỳ nếu mọi bước chuyển kỳ có số thay đổi ≤ κ}, đánh giá bằng max_t MLU.
- Greedy (s): tổng thời gian greedy của mọi kỳ, máy desktop i5-12400 (6 nhân, 31 GB), 5 instance chạy song song — chạy lại 23/10 bằng greedy bản cuối.
- Tạo bởi: `julia --project=. save_greedy_results.jl ../results/greedy_setC_final/setC-06.md ../setC/setC-06`.

| Instance | n | m | Số demand | T | κ | Baseline max_t | Greedy (thỏa budget) | Giảm | Phương án chọn | Thay đổi max/kỳ | Thay đổi max nếu greedy từng kỳ | Greedy từng kỳ max_t | Greedy (s) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|---:|
| setC-06 | 835 | 2662 | 5003 | 24 | 8 | 1.0000 | 0.9000 | 10.0% | greedy t = 23 cho mọi kỳ | 0 | 6 | 0.9000 | 7200.1 |


MLU từng kỳ: baseline → greedy riêng kỳ đó (chưa xét budget)

| Instance | t = 0 | t = 1 | t = 2 | t = 3 | t = 4 | t = 5 | t = 6 | t = 7 | t = 8 | t = 9 | t = 10 | t = 11 | t = 12 | t = 13 | t = 14 | t = 15 | t = 16 | t = 17 | t = 18 | t = 19 | t = 20 | t = 21 | t = 22 | t = 23 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| setC-06 | 0.900 → 0.900 | 0.900 → 0.900 | 0.900 → 0.900 | 0.900 → 0.900 | 0.900 → 0.900 | 0.900 → 0.900 | 0.900 → 0.900 | 0.900 → 0.900 | 0.900 → 0.900 | 0.900 → 0.900 | 0.900 → 0.900 | 0.900 → 0.900 | 0.900 → 0.900 | 0.900 → 0.900 | 0.900 → 0.900 | 0.900 → 0.900 | 0.900 → 0.900 | 0.900 → 0.900 | 0.900 → 0.900 | 0.900 → 0.900 | 0.900 → 0.900 | 0.900 → 0.900 | 0.900 → 0.900 | 1.000 → 0.900 |

