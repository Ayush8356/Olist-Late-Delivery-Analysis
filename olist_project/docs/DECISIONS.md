# DECISIONS.md : every rule behind the numbers

Reproduce: load CSVs (`sql/00_schema.sql`, `sql/00b_load.sql`), `sql/01_base_views.sql`, then `python run_queries.py` and
`python notebooks/03_controlled_regression.py`. MySQL 8.0.46. Every figure below comes from a file in `results/`.

## Population funnel
| Step | Orders |
|---|---|
| All orders | 99,441 |
| status = delivered | 96,478 |
| ... with a delivery date (8 delivered orders have none) | 96,470 |
| ... purchased 2017-01-01 to 2018-08-31 (reliable window) | **96,203** (analysis base, `v_order_base`) |

Dropped: cancelled/unavailable/shipped/etc. (no delivery date, so no delay), 2016 and Sep-Oct 2018 (4 + 325 + 1 + 16 + 4 orders, too sparse).
Every delivered in-window order has items, so the join to items drops nothing.

## Definitions
- **Person** = `customer_unique_id` (96,096 customers; `customer_id` is per order, 99,441).
- **Delay days** = `DATE(delivered) - DATE(estimated)`. Date granularity, because the estimate has no time. Late = delay > 0.
  Buckets: on_time (<=0), 1-3, 4-9, 10+.
- **Bad review** = score <= 2. One review per order: latest `review_answer_timestamp` wins (547 orders have more than one).
  643 in-window orders have no review: kept for revenue and delay, excluded from review rates.
- **Revenue** = `SUM(price)` from `order_items`. Freight is kept separate. Category via translation table, missing = `unknown`.
- **Payments are NOT used for revenue.** Reconciliation: price + freight = R$15,371,741 vs payments R$15,374,497 (0.02% apart;
  241 orders differ by more than R$1, mostly installment interest). A naive payments x items join gives R$19.7M (+28%): the double-count trap.
- **Multi-seller orders** (1,278 in the full data) have `seller_id = NULL` in the base view. They stay in order-level metrics and
  are excluded from seller scorecard and delay attribution. Multi-category orders get `category = 'multiple'`.

## Controlled review gap: minimum group sizes
A stratum (state, category or seller) counts only if it has at least 20 late AND 20 on-time reviewed orders. For sellers that leaves
53 strata. The seller-controlled gap (54.4 pp) rests on fewer orders than the state/category versions, so lean on the joint
regression (`03d_regression.csv`, seller fixed effects absorbed by demeaning, no seller dummies, SE clustered by seller).

## Reconciliation with Ivy's SQLite run (17 Nov 2026)
| Ivy | Mine | Why |
|---|---|---|
| 96,211 base orders, 6,539 late, 2,305 in 10+, late revenue R$986,868 | 96,203, 6,531, 2,297, R$985,618 | Ivy's view is missing `delivered_date IS NOT NULL`. The 8 delivered orders with no delivery date (R$1,249.18 of items) get a NULL delay that falls into the `ELSE '10+'` branch. Fix: add the filter. 985,618.47 + 1,249.18 = 986,867.65. |
| Payments gap R$165,319 (~1%) on price R$13,591,644 + freight R$2,251,910 | 0.02% gap (R$2,756) on the base | Ivy's totals are the WHOLE dataset (all statuses, all years). Mine are the 96,203 base orders. Both correct for their population. |
| Single-seller 98.7%, 643 unreviewed, on-time 89,672 and 4.29 | same | match |

## Delay attribution (query 08), a heuristic
Order-level carrier date vs item-level `shipping_limit_date` (taken as MIN per order), single-seller orders only, day granularity.
`seller_overrun_days = max(0, carrier_date - min_ship_limit)`. For late orders:
logistics_only = handover on time; seller_only = handover delay >= total delay; both = handover late and total delay longer.
Assumes one day of handover delay shifts delivery by one day. It cannot see how the estimate was built, so treat shares as indicative.
Excluded: 13 multi-seller late orders and 1 with no carrier date.

## Repeat buying (query 07)
- All-time: customers with 2+ delivered orders / customers with 1+ delivered order = **3.00%** (2,801 / 93,358).
  This differs from the 96,096 base and 3.12% figure in the spec: that base includes customers with no delivered order, and the
  numerator counts any order. We use delivered orders on both sides.
- Experience test: cohort = first delivered order delivered on or before 2018-03-04 (`DATE(delivered) <= '2018-03-04'`; a 03-05 cutoff gives identical results), so every customer had a full 180 days to return
  before the 2018-09-01 cut-off (no right-censoring). Repeat = later non-cancelled order, purchased after the first was delivered,
  within 180 days. Wilson 95% CIs reported.

