# Kết quả thí nghiệm (../results/step6_greedy)

- Trung bình theo các lần chạy (seed khác nhau). CPU time = thời gian riêng `optimize!`.
- Gap = 1 − bound / best. Mọi lần chạy bắt đầu từ nghiệm greedy nên Best ≤ Greedy.
- Giảm = (baseline − best TB) / baseline.

| Instance | n | m | Số demand | Số lần | Baseline | Greedy | Greedy (s) | Best TB | Best min | Giảm | Status | CPU time TB (s) | Gap TB | Nodes TB |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|
| setA-01 | 20 | 80 | 40 | 10 | 1.0000 | 0.9294 | 0.0 | 0.9294 | 0.9294 | 7.1% | OPTIMAL ×10 | 0.6 | 0.0000 | 1 |
| setA-02 | 30 | 150 | 45 | 10 | 1.0000 | 0.5486 | 0.0 | 0.5486 | 0.5486 | 45.1% | OPTIMAL ×10 | 0.8 | 0.0000 | 1 |
| setA-03 | 50 | 250 | 20 | 10 | 1.0000 | 0.9435 | 0.0 | 0.9435 | 0.9435 | 5.6% | OPTIMAL ×10 | 12.9 | 0.0000 | 1 |
| setA-04 | 50 | 250 | 200 | 5 | 0.6918 | 0.4628 | 0.3 | 0.4628 | 0.4628 | 33.1% | TIME_LIMIT ×5 | 1817.8 | 0.0080 | 0 |
| setA-05 | 100 | 396 | 100 | 5 | 0.3333 | 0.1216 | 0.3 | 0.1204 | 0.1155 | 63.9% | OPTIMAL ×1, TIME_LIMIT ×4 | 1714.0 | 0.0403 | 0 |
| setA-06 | 100 | 500 | 500 | 2 | 1.0000 | 0.1127 | 0.8 | 0.1127 | 0.1127 | 88.7% | TIME_LIMIT ×2 | 1809.1 | 1.0000 | 0 |
| setA-07 | 100 | 500 | 800 | 2 | 0.9080 | 0.9080 | 0.7 | 0.9080 | 0.9080 | 0.0% | TIME_LIMIT ×2 | 1811.3 | 1.0000 | 0 |
| setA-08 | 150 | 654 | 200 | 2 | 1.0000 | 0.3189 | 0.8 | 0.3189 | 0.3189 | 68.1% | OPTIMAL ×2 | 538.6 | 0.0000 | 1 |
| setA-10 | | | | 0 | | | | | không dựng: ước tính 116.0 triệu số hạng trong (3) > 100 triệu (RAM); chỉ có greedy: MLU = 0.0978 trong 2.3 s | | | |
| setA-13 | | | | 0 | | | | | không dựng: ước tính 503.0 triệu số hạng trong (3) > 100 triệu (RAM); chỉ có greedy: MLU = 0.0449 trong 10.4 s | | | |
| setA-14 | | | | 0 | | | | | không dựng: ước tính 225.0 triệu số hạng trong (3) > 100 triệu (RAM); chỉ có greedy: MLU = 0.4342 trong 0.0 s | | | |
| setA-15 | | | | 0 | | | | | không dựng: ước tính 153.0 triệu số hạng trong (3) > 100 triệu (RAM); chỉ có greedy: MLU = 0.8252 trong 0.0 s | | | |
| setA-16 | | | | 0 | | | | | không dựng: ước tính 2074.0 triệu số hạng trong (3) > 100 triệu (RAM); chỉ có greedy: MLU = 0.1352 trong 53.8 s | | | |
| setA-17 | | | | 0 | | | | | không dựng: ước tính 1115.0 triệu số hạng trong (3) > 100 triệu (RAM); chỉ có greedy: MLU = 0.4242 trong 0.0 s | | | |
| setA-18 | | | | 0 | | | | | không dựng: ước tính 750.0 triệu số hạng trong (3) > 100 triệu (RAM); chỉ có greedy: MLU = 0.6334 trong 0.0 s | | | |
| setA-19 | | | | 0 | | | | | không dựng: ước tính 3790.0 triệu số hạng trong (3) > 100 triệu (RAM); chỉ có greedy: MLU = 0.0581 trong 259.1 s | | | |
| setA-20 | | | | 0 | | | | | không dựng: ước tính 4264.0 triệu số hạng trong (3) > 100 triệu (RAM); chỉ có greedy: MLU = 0.9913 trong 0.2 s | | | |
