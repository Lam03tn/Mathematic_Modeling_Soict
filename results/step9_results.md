# Kết quả thí nghiệm (../results/step9)

- Trung bình theo các lần chạy (seed khác nhau). CPU time = thời gian riêng `optimize!`.
- Gap = 1 − bound / best. Mọi lần chạy bắt đầu từ nghiệm baseline nên Best ≤ Baseline.
- Giảm = (baseline − best TB) / baseline.

| Instance | n | m | Số demand | Số lần | Baseline | Best TB | Best min | Giảm | Status | CPU time TB (s) | Gap TB | Nodes TB | κ(1) | Thay đổi TB |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|---:|---:|
| setA-01 | 20 | 80 | 40 | 10 | 1.0000 | 0.9294 | 0.9294 | 7.1% | OPTIMAL ×10 | 18.2 | 0.0000 | 1 | 51 | 3.4 |
| setA-02 | 30 | 150 | 45 | 3 | 1.0981 | 0.9681 | 0.9031 | 11.8% | OPTIMAL ×2, TIME_LIMIT ×1 | 1634.9 | 0.0592 | 1 | 63 | 7.7 |
| setA-03 | 50 | 250 | 20 | 3 | 1.0000 | 0.9438 | 0.9435 | 5.6% | OPTIMAL ×2, TIME_LIMIT ×1 | 1325.8 | 0.0003 | 34 | 53 | 0.7 |
| setA-04 | 50 | 250 | 200 | 3 | 1.0000 | 1.0000 | 1.0000 | 0.0% | TIME_LIMIT ×3 | 3602.8 | 1.0000 | 0 | 44 | 0.0 |
