# Kết quả thí nghiệm (../results/deep/step9_kappainf)

- Trung bình theo các lần chạy (seed khác nhau). CPU time = thời gian riêng `optimize!`.
- Gap = 1 − bound / best. Mọi lần chạy bắt đầu từ nghiệm greedy nên Best ≤ Greedy.
- Giảm = (baseline − best TB) / baseline.

| Instance | n | m | Số demand | Số lần | Baseline | Greedy | Greedy (s) | Best TB | Best min | Giảm | Status | CPU time TB (s) | Gap TB | Nodes TB | κ(1) | Thay đổi TB |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|---:|---:|
| setA-02 | 30 | 150 | 45 | 10 | 1.0981 | 0.9031 | 1.2 | 0.9031 | 0.9031 | 17.8% | OPTIMAL ×10 | 4.6 | 0.0000 | 1 | Inf | 21.0 |
| setA-03 | 50 | 250 | 20 | 10 | 1.0000 | 0.9435 | 1.2 | 0.9435 | 0.9435 | 5.6% | OPTIMAL ×10 | 25.9 | 0.0000 | 1 | Inf | 0.0 |
| setA-04 | 50 | 250 | 200 | 3 | 1.0000 | 0.6242 | 1.2 | 0.6242 | 0.6242 | 37.6% | TIME_LIMIT ×3 | 3602.5 | 0.0690 | 0 | Inf | 0.0 |
| setA-05 | 100 | 396 | 100 | 3 | 1.0000 | 0.2050 | 1.1 | 0.2050 | 0.2050 | 79.5% | OPTIMAL ×3 | 390.8 | 0.0000 | 1 | Inf | 0.0 |
