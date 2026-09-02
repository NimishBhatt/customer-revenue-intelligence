# Customer & Revenue Intelligence — Business Findings

## Revenue Performance

### Core KPIs

Analysis of delivered orders identified:

- Delivered Orders: 96,478
- Product Revenue: R$13,221,498.11
- Freight Charges: R$2,198,275.64
- Product + Freight Value: R$15,419,773.75
- Average Order Value (AOV): R$137.04

Product revenue is defined as the sum of item prices associated with
delivered orders. Freight charges are tracked separately.

### Revenue Trends

November 2017 generated the highest delivered product revenue in the
dataset at R$987,765.37 from 7,289 delivered orders.

Eight of the ten highest-revenue months occurred during 2018, suggesting
that the marketplace was operating at a substantially higher revenue
level during the later period of the dataset.

Revenue performance is influenced by both order volume and order value.
High order volume does not necessarily correspond directly to the
highest revenue month.

Further analysis is required to determine the drivers of revenue growth,
including customer behavior, average order value, product mix, geography,
and repeat purchasing.

## Customer Retention & Repeat Purchasing

### Customer Purchase Behavior

Among 93,358 customers with delivered orders:

- 90,557 customers (97.00%) made only one purchase.
- 2,801 customers (3.00%) made more than one purchase.

This indicates that observed purchasing behavior is heavily dominated by
one-time customers, making repeat purchasing a potential area for further
business investigation.

### Revenue Contribution

One-time customers generated R$12,493,089.36, representing 94.49% of
delivered product revenue.

Repeat customers generated R$728,408.75, representing 5.51% of delivered
product revenue.

Although repeat customers represent only 3.00% of customers, they account
for 5.51% of product revenue.

Average observed product revenue per customer was approximately:

- One-time customers: R$137.96
- Repeat customers: R$260.05

Repeat customers therefore generated approximately 1.88x the observed
product revenue per customer compared with one-time customers.

These findings suggest that customer retention and repeat purchasing
represent important areas for further analysis. However, the 3% repeat
purchase rate should be interpreted within the available observation
period rather than as a lifetime customer retention rate.

### Customer Value & Purchase Frequency

The top 10% of customers generated R$5,434,024.58 in delivered product
revenue, representing 41.10% of total product revenue. This indicates
meaningful revenue concentration among the highest-value customers.

Purchase frequency declines sharply after the first purchase:

- 90,557 customers placed 1 delivered order.
- 2,573 customers placed 2 delivered orders.
- 181 customers placed 3 delivered orders.
- Only 47 customers placed 4 or more delivered orders.

Of the 2,801 repeat customers, approximately 91.86% placed exactly two
orders. Only 228 customers placed three or more delivered orders,
representing approximately 0.24% of the observed customer base.

This suggests that the retention challenge extends beyond converting
first-time buyers into second-time buyers; sustained repeat purchasing
is particularly uncommon within the available observation period.

### Repurchase Timing

Across 3,120 observed repeat-purchase intervals:

- Average time between purchases: 79.15 days
- Median time between purchases: 29.46 days

The substantial difference between the mean and median indicates a
right-skewed repurchase-time distribution, with some customers returning
after much longer periods.

The median suggests that approximately half of observed repeat purchases
occurred within roughly 30 days of the previous purchase. This makes the
first 30 days after purchase a potentially useful period to investigate
for retention and re-engagement activity.

### High-Value Customer Behavior

High customer value does not necessarily imply high purchase frequency.

The highest-revenue customer generated R$13,440 from a single delivered
order, while other high-value customers accumulated revenue across
multiple purchases.

Customer value should therefore be evaluated across multiple dimensions
rather than product revenue alone. Recency, Frequency, and Monetary
value will be analyzed together using RFM segmentation.

## RFM Customer Segmentation

Customers were segmented using Recency, Frequency, and Monetary (RFM)
analysis based on delivered orders.

### Recency

Recency measures the number of days since the customer's latest delivered
purchase relative to the end of the dataset observation period.

Recency quartiles were:

- R4: <= 115 days
- R3: 116-219 days
- R2: 220-347 days
- R1: > 347 days

Lower recency indicates more recent purchasing activity.

### Frequency

Frequency measures the number of delivered orders placed by each customer.

Because 97% of customers placed only one delivered order, conventional
frequency quintiles would artificially assign different scores to customers
with identical purchase behavior.

Behavior-based frequency scoring was therefore used:

- F1: 1 order
- F2: 2 orders
- F3: 3 orders
- F4: 4+ orders

### Monetary

Monetary value represents total delivered product revenue associated with
each customer.

Monetary quartiles were:

- M1: <= R$47.65
- M2: R$47.66-R$89.73
- M3: R$89.74-R$154.74
- M4: > R$154.74

### Customer Segments

The resulting model separates customers into six actionable groups:

- Champions — recent repeat customers with above-median value.
- Active Repeat — other recent customers demonstrating repeat purchasing.
- High-Value Recent — recent, high-value customers with one observed order.
- Recent One-Time — other relatively recent customers with one observed order.
- At-Risk Valuable — older customers with repeat history or above-median value.
- Inactive Low-Value — older, lower-value one-time customers.

The segmentation was adapted to the observed purchase-frequency distribution
rather than applying generic RFM segment definitions.

