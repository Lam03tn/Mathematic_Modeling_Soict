# Kết quả thí nghiệm (../results/deep/step6_none)

- Trung bình theo các lần chạy (seed khác nhau). CPU time = thời gian riêng `optimize!`.
- Gap = 1 − bound / best. Mọi lần chạy bắt đầu từ nghiệm baseline nên Best ≤ Baseline.
- Giảm = (baseline − best TB) / baseline.

| Instance | n | m | Số demand | Số lần | Baseline | Best TB | Best min | Giảm | Status | CPU time TB (s) | Gap TB | Nodes TB |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|
| setA-02 | 30 | 150 | 45 | 10 | 1.0000 | 0.5486 | 0.5486 | 45.1% | OPTIMAL ×10 | 16.5 | 0.0000 | 1 |
| setA-03 | 50 | 250 | 20 | 10 | 1.0000 | 0.9435 | 0.9435 | 5.6% | OPTIMAL ×10 | 33.4 | 0.0000 | 1 |
| setA-04 | 50 | 250 | 200 | 5 | 0.6918 | — | — | NaN% | TIME_LIMIT ×5 | 1806.2 | — | 0 |
| setA-05 | 100 | 396 | 100 | 5 | 0.3333 | — | — | NaN% | TIME_LIMIT ×5 | 2531.2 | — | 0 |
