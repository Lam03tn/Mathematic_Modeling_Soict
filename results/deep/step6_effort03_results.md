# Kết quả thí nghiệm (../results/deep/step6_effort03)

- Trung bình theo các lần chạy (seed khác nhau). CPU time = thời gian riêng `optimize!`.
- Gap = 1 − bound / best. Mọi lần chạy bắt đầu từ nghiệm greedy nên Best ≤ Greedy.
- Giảm = (baseline − best TB) / baseline.

| Instance | n | m | Số demand | Số lần | Baseline | Greedy | Greedy (s) | Best TB | Best min | Giảm | Status | CPU time TB (s) | Gap TB | Nodes TB |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|
| setA-02 | 30 | 150 | 45 | 10 | 1.0000 | 0.5486 | 1.0 | 0.5486 | 0.5486 | 45.1% | OPTIMAL ×10 | 1.0 | 0.0000 | 1 |
| setA-03 | 50 | 250 | 20 | 10 | 1.0000 | 0.9435 | 1.2 | 0.9435 | 0.9435 | 5.6% | OPTIMAL ×10 | 14.6 | 0.0000 | 1 |
| setA-04 | 50 | 250 | 200 | 5 | 0.6918 | 0.4628 | 1.5 | 0.4628 | 0.4628 | 33.1% | TIME_LIMIT ×5 | 1801.9 | 0.0080 | 0 |
| setA-05 | 100 | 396 | 100 | 5 | 0.3333 | 0.1216 | 1.1 | 0.1204 | 0.1155 | 63.9% | OPTIMAL ×1, TIME_LIMIT ×4 | 1757.7 | 0.0403 | 0 |
