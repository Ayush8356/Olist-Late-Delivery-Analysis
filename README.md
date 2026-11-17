# Olist E-commerce — Late Delivery to Revenue Associated

**SQL + Power BI. Base: 96,203 delivered orders, 1 Jan 2017 – 31 Aug 2018, Olist Brazilian E-Commerce.**

> Status 17 Nov 2026, 5:10 pm: real 4-page Power BI dashboard built in Power BI Desktop on Windows. The .pbix file is saved in this project at `powerbi/Olist_Late_Delivery_Dashboard.pbix` (260 KB, verified as a valid .pbix, received 17 Nov 5:18 pm). Real screenshots in `powerbi/screenshots/real_powerbi/` (p1–p4), checked by Ivy against `results/` CSVs on 17 Nov — every number matches. This can now be called "SQL + Power BI".

Question: how much revenue is *associated with* late deliveries and bad reviews, which sellers and states cause it, and does a bad first experience stop people coming back?

Wording rule throughout: **"associated with" — never "lost" or "profitability".** Late orders were already paid, so nothing here is lost revenue. There is no cost data, so no profit is claimed. R$ is primary; INR is scale only.

## Answer in one paragraph

6,531 of 96,203 orders were late (6.79%). On-time orders average 4.29 stars, late orders 2.27. The bad-review rate jumps from 9.25% on-time to 62.42% late. That gap is associated with **3,391 excess bad reviews — 27.7% of all 12,228 bad reviews — and with R$527,125 (~₹85.6 lakh) in item revenue**. About 78% of late orders had on-time seller handover (logistics-only 77.7%, seller-only 12.6%, both 9.7% — the attribution split is a heuristic, see Page 3). Repeat buying barely moves: 1.35% after a late first order vs 1.86% on-time, with overlapping confidence intervals.

## Dashboard — 4 pages

Real Power BI Desktop screenshots in `powerbi/screenshots/real_powerbi/` (p1–p4, 17 Nov 2026, 5:10 pm) — read them + this walkthrough. The 7 matplotlib previews in `powerbi/screenshots/` are now superseded by those real screenshots. The Power BI build spec is in `powerbi/POWER_BI_BUILD_SPEC.md`, and the data is in `powerbi/Olist_PowerBI_Data.xlsx` (every `results/` CSV as a sheet, plus a single FX parameter). The workbook in this folder is now Claude's fixed copy: numbers are numeric (not text), and the INR cells are formulas driven by `Parameters!B2`. Page 1 KPI cards use FORMAT text measures (e.g. `Orders Text = FORMAT(SUM('02_overall'[orders]), "#,##0")`) so Power BI shows exact numbers (96,203, not 96K) — the Display-units setting for the multi-row card did not change the display in this Power BI version, so the text measures are the fix.

### Page 1 — Executive summary
- Late rate **6.79%** (6,531 / 96,203). Source: `results/02_overall.csv`
- Average review **4.29 on-time vs 2.27 late**. Bad-review rate **9.25% vs 62.42%**. Source: `results/02_overall.csv`
- Excess bad reviews **3,391 (27.7% of 12,228)**, revenue associated **R$527,125 (~₹85.6 lakh at 16.233)**. Source: `results/06_excess_bad_reviews.csv`
- Total item revenue **R$13,179,778 (~₹213.9 million)**. Late orders R$985,618 (7.48%), late AND bad R$618,806 (4.70%). Source: `results/06_revenue_segments.csv`
- Repeat buying note: **1.35% after a late first order [0.98, 1.86] vs 1.86% on-time [1.75, 1.98]** within 180 days. The gap is small and the intervals overlap — do not claim late delivery kills repeat buying. Source: `results/07_repeat_by_experience.csv`
- Chart: `powerbi/screenshots/real_powerbi/p1_executive_summary.png` (real Power BI, 17 Nov 2026)

### Page 2 — Delivery vs ratings
- Day-by-day curve: average review falls steeply over days 1 to 6 late (4.03 at 0 days → 1.81 at 6 days), then stays flat near 1.6–1.7. Source: `results/02_delay_by_day.csv`
- Buckets: on-time 89,672 orders avg 4.29, 9.25% bad; 1–3 days 1,869 avg 3.29, 32.14% bad; 4–9 days 2,365 avg 2.00, 70.48% bad; 10+ days 2,297 avg 1.70, 79.24% bad. Source: `results/02_delay_buckets.csv`
- Charts: `powerbi/screenshots/real_powerbi/p2_delivery_vs_ratings.png` (real Power BI, 17 Nov 2026)

### Page 3 — Drivers
- Attribution: **logistics-only 77.7% (5,061 orders), seller-only 12.6% (821), both 9.7% (635)** of 6,517 classified late orders. 14 late orders excluded (13 multi-seller, 1 no carrier date). Source: `results/08_delay_attribution.csv`
- **Caveat on the slide: the attribution split is a heuristic** — it assumes one day of handover delay shifts delivery by one day, and it cannot see how the estimate was built.
- State story, confirmed against `results/06_by_state.csv`: **RJ has 12,310 orders (12.8% of 96,203) but R$152,004 (24.6%) of late-and-bad revenue. Its late rate is 12.14% vs 4.50% for SP.** SP has more late-and-bad revenue in absolute terms (R$159,885, 25.8%) but on 40,399 orders (42.0%) — so RJ is over-represented by ~1.9x, SP is under-represented.
- Seller-controlled gap: **54.4 pp**, but it rests on **53 sellers** with 20+ late and 20+ on-time reviewed orders (2,496 late orders). Lean on the joint regression instead: +22.5 / +60.8 / +69.0 pp for 1–3 / 4–9 / 10+ days late, seller fixed effects absorbed by demeaning, no seller dummies. Source: `results/03_controlled_summary.csv`, `results/03d_regression.csv`
- Charts: `powerbi/screenshots/real_powerbi/p3_drivers.png` (real Power BI, 17 Nov 2026)

