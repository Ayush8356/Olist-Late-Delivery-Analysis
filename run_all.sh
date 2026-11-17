#!/usr/bin/env bash
# Full rebuild. Assumes MySQL 8 running, database `olist` exists, CSVs at the paths in sql/00b_load.sql
set -e
mysql olist < sql/00_schema.sql
mysql --local-infile=1 olist < sql/00b_load.sql
mysql olist < sql/01_base_views.sql
python run_queries.py
python notebooks/03_controlled_regression.py
