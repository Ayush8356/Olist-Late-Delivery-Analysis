# %% [markdown]
# # 03 - Late delivery vs bad reviews with joint controls
# Linear probability model: P(bad review) ~ delay bucket + category + customer state + freight ratio + seller fixed effects.
# Seller FE are absorbed by within-seller demeaning; SE clustered by seller. Single-seller reviewed orders only.
# Association, not causation. Run after sql/01_base_views.sql: `python notebooks/03_controlled_regression.py`

# %%
import numpy as np, pandas as pd, statsmodels.api as sm, mysql.connector
cn = mysql.connector.connect(user="root", host="127.0.0.1", database="olist", unix_socket="/var/run/mysqld/mysqld.sock")
df = pd.read_sql("""SELECT order_id, seller_id, category, customer_state, delay_bucket,
                           is_bad_review AS bad, freight/item_revenue AS freight_ratio
                    FROM v_order_base WHERE seller_id IS NOT NULL AND review_score IS NOT NULL AND item_revenue > 0""", cn)
df["bad"] = df["bad"].astype(float)
print(len(df), "orders,", df.seller_id.nunique(), "sellers")

# %%
X = pd.get_dummies(df[["delay_bucket", "category", "customer_state"]], drop_first=False).astype(float)
X = X.drop(columns=["delay_bucket_on_time", "category_multiple", "customer_state_SP"])   # reference levels
X["freight_ratio"] = df["freight_ratio"].clip(upper=df["freight_ratio"].quantile(0.99))
y = df["bad"]

def fit(Xm, ym, groups, demean_by=None):
    if demean_by is not None:                      # absorb seller fixed effects
        Xm = Xm - Xm.groupby(demean_by).transform("mean"); ym = ym - ym.groupby(demean_by).transform("mean")
    return sm.OLS(ym, Xm, missing="drop").fit(cov_type="cluster", cov_kwds={"groups": groups})

bk = [c for c in X.columns if c.startswith("delay_bucket_")]
raw  = fit(sm.add_constant(df[["bad"]].assign(**{c: X[c] for c in bk}).drop(columns="bad")), y, df.seller_id)
ctrl = fit(sm.add_constant(X), y, df.seller_id)
fe   = fit(X, y, df.seller_id, demean_by=df.seller_id)

# %%
rows = []
for name, m in [("raw (bucket only)", raw), ("+ category, state, freight", ctrl), ("+ seller fixed effects", fe)]:
    for b in bk:
        lo, hi = m.conf_int().loc[b]
        rows.append({"model": name, "delay_bucket": b.replace("delay_bucket_", ""),
                     "bad_review_gap_pp": round(100 * m.params[b], 2), "ci95_low_pp": round(100 * lo, 2), "ci95_high_pp": round(100 * hi, 2)})
out = pd.DataFrame(rows); out.to_csv("results/03d_regression.csv", index=False); print(out.to_string(index=False))
