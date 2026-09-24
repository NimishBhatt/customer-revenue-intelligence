from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


# --------------------------------------------------
# 1. FIND PROJECT FOLDERS
# --------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSED_DATA_DIR = PROJECT_ROOT / "data" / "processed"
IMAGES_DIR = PROJECT_ROOT / "images"

IMAGES_DIR.mkdir(parents=True, exist_ok=True)


# --------------------------------------------------
# 2. LOAD COHORT DATA
# --------------------------------------------------

input_path = PROCESSED_DATA_DIR / "cohort_retention.csv"

if not input_path.exists():
    raise FileNotFoundError(
        "cohort_retention.csv was not found. "
        "Run 02_extract_analysis_data.py first."
    )

cohorts = pd.read_csv(input_path)

required_columns = {
    "cohort_month",
    "cohort_index",
    "cohort_size",
    "active_customers",
    "retention_rate_pct",
}

missing_columns = required_columns.difference(cohorts.columns)

if missing_columns:
    missing = ", ".join(sorted(missing_columns))
    raise ValueError(f"Missing required columns: {missing}")


# --------------------------------------------------
# 3. CLEAN AND FILTER DATA
# --------------------------------------------------

cohorts["cohort_month"] = pd.to_datetime(
    cohorts["cohort_month"]
)

cohorts["cohort_label"] = (
    cohorts["cohort_month"].dt.strftime("%Y-%m")
)

# Remove tiny cohorts because their percentages are unstable.
# Month 0 is excluded because it is always 100%.
heatmap_data = cohorts[
    (cohorts["cohort_size"] >= 100)
    & (cohorts["cohort_index"].between(1, 12))
].copy()


# --------------------------------------------------
# 4. CREATE RETENTION MATRIX
# --------------------------------------------------

retention_matrix = heatmap_data.pivot(
    index="cohort_label",
    columns="cohort_index",
    values="retention_rate_pct",
)

retention_matrix = retention_matrix.reindex(
    columns=range(1, 13)
)

retention_matrix.index.name = "cohort_month"

matrix_output_path = (
    PROCESSED_DATA_DIR / "cohort_retention_matrix.csv"
)

retention_matrix.to_csv(matrix_output_path)

print("\n--------------------------------")
print("COHORT RETENTION MATRIX")
print("--------------------------------\n")

print(retention_matrix.round(2).to_string())

print(
    f"\nSaved: "
    f"{matrix_output_path.relative_to(PROJECT_ROOT)}"
)


# --------------------------------------------------
# 5. CREATE RETENTION HEATMAP
# --------------------------------------------------

matrix_values = retention_matrix.to_numpy(
    dtype=float
)

masked_values = np.ma.masked_invalid(matrix_values)

maximum_retention = np.nanmax(matrix_values)

colour_map = plt.colormaps["YlGnBu"].copy()
colour_map.set_bad("#F2F2F2")

figure, axis = plt.subplots(figsize=(16, 10))

heatmap = axis.imshow(
    masked_values,
    aspect="auto",
    cmap=colour_map,
    vmin=0,
    vmax=maximum_retention,
)

axis.set_title(
    "Customer Cohort Retention — Months After Acquisition",
    fontsize=17,
    fontweight="bold",
    pad=18,
)

axis.set_xlabel("Months after first purchase")
axis.set_ylabel("Acquisition cohort")

axis.set_xticks(range(12))
axis.set_xticklabels(
    [f"M{month}" for month in range(1, 13)]
)

axis.set_yticks(range(len(retention_matrix.index)))
axis.set_yticklabels(retention_matrix.index)

for row_index in range(matrix_values.shape[0]):
    for column_index in range(matrix_values.shape[1]):

        value = matrix_values[row_index, column_index]

        if np.isnan(value):
            continue

        text_colour = (
            "white"
            if value > maximum_retention * 0.60
            else "black"
        )

        axis.text(
            column_index,
            row_index,
            f"{value:.2f}%",
            ha="center",
            va="center",
            fontsize=8,
            color=text_colour,
        )

colour_bar = figure.colorbar(
    heatmap,
    ax=axis,
    pad=0.02,
)

colour_bar.set_label("Retention rate (%)")

figure.tight_layout()

chart_path = IMAGES_DIR / "cohort_retention_heatmap.png"

figure.savefig(
    chart_path,
    dpi=200,
    bbox_inches="tight",
)

plt.close(figure)

print(f"Saved: {chart_path.relative_to(PROJECT_ROOT)}")


# --------------------------------------------------
# 6. PRINT KEY FINDINGS
# --------------------------------------------------

month_one = cohorts[
    (cohorts["cohort_index"] == 1)
    & (cohorts["cohort_size"] >= 100)
].copy()

weighted_month_one_retention = (
    100
    * month_one["active_customers"].sum()
    / month_one["cohort_size"].sum()
)

best_month_one_cohort = month_one.loc[
    month_one["retention_rate_pct"].idxmax()
]

print("\n--------------------------------")
print("KEY FINDINGS")
print("--------------------------------")

print(
    "Weighted month-one retention: "
    f"{weighted_month_one_retention:.2f}%"
)

print(
    "Best month-one cohort: "
    f"{best_month_one_cohort['cohort_month']:%Y-%m} "
    f"({best_month_one_cohort['retention_rate_pct']:.2f}%)"
)