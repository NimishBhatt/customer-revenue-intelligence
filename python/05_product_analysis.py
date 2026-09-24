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
# 2. LOAD PRODUCT DATA
# --------------------------------------------------

category_path = (
    PROCESSED_DATA_DIR / "product_category_performance.csv"
)

abc_path = (
    PROCESSED_DATA_DIR / "product_abc_analysis.csv"
)

priority_path = (
    PROCESSED_DATA_DIR / "category_business_priorities.csv"
)

for file_path in [category_path, abc_path, priority_path]:
    if not file_path.exists():
        raise FileNotFoundError(
            f"{file_path.name} was not found. "
            "Run 02_extract_analysis_data.py first."
        )

categories = pd.read_csv(category_path)
abc_analysis = pd.read_csv(abc_path)
priorities = pd.read_csv(priority_path)


# --------------------------------------------------
# 3. VALIDATE REQUIRED COLUMNS
# --------------------------------------------------

category_columns = {
    "product_category",
    "total_orders",
    "units_sold",
    "product_revenue",
    "freight_to_revenue_pct",
}

abc_columns = {
    "abc_class",
    "number_of_products",
    "class_revenue",
    "revenue_share_pct",
}

priority_columns = {
    "revenue_rank",
    "product_category",
    "total_orders",
    "product_revenue",
    "average_review_score",
    "negative_review_pct",
    "business_priority",
}

checks = [
    ("category data", categories, category_columns),
    ("ABC data", abc_analysis, abc_columns),
    ("priority data", priorities, priority_columns),
]

for name, dataframe, required_columns in checks:

    missing_columns = required_columns.difference(
        dataframe.columns
    )

    if missing_columns:
        missing = ", ".join(sorted(missing_columns))
        raise ValueError(
            f"Missing columns in {name}: {missing}"
        )


# --------------------------------------------------
# 4. CREATE ANALYSIS TABLES
# --------------------------------------------------

top_categories = (
    categories
    .nlargest(10, "product_revenue")
    .copy()
)

top_categories["category_label"] = (
    top_categories["product_category"]
    .str.replace("_", " ", regex=False)
    .str.title()
)

actionable_priorities = priorities[
    priorities["business_priority"] != "Monitor"
].copy()

top_categories.to_csv(
    PROCESSED_DATA_DIR / "top_10_product_categories.csv",
    index=False,
)

actionable_priorities.to_csv(
    PROCESSED_DATA_DIR / "category_action_priorities.csv",
    index=False,
)


# --------------------------------------------------
# 5. TOP CATEGORIES AND ABC VISUALIZATION
# --------------------------------------------------

plot_categories = top_categories.sort_values(
    "product_revenue",
    ascending=True,
)

figure, axes = plt.subplots(
    1,
    2,
    figsize=(17, 7),
)

revenue_millions = (
    plot_categories["product_revenue"] / 1_000_000
)

axes[0].barh(
    plot_categories["category_label"],
    revenue_millions,
    color="#4C78A8",
)

axes[0].set_title("Top 10 Categories by Product Revenue")
axes[0].set_xlabel("Product revenue (BRL millions)")
axes[0].set_ylabel("")

for index, value in enumerate(revenue_millions):
    axes[0].text(
        value + 0.01,
        index,
        f"R$ {value:.2f}M",
        va="center",
        fontsize=9,
    )

abc_colours = [
    "#2E86AB",
    "#F6C85F",
    "#D1495B",
]

axes[1].pie(
    abc_analysis["revenue_share_pct"],
    labels=abc_analysis["abc_class"],
    autopct="%1.1f%%",
    startangle=90,
    colors=abc_colours,
)

axes[1].set_title("Revenue Concentration by ABC Class")

figure.suptitle(
    "Product Portfolio Analysis",
    fontsize=18,
    fontweight="bold",
)

figure.tight_layout(rect=(0, 0, 1, 0.94))

portfolio_chart_path = (
    IMAGES_DIR / "product_category_analysis.png"
)

