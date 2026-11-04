# Kết quả thí nghiệm (../results/step6)

- Trung bình theo các lần chạy (seed khác nhau). CPU time = thời gian riêng `optimize!`.
- Gap = 1 − bound / best. Mọi lần chạy bắt đầu từ nghiệm baseline nên Best ≤ Baseline.
- Giảm = (baseline − best TB) / baseline.

| Instance | n | m | Số demand | Số lần | Baseline | Best TB | Best min | Giảm | Status | CPU time TB (s) | Gap TB | Nodes TB |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|
| setA-01 | 20 | 80 | 40 | 10 | 1.0000 | 0.9294 | 0.9294 | 7.1% | OPTIMAL ×10 | 3.6 | 0.0000 | 1 |
| setA-02 | 30 | 150 | 45 | 10 | 1.0000 | 0.5486 | 0.5486 | 45.1% | OPTIMAL ×10 | 8.9 | 0.0000 | 1 |
| setA-03 | 50 | 250 | 20 | 10 | 1.0000 | 0.9435 | 0.9435 | 5.6% | OPTIMAL ×10 | 11.2 | 0.0000 | 1 |
| setA-04 | 50 | 250 | 200 | 5 | 0.6918 | 0.6632 | 0.5488 | 4.1% | TIME_LIMIT ×5 | 1802.6 | 0.3018 | 0 |
| setA-05 | 100 | 396 | 100 | 5 | 0.3333 | 0.1664 | 0.1155 | 50.1% | OPTIMAL ×2, TIME_LIMIT ×3 | 2926.8 | 0.1825 | 0 |
| setA-06 | 100 | 500 | 500 | 2 | 1.0000 | 1.0000 | 1.0000 | 0.0% | TIME_LIMIT ×2 | 1807.5 | 1.0000 | 0 |
| setA-07 | 100 | 500 | 800 | 2 | 0.9080 | 0.9080 | 0.9080 | 0.0% | TIME_LIMIT ×2 | 1812.3 | 1.0000 | 0 |
| setA-08 | 150 | 654 | 200 | 2 | 1.0000 | 1.0000 | 1.0000 | 0.0% | TIME_LIMIT ×2 | 3321.6 | 0.6811 | 0 |
| setA-09 | 150 | 750 | 200 | 5 | 0.6111 | 0.6111 | 0.6111 | 0.0% | TIME_LIMIT ×5 | 1805.5 | 0.1730 | 0 |
| setA-10 | | | | 0 | | | | | không dựng: ước tính 116.0 triệu số hạng trong (3) > 100 triệu (RAM) | | | |
| setA-13 | | | | 0 | | | | | không dựng: ước tính 503.0 triệu số hạng trong (3) > 100 triệu (RAM) | | | |
| setA-14 | | | | 0 | | | | | không dựng: ước tính 225.0 triệu số hạng trong (3) > 100 triệu (RAM) | | | |
| setA-15 | | | | 0 | | | | | không dựng: ước tính 153.0 triệu số hạng trong (3) > 100 triệu (RAM) | | | |
| setA-16 | | | | 0 | | | | | không dựng: ước tính 2074.0 triệu số hạng trong (3) > 100 triệu (RAM) | | | |
| setA-17 | | | | 0 | | | | | không dựng: ước tính 1115.0 triệu số hạng trong (3) > 100 triệu (RAM) | | | |
| setA-18 | | | | 0 | | | | | không dựng: ước tính 750.0 triệu số hạng trong (3) > 100 triệu (RAM) | | | |
| setA-19 | | | | 0 | | | | | không dựng: ước tính 3790.0 triệu số hạng trong (3) > 100 triệu (RAM) | | | |
| setA-20 | | | | 0 | | | | | không dựng: ước tính 4264.0 triệu số hạng trong (3) > 100 triệu (RAM) | | | |