## FX (INR) — fixed 17 Nov 2026
`@fx = 16.233` INR per BRL in `sql/06_revenue_associated.sql`, single parameter, used for every INR figure in `results/06_revenue_segments.csv` and `results/06_excess_bad_reviews.csv` (re-exported 17 Nov 2026).
Source: exchange-rates.org, BRL to INR, 1 BRL = 16.233 INR, 17 Nov 2026 at 01:40 UTC (https://www.exchange-rates.org/converter/brl-inr). Cross-check same day: ForexInvestors 16.244 INR, so the dated mid-market rate is ~16.23–16.24, not the undated 15.3–19.1 range cited before. R$ is the primary unit everywhere; INR is scale only, and if the rate moves the INR figures move with it. At 16.233, R$527,125 = ₹8,556,820 (~₹85.6 lakh), not ~₹88 lakh at the old unverified 16.69.

Re-check 17 Nov 2026 after Claude's review: Claude could not open exchange-rates.org and cited early-November sources at ~17.2–17.5 (ECB reference 17.03 on 9 Nov). I opened the exchange-rates.org page directly on 17 Nov at 08:00 UTC: 1 BRL = 16.173 INR. The page shows a 30-day low of 16.32 and a -13.40% move in 30 days, so ~16.2 on 17 Nov is the live rate. Triangulation: USD/INR 93.565 / USD/BRL 5.7842 = 16.18. Keep 16.233 as the pinned 17 Nov rate; do not switch to ~17.3, which is stale early-November.

## Data issues found
- `LOAD DATA` dropped 1 review row until backslash escaping was disabled (`ESCAPED BY ''`). Counts now match the CSVs exactly.
- Review file has 99,224 rows (spec said ~100,000); orders 99,441; items 112,650; payments 103,886.
- Reviews and category-translation CSVs have CRLF line endings: a stray `\r` stuck to every English category name until the loader trimmed it. Counts and metrics were unaffected; labels are now clean.
- `review_id` is not unique (98,410 distinct across 99,224 rows). Geolocation (1,000,163 rows) is loaded but unused.

## Headline numbers (for verification)
| What | Value | File |
|---|---|---|
| Late orders | 6,531 of 96,203 = 6.79% (on-time 93.21%) | 02_overall |
| Avg review, on-time vs late | 4.29 vs 2.27 | 02_overall |
| Bad-review rate by bucket: on-time / 1-3 / 4-9 / 10+ | 9.25% / 32.14% / 70.48% / 79.24% | 02_delay_buckets |
| Shape of the drop | Steep over days 1 to 6 late (avg review 4.03 at 0 days to 1.81 at 6), flat near 1.6 to 1.7 after about day 8 | 02_delay_by_day |
| Bad-review gap late vs on-time, raw / state / category / seller controls | 53.2 / 52.9 / 53.3 / 54.4 pp (seller: 53 sellers with 20+ late and 20+ on-time orders, 2,496 late orders) | 03_controlled_summary |
| Joint regression with seller fixed effects: 1-3 / 4-9 / 10+ days late | +22.5 / +60.8 / +69.0 pp | 03d_regression |
| Revenue: all / late / bad-review / late AND bad | R$13.18M / R$985,618 / R$1.96M / R$618,806 | 06_revenue_segments |
| Revenue of bad-review orders that were NOT late | R$1.34M (10.15% of revenue) | 06_revenue_segments |
| Excess bad reviews associated with lateness | 3,391 = 27.7% of all 12,228 bad reviews | 06_excess_bad_reviews |
| Revenue on those excess bad-review orders | R$527,125 (~₹85.6 lakh at 16.233, 17 Nov 2026) | 06_excess_bad_reviews |
| Late orders by class: logistics_only / seller_only / both | 77.7% / 12.6% / 9.7% | 08_delay_attribution |
| Repeat within 180 days, all cohort | 1.83% (960 of 52,341) | 07_repeat_by_experience |
| Repeat, first order late vs on-time | 1.35% [0.98, 1.86] vs 1.86% [1.75, 1.98] | 07_repeat_by_experience |
| Repeat, first review 1-2 stars vs 4-5 | 1.49% [1.22, 1.82] vs 1.89% [1.77, 2.03] | 07_repeat_by_experience |

## Not done yet
Power BI, README and resume bullets (Muse's part, after verification). ML late-delivery model: optional, only after the core is verified.
