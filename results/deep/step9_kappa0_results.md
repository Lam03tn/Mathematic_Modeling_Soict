# Kết quả thí nghiệm (../results/deep/step9_kappa0)

- Trung bình theo các lần chạy (seed khác nhau). CPU time = thời gian riêng `optimize!`.
- Gap = 1 − bound / best. Mọi lần chạy bắt đầu từ nghiệm greedy nên Best ≤ Greedy.
- Giảm = (baseline − best TB) / baseline.

| Instance | n | m | Số demand | Số lần | Baseline | Greedy | Greedy (s) | Best TB | Best min | Giảm | Status | CPU time TB (s) | Gap TB | Nodes TB | κ(1) | Thay đổi TB |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|---:|---:|
| setA-02 | 30 | 150 | 45 | 10 | 1.0981 | 1.0000 | 1.3 | 0.9031 | 0.9031 | 17.8% | OPTIMAL ×10 | 687.3 | 0.0000 | 31 | 0 | 0.0 |
| setA-03 | 50 | 250 | 20 | 10 | 1.0000 | 0.9435 | 1.2 | 0.9435 | 0.9435 | 5.6% | OPTIMAL ×10 | 25.5 | 0.0000 | 1 | 0 | 0.0 |
| setA-04 | 50 | 250 | 200 | 2 | 1.0000 | 0.6242 | 0.8 | 0.6242 | 0.6242 | 37.6% | TIME_LIMIT ×2 | 3601.7 | 0.5345 | 0 | 0 | 0.0 |
| setA-05 | 100 | 396 | 100 | 2 | 1.0000 | 0.2050 | 0.7 | 0.2050 | 0.2050 | 79.5% | OPTIMAL ×2 | 339.7 | 0.0000 | 1 | 0 | 0.0 |
