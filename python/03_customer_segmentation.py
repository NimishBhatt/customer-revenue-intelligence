from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


# --------------------------------------------------
# 1. FIND PROJECT FOLDERS
# --------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSED_DATA_DIR = PROJECT_ROOT / "data" / "processed"
IMAGES_DIR = PROJECT_ROOT / "images"

IMAGES_DIR.mkdir(parents=True, exist_ok=True)


# --------------------------------------------------
# 2. LOAD CUSTOMER RFM DATA
# --------------------------------------------------

input_path = PROCESSED_DATA_DIR / "customer_rfm.csv"

if not input_path.exists():
    raise FileNotFoundError(
        "customer_rfm.csv was not found. "
        "Run 02_extract_analysis_data.py first."
    )

customers = pd.read_csv(input_path)

required_columns = {
    "customer_unique_id",
    "customer_segment",
    "recency_days",
    "frequency",
    "monetary_value",
}

missing_columns = required_columns.difference(customers.columns)

if missing_columns:
    missing = ", ".join(sorted(missing_columns))
    raise ValueError(f"Missing required columns: {missing}")


# --------------------------------------------------
# 3. CREATE CUSTOMER SEGMENT SUMMARY
# --------------------------------------------------

segment_summary = (
    customers
    .groupby("customer_segment", as_index=False)
    .agg(
        customers=("customer_unique_id", "nunique"),
        product_revenue=("monetary_value", "sum"),
        average_customer_value=("monetary_value", "mean"),
        average_recency_days=("recency_days", "mean"),
        average_frequency=("frequency", "mean"),
    )
)

total_customers = segment_summary["customers"].sum()
total_revenue = segment_summary["product_revenue"].sum()

segment_summary["customer_share_pct"] = (
    100 * segment_summary["customers"] / total_customers
)

segment_summary["revenue_share_pct"] = (
    100 * segment_summary["product_revenue"] / total_revenue
)

segment_summary = segment_summary[
    [
        "customer_segment",
        "customers",
        "customer_share_pct",
        "product_revenue",
        "revenue_share_pct",
        "average_customer_value",
        "average_recency_days",
        "average_frequency",
    ]
].sort_values(
    "product_revenue",
    ascending=False,
)

numeric_columns = [
    "customer_share_pct",
    "product_revenue",
    "revenue_share_pct",
    "average_customer_value",
    "average_recency_days",
    "average_frequency",
]

segment_summary[numeric_columns] = (
    segment_summary[numeric_columns].round(2)
)


# --------------------------------------------------
# 4. SAVE SUMMARY
# --------------------------------------------------

output_path = (
    PROCESSED_DATA_DIR / "customer_segment_summary.csv"
)

segment_summary.to_csv(output_path, index=False)

print("\n--------------------------------")
print("CUSTOMER SEGMENT SUMMARY")
print("--------------------------------\n")

print(segment_summary.to_string(index=False))

print(f"\nSaved: {output_path.relative_to(PROJECT_ROOT)}")


# --------------------------------------------------
# 5. CREATE VISUALIZATION
# --------------------------------------------------

plot_data = segment_summary.sort_values(
    "product_revenue",
    ascending=True,
)

figure, axes = plt.subplots(
    1,
    2,
    figsize=(16, 7),
)

axes[0].barh(
    plot_data["customer_segment"],
    plot_data["customer_share_pct"],
    color="#4C78A8",
)

axes[0].set_title("Customer Distribution by Segment")
axes[0].set_xlabel("Share of customers (%)")
axes[0].set_ylabel("")

for index, value in enumerate(
    plot_data["customer_share_pct"]
):
    axes[0].text(
        value + 0.3,
        index,
        f"{value:.1f}%",
        va="center",
    )

axes[1].barh(
    plot_data["customer_segment"],
    plot_data["revenue_share_pct"],
    color="#F28E2B",
)

axes[1].set_title("Revenue Contribution by Segment")
axes[1].set_xlabel("Share of product revenue (%)")
axes[1].set_ylabel("")

for index, value in enumerate(
    plot_data["revenue_share_pct"]
):
    axes[1].text(
        value + 0.3,
        index,
        f"{value:.1f}%",
        va="center",
    )

figure.suptitle(
    "Customer Segmentation Analysis",
    fontsize=18,
    fontweight="bold",
)

figure.tight_layout(rect=(0, 0, 1, 0.95))

chart_path = IMAGES_DIR / "customer_segmentation_analysis.png"

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

highest_revenue_segment = segment_summary.iloc[0]

largest_segment = segment_summary.sort_values(
    "customers",
    ascending=False,
).iloc[0]

print("\n--------------------------------")
print("KEY FINDINGS")
print("--------------------------------")

print(
    "Highest-revenue segment: "
    f"{highest_revenue_segment['customer_segment']} "
    f"({highest_revenue_segment['revenue_share_pct']:.2f}% "
    "of revenue)"
)

print(
    "Largest customer segment: "
    f"{largest_segment['customer_segment']} "
    f"({largest_segment['customer_share_pct']:.2f}% "
    "of customers)"
)