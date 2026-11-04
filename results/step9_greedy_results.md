# Kết quả thí nghiệm (../results/step9_greedy)

- Trung bình theo các lần chạy (seed khác nhau). CPU time = thời gian riêng `optimize!`.
- Gap = 1 − bound / best. Mọi lần chạy bắt đầu từ nghiệm greedy nên Best ≤ Greedy.
- Giảm = (baseline − best TB) / baseline.

| Instance | n | m | Số demand | Số lần | Baseline | Greedy | Greedy (s) | Best TB | Best min | Giảm | Status | CPU time TB (s) | Gap TB | Nodes TB | κ(1) | Thay đổi TB |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---:|---:|---:|
| setA-01 | 20 | 80 | 40 | 10 | 1.0000 | 0.9294 | 1.5 | 0.9294 | 0.9294 | 7.1% | OPTIMAL ×10 | 2.6 | 0.0000 | 1 | 51 | 0.0 |
| setA-02 | 30 | 150 | 45 | 3 | 1.0981 | 0.9031 | 1.6 | 0.9031 | 0.9031 | 17.8% | OPTIMAL ×3 | 729.7 | 0.0000 | 1 | 63 | 21.0 |
| setA-03 | 50 | 250 | 20 | 3 | 1.0000 | 0.9435 | 0.9 | 0.9435 | 0.9435 | 5.6% | OPTIMAL ×3 | 286.8 | 0.0000 | 1 | 53 | 0.0 |
| setA-04 | 50 | 250 | 200 | 3 | 1.0000 | 0.6242 | 1.3 | 0.6242 | 0.6242 | 37.6% | TIME_LIMIT ×3 | 3605.0 | 1.0000 | 0 | 44 | 0.0 |
| setA-05 | 100 | 396 | 100 | 1 | 1.0000 | 0.2050 | 0.8 | 0.2050 | 0.2050 | 79.5% | OPTIMAL ×1 | 1135.5 | 0.0000 | 1 | 1 | 0.0 |
| setA-10 | | | | 0 | | | | | không dựng: ước tính 231.0 triệu số hạng trong (3) > 100 triệu (RAM); chỉ có greedy: MLU = 0.2761 trong 4.4 s | | | |
| setA-11 | | | | 0 | | | | | không dựng: ước tính 127.0 triệu số hạng trong (3) > 100 triệu (RAM); chỉ có greedy: MLU = 0.7858 trong 0.0 s | | | |
| setA-12 | | | | 0 | | | | | không dựng: ước tính 177.0 triệu số hạng trong (3) > 100 triệu (RAM); chỉ có greedy: MLU = 0.8799 trong 0.0 s | | | |
| setA-13 | | | | 0 | | | | | không dựng: ước tính 1007.0 triệu số hạng trong (3) > 100 triệu (RAM); chỉ có greedy: MLU = 0.1923 trong 17.5 s | | | |
| setA-14 | | | | 0 | | | | | không dựng: ước tính 451.0 triệu số hạng trong (3) > 100 triệu (RAM); chỉ có greedy: MLU = 0.5331 trong 0.0 s | | | |
| setA-15 | | | | 0 | | | | | không dựng: ước tính 308.0 triệu số hạng trong (3) > 100 triệu (RAM); chỉ có greedy: MLU = 0.8987 trong 0.0 s | | | |
| setA-16 | | | | 0 | | | | | không dựng: ước tính 4151.0 triệu số hạng trong (3) > 100 triệu (RAM); chỉ có greedy: MLU = 0.3852 trong 77.2 s | | | |
| setA-17 | | | | 0 | | | | | không dựng: ước tính 2231.0 triệu số hạng trong (3) > 100 triệu (RAM); chỉ có greedy: MLU = 0.4242 trong 0.0 s | | | |
| setA-18 | | | | 0 | | | | | không dựng: ước tính 1501.0 triệu số hạng trong (3) > 100 triệu (RAM); chỉ có greedy: MLU = 1.0 trong 0.0 s | | | |
| setA-19 | | | | 0 | | | | | không dựng: ước tính 7582.0 triệu số hạng trong (3) > 100 triệu (RAM); chỉ có greedy: MLU = 0.1686 trong 459.8 s | | | |
| setA-20 | | | | 0 | | | | | không dựng: ước tính 8526.0 triệu số hạng trong (3) > 100 triệu (RAM); chỉ có greedy: MLU = 0.9913 trong 0.4 s | | | |
