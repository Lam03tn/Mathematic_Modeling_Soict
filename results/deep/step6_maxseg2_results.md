# Kết quả thí nghiệm (../results/deep/step6_maxseg2)

- Trung bình theo các lần chạy (seed khác nhau). CPU time = thời gian riêng `optimize!`.
- Gap = 1 − bound / best. Mọi lần chạy bắt đầu từ nghiệm greedy nên Best ≤ Greedy.
- Giảm = (baseline − best TB) / baseline.

| Instance | n | m | Số demand | Số lần | Baseline | Greedy | Greedy (s) | Best TB | Best min | Giảm | Status | CPU time TB (s) | Gap TB | Nodes TB |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|
| setA-02 | 30 | 150 | 45 | 10 | 1.0000 | 0.5486 | 1.0 | 0.5486 | 0.5486 | 45.1% | OPTIMAL ×10 | 5.4 | 0.0000 | 0 |
| setA-03 | 50 | 250 | 20 | 5 | 1.0000 | 0.9435 | 1.2 | 0.9435 | 0.9435 | 5.6% | OPTIMAL ×5 | 110.9 | 0.0000 | 1 |
| setA-04 | 50 | 250 | 200 | 5 | 0.6918 | 0.4628 | 1.5 | 0.4628 | 0.4628 | 33.1% | TIME_LIMIT ×5 | 1801.7 | 0.0080 | 0 |
| setA-05 | 100 | 396 | 100 | 5 | 0.3333 | 0.1216 | 1.4 | 0.1216 | 0.1216 | 63.5% | TIME_LIMIT ×5 | 1822.4 | Inf | 0 |