figure.savefig(
    portfolio_chart_path,
    dpi=200,
    bbox_inches="tight",
)

plt.close(figure)


# --------------------------------------------------
# 6. CATEGORY PRIORITY MATRIX
# --------------------------------------------------

priority_colours = {
    "Critical: High revenue / lower satisfaction":
        "#D1495B",
    "Protect: High revenue / strong satisfaction":
        "#2E86AB",
    "Improve customer experience":
        "#F28E2B",
    "Review logistics costs":
        "#59A14F",
    "Monitor":
        "#BDBDBD",
}

figure, axis = plt.subplots(figsize=(14, 8))

maximum_orders = priorities["total_orders"].max()

for priority_name, group in priorities.groupby(
    "business_priority"
):

    bubble_sizes = (
        40
        + 700
        * np.sqrt(group["total_orders"] / maximum_orders)
    )

    axis.scatter(
        group["average_review_score"],
        group["product_revenue"] / 1_000_000,
        s=bubble_sizes,
        alpha=0.70,
        color=priority_colours.get(
            priority_name,
            "#BDBDBD",
        ),
        label=priority_name,
        edgecolor="white",
        linewidth=0.5,
    )

label_categories = priorities.nsmallest(
    10,
    "revenue_rank",
)

for _, row in label_categories.iterrows():

    label = (
        row["product_category"]
        .replace("_", " ")
        .title()
    )

    axis.annotate(
        label,
        (
            row["average_review_score"],
            row["product_revenue"] / 1_000_000,
        ),
        xytext=(5, 5),
        textcoords="offset points",
        fontsize=8,
    )

axis.axvline(
    4.10,
    color="#666666",
    linestyle="--",
    linewidth=1,
    label="Review benchmark: 4.10",
)

axis.set_title(
    "Category Revenue and Customer Satisfaction Priorities",
    fontsize=16,
    fontweight="bold",
)

axis.set_xlabel("Average review score")
axis.set_ylabel("Product revenue (BRL millions)")

axis.legend(
    loc="upper left",
    bbox_to_anchor=(1.02, 1),
)

axis.grid(
    alpha=0.20,
    linestyle="--",
)

figure.tight_layout()

priority_chart_path = (
    IMAGES_DIR / "category_priority_matrix.png"
)

figure.savefig(
    priority_chart_path,
    dpi=200,
    bbox_inches="tight",
)

plt.close(figure)


# --------------------------------------------------
# 7. PRINT KEY FINDINGS
# --------------------------------------------------

top_category = categories.loc[
    categories["product_revenue"].idxmax()
]

established_categories = priorities[
    priorities["reviewed_orders"] >= 100
]

lowest_satisfaction = established_categories.loc[
    established_categories[
        "average_review_score"
    ].idxmin()
]

highest_freight = categories[
    categories["total_orders"] >= 100
].loc[
    categories[
        categories["total_orders"] >= 100
    ]["freight_to_revenue_pct"].idxmax()
]

abc_a = abc_analysis[
    abc_analysis["abc_class"].str.startswith("A")
].iloc[0]

print("\n--------------------------------")
print("PRODUCT ANALYSIS COMPLETE")
print("--------------------------------")

print(
    "Top revenue category: "
    f"{top_category['product_category']} "
    f"(R$ {top_category['product_revenue']:,.2f})"
)

print(
    "Lowest-rated established category: "
    f"{lowest_satisfaction['product_category']} "
    f"({lowest_satisfaction['average_review_score']:.2f})"
)

print(
    "Highest freight burden among established categories: "
    f"{highest_freight['product_category']} "
    f"({highest_freight['freight_to_revenue_pct']:.2f}%)"
)

print(
    "ABC Class A: "
    f"{int(abc_a['number_of_products']):,} products generate "
    f"{abc_a['revenue_share_pct']:.2f}% of revenue"
)

print(
    f"\nSaved: "
    f"{portfolio_chart_path.relative_to(PROJECT_ROOT)}"
)

print(
    f"Saved: "
    f"{priority_chart_path.relative_to(PROJECT_ROOT)}"
)