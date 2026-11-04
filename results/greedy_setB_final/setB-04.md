# Greedy waypoint trên instance nhiều kỳ (MIP không dựng nổi)

- Greedy riêng từng kỳ: lặp lại đổi đường các demand qua cung nặng nhất thành s → w → t (`greedy_waypoints.jl`), tối đa 300.0 s mỗi kỳ.
- Greedy (thỏa budget): phương án tốt nhất trong {baseline mọi kỳ; greedy kỳ k cho mọi kỳ; greedy riêng từng kỳ nếu mọi bước chuyển kỳ có số thay đổi ≤ κ}, đánh giá bằng max_t MLU.
- Greedy (s): tổng thời gian greedy của mọi kỳ, máy desktop i5-12400 (6 nhân, 31 GB), 8 instance chạy song song — chạy lại 23/10.
- Tạo bởi: `julia --project=. save_greedy_results.jl ../results/greedy_setB_final/setB-04.md ../setB/setB-04`.

| Instance | n | m | Số demand | T | κ | Baseline max_t | Greedy (thỏa budget) | Giảm | Phương án chọn | Thay đổi max/kỳ | Thay đổi max nếu greedy từng kỳ | Greedy từng kỳ max_t | Greedy (s) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|---:|
| setB-04 | 408 | 1616 | 6874 | 12 | 78 | 1.0000 | 0.8743 | 12.6% | greedy t = 11 cho mọi kỳ | 0 | 126 | 0.6725 | 4.4 |


MLU từng kỳ: baseline → greedy riêng kỳ đó (chưa xét budget)

| Instance | t = 0 | t = 1 | t = 2 | t = 3 | t = 4 | t = 5 | t = 6 | t = 7 | t = 8 | t = 9 | t = 10 | t = 11 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| setB-04 | 0.935 → 0.473 | 1.000 → 0.673 | 0.820 → 0.541 | 0.883 → 0.517 | 0.950 → 0.492 | 0.820 → 0.517 | 0.838 → 0.422 | 0.797 → 0.497 | 0.954 → 0.558 | 0.858 → 0.461 | 0.978 → 0.611 | 0.861 → 0.455 |

