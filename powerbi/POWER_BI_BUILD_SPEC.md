# Power BI build spec — Olist Late Delivery to Revenue Associated

> Note 17 Nov 2026: the screenshots in `screenshots/` are matplotlib previews made from the same `results/` CSVs, **not** Power BI Desktop screenshots. Do not present them as Power BI screenshots. Follow this spec on Windows in Power BI Desktop, build the 4 pages, take real screenshots, and replace the previews.

Build this in Power BI Desktop from `Olist_PowerBI_Data.xlsx` in this folder. No `.pbix` is shipped, because the file was built on Linux — follow these steps and the result will match the screenshots in `screenshots/`.

## Rule 1 — build only from results/
Import the Excel workbook. Each sheet is one `results/` CSV, already exported from SQL. **Do not recalculate base metrics in DAX.** DAX measures below only SUM / AVERAGE the columns that are already in the sheets. If a visual needs a number that isn't in a sheet, stop, add the SQL query, re-export the CSV, and re-import first.

## Rule 2 — single FX parameter
- In Power BI: Modeling → New Parameter → Numeric, name `FX_INR_per_BRL`, value **16.233**.
- Source: exchange-rates.org, 17 Nov 2026 01:40 UTC. Recorded in `docs/DECISIONS.md`.
- Every INR visual = `[Revenue BRL] * FX_INR_per_BRL`, shown in smaller text under the R$ figure. R$ is always first and larger.
- If the rate changes, change the parameter once — every INR figure moves with it.

## Data model
- One table per sheet. No relationships are needed for these 4 pages — each visual reads one table. Do not join the CSVs back together in Power BI; the joins already happened in SQL.
- Tables to import: `02_overall`, `02_delay_buckets`, `02_delay_by_day`, `03_controlled`, `03d_regression`, `05_freight_state`, `05_freight_category`, `06_revenue_seg`, `06_excess`, `06_by_state`, `07_repeat`, `08_attribution`.

## DAX measures (SUM / AVERAGE only)
```
Revenue BRL = SUM('06_revenue_seg'[revenue_brl])
Revenue INR scale = [Revenue BRL] * FX_INR_per_BRL
Excess Bad Reviews = SUM('06_excess'[excess_bad_reviews])   // 3,391
Late Rate = SUM('02_overall'[late_orders]) / SUM('02_overall'[orders])   // 6.79%
```
No other DAX. Do not rebuild delay_days, buckets, or review rates in DAX — they are already in the CSVs.

## Page 1 — Executive summary
- KPI cards (from `02_overall`): Orders 96,203 · Late 6,531 · Late rate 6.79% · Avg review on-time 4.29 · Avg review late 2.27
- KPI cards (from `06_excess`): Excess bad reviews 3,391 · 27.7% of all bad reviews · Revenue associated R$527,125 · INR scale ₹8,556,820 (~₹85.6 lakh, small text)
- Bar chart (from `06_revenue_seg`): Revenue by segment — All R$13,179,778, Late R$985,618, Bad R$1,957,040, Late AND bad R$618,806, Bad not late R$1,338,234. Screenshot: `screenshots/p1_revenue_associated.png`
- Text box, repeat note (from `07_repeat`): "Repeat within 180 days: 1.35% after a late first order [0.98, 1.86] vs 1.86% on-time [1.75, 1.98]. Gap is small, CIs overlap."
- Footer: "Associated with, not lost. Orders were already paid."

## Page 2 — Delivery vs ratings
- Line chart (from `02_delay_by_day`): X = delay_day_clipped (-10 to 20), Y = avg_review. Title: "Steep fall over days 1 to 6, then flat near 1.6–1.7". Screenshot: `screenshots/p2_review_by_day.png`
- Two bar charts (from `02_delay_buckets`): Avg review by bucket, % bad reviews by bucket. Screenshot: `screenshots/p2_buckets.png`
- Footnote the source file name under each visual.

## Page 3 — Drivers
- Bar chart (from `08_attribution`): % of late orders — Logistics only 77.7%, Seller only 12.6%, Both 9.7%. Screenshot: `screenshots/p3_attribution.png`
- Text box under it, verbatim: "Caveat: this split is a heuristic — one day of handover delay is assumed to shift delivery by one day, and it cannot see how the estimate was built."
- Bar chart (from `06_by_state`, top 10 by late_and_bad_revenue_brl): Late-and-bad revenue by state, RJ highlighted. Screenshot: `screenshots/p3_late_bad_by_state.png`
- Text box, verbatim: "RJ: 12,310 orders (12.8% of 96,203) but R$152,004 (24.6%) of late-and-bad revenue; late rate 12.14% vs SP 4.50%."
- Text box, seller gap: "Seller-controlled bad-review gap 54.4 pp rests on 53 sellers (20+ late and 20+ on-time reviewed orders each). Regression with seller fixed effects: +22.5 / +60.8 / +69.0 pp for 1–3 / 4–9 / 10+ days late." Source: `03_controlled`, `03d_regression`.

## Page 4 — Freight burden
- Bar chart (from `05_freight_category`, top 10 by freight_share_of_basket_pct): Freight burden by category. Screenshot: `screenshots/p4_freight_by_category.png`
- Bar chart (from `05_freight_state`, top 10): Freight burden by state. Screenshot: `screenshots/p4_freight_by_state.png`
- Text box: "Freight burden = freight as % of basket. Not profitability — no cost data."

## Export for recruiters
- File → Export to PDF, and export each page as PNG. Save the PNGs in `screenshots/` (already done here from the same CSVs).
- Share the README + screenshots, not the `.pbix` alone — recruiters can't open a `.pbix`.

## Checklist before publishing
- [ ] Every card traces to one `results/` CSV (check the Contents sheet in the Excel file)
- [ ] No visual says "lost" or "profitability"
- [ ] R$ first, INR smaller, FX parameter = 16.233
- [ ] All three caveats are on the slides, not only in the README
- [ ] RJ numbers match `06_by_state.csv` (12,310 orders, 24.56% share, 12.14% late)