### Page 4 — Freight burden
- Freight burden = freight as % of basket (price + freight). Not profitability.
- By category, highest: electronics 22.8%, food_drink 22.7%, furniture_living_room 20.8%. Source: `results/05_freight_by_category.csv`
- By state, highest: MA 20.8%, RO 19.8%, SE 19.5% — remote states carry the highest burden. Source: `results/05_freight_by_state.csv`
- Charts: `powerbi/screenshots/real_powerbi/p4_freight_burden.png` (real Power BI, 17 Nov 2026)

## Caveats (also on the slides, not only here)
1. Seller-controlled gap rests on 53 sellers — see Page 3.
2. Attribution split is a heuristic — see Page 3.
3. Repeat gap is small, with overlapping CIs — see Page 1.

## FX — fixed, dated, single parameter
**1 BRL = 16.233 INR, 17 Nov 2026 at 01:40 UTC, exchange-rates.org** (https://www.exchange-rates.org/converter/brl-inr). Cross-check same day: ForexInvestors 16.244. Recorded in `docs/DECISIONS.md`, set once in `sql/06_revenue_associated.sql` (`SET @fx = 16.233`) and once in Power BI as the `FX_INR_per_BRL` parameter in `powerbi/Olist_PowerBI_Data.xlsx`. At 16.233, R$527,125 is **₹8,556,820 (~₹85.6 lakh, about ₹0.85 crore)**. If the rate moves, the INR figures move with it — R$ does not change.

**FX check 17 Nov 2026 (after Claude's review):** Claude could not open exchange-rates.org and cited early-November sources at ~17.2–17.5. Those were 2–9 Nov — e.g. ECB reference 17.03 on 9 Nov — before the rate fell. I opened the exchange-rates.org page directly on 17 Nov at 08:00 UTC: **1 BRL = 16.173 INR**. The same page shows a 30-day low of 16.32 and a -13.40% move in 30 days, so ~16.2 on 17 Nov is the live rate, not an outlier. Triangulation the same day: USD/INR 93.565 and USD/BRL 5.7842 give 93.565 / 5.7842 = 16.18. So 16.233 (01:40 UTC) and 16.173 (08:00 UTC) agree within 0.4%. Do **not** switch to ~17.3 — that is a stale early-November rate. Keep 16.233 as the pinned 17 Nov rate, R$ primary, INR as "about ₹85 lakh".

## How the numbers were made
- Load the 8 core CSVs, build `v_order_base` in `sql/01_base_views.sql` (delivered orders only, purchase 2017-01-01 to 2018-08-31, one review per order, revenue = SUM(price), freight separate).
- Corrected base: **96,203 orders**. An earlier run gave 96,211 / 6,539 late because 8 delivered orders with no delivery date were stored as empty string, not NULL, in SQLite — fixed by converting empty strings to NULL. Those 8 carry R$1,249.18. See `docs/DECISIONS.md` reconciliation table.
- Run queries 02–08 in `sql/`, outputs in `results/` (21 CSVs). Payments are used only for reconciliation: on the base, price + freight R$15,371,741 vs payments R$15,374,497, gap R$2,755 (0.02%).
- Dashboard built **only from `results/` CSVs** — no DAX recalculation of base metrics. If a visual needs a number that isn't in a CSV, add the query and re-export first.
- Full rules, definitions and reconciliation in `docs/DECISIONS.md`.

## Files
- `sql/` — schema, load, base views, queries 02–08
- `results/` — 21 CSVs, every dashboard number traces to one of these
- `docs/DECISIONS.md` — every rule, definition, and the FX record
- `powerbi/Olist_PowerBI_Data.xlsx` — all results + Parameters sheet
- `powerbi/POWER_BI_BUILD_SPEC.md` — step-by-step Power BI Desktop build
- `powerbi/screenshots/real_powerbi/` — 4 real Power BI Desktop screenshots, one per page (17 Nov 2026, verified against `results/`)
- `powerbi/dashboard.html` — the 4 pages as a readable preview

## ML layer — held
Held until the dashboard and README are done. The core already answers the question. If the 2-week box is tight, skip it.

## Resume bullets (draft, from these numbers only)
- Built a SQL + Power BI analysis of 96,203 Olist orders (2017–2018) linking late delivery to review scores: late orders averaged 2.27 vs 4.29 on-time, with 3,391 excess bad reviews associated with R$527,125 in item revenue.
- Showed most lateness was logistics-driven (77.7%) not seller-driven, and that Rio de Janeiro — 12.8% of orders — accounted for 24.6% of late-and-bad revenue.
