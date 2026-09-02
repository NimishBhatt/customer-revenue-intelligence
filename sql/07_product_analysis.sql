-- ============================================================
-- CUSTOMER & REVENUE INTELLIGENCE PLATFORM
-- PRODUCT ANALYSIS
-- ============================================================
-- Purpose:
-- Analyse product and category performance using delivered
-- orders, unit sales, revenue, pricing and freight costs.
--
-- Revenue definition:
-- Product revenue = SUM(order_items.price)
-- Freight is reported separately and is not included in revenue.
-- ============================================================


-- ------------------------------------------------------------
-- 1. PRODUCT CATEGORY PERFORMANCE
-- Purpose:
-- Compare product categories by products, orders, units sold,
-- customers, product revenue and freight value.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_product_category_performance AS

SELECT
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Uncategorised'
    ) AS product_category,

    COUNT(DISTINCT p.product_id) AS distinct_products,

    COUNT(DISTINCT oi.order_id) AS total_orders,

    COUNT(*) AS units_sold,

    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,

    ROUND(
        SUM(oi.price)::numeric,
        2
    ) AS product_revenue,

    ROUND(
        AVG(oi.price)::numeric,
        2
    ) AS average_unit_price,

    ROUND(
        SUM(oi.freight_value)::numeric,
        2
    ) AS total_freight_value,

    ROUND(
        (
            100.0 * SUM(oi.freight_value)
            / NULLIF(SUM(oi.price), 0)
        )::numeric,
        2
    ) AS freight_to_revenue_pct

FROM order_items AS oi

INNER JOIN orders AS o
    ON oi.order_id = o.order_id

INNER JOIN products AS p
    ON oi.product_id = p.product_id

INNER JOIN customers AS c
    ON o.customer_id = c.customer_id

LEFT JOIN category_translation AS pct
    ON p.product_category_name = pct.product_category_name

WHERE o.order_status = 'delivered'

GROUP BY
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Uncategorised'
    )

ORDER BY product_revenue DESC;

-- ------------------------------------------------------------
-- 2. TOP PRODUCTS BY REVENUE
-- Purpose:
-- Identify the individual products generating the most revenue,
-- together with their sales volume, customers and freight costs.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_top_products AS

SELECT
    oi.product_id,

    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Uncategorised'
    ) AS product_category,

    COUNT(DISTINCT oi.order_id) AS total_orders,

    COUNT(*) AS units_sold,

    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,

    ROUND(
        SUM(oi.price)::numeric,
        2
    ) AS product_revenue,

    ROUND(
        AVG(oi.price)::numeric,
        2
    ) AS average_unit_price,

    ROUND(
        SUM(oi.freight_value)::numeric,
        2
    ) AS total_freight_value,

    ROUND(
        (
            100.0 * SUM(oi.freight_value)
            / NULLIF(SUM(oi.price), 0)
        )::numeric,
        2
    ) AS freight_to_revenue_pct

FROM order_items AS oi

INNER JOIN orders AS o
    ON oi.order_id = o.order_id

INNER JOIN products AS p
    ON oi.product_id = p.product_id

INNER JOIN customers AS c
    ON o.customer_id = c.customer_id

LEFT JOIN category_translation AS pct
    ON p.product_category_name = pct.product_category_name

WHERE o.order_status = 'delivered'

GROUP BY
    oi.product_id,
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Uncategorised'
    )

ORDER BY product_revenue DESC

LIMIT 20;

-- ------------------------------------------------------------
-- 3. PRODUCT REVENUE CONCENTRATION — ABC ANALYSIS
-- Purpose:
-- Classify products according to their cumulative contribution
-- to total product revenue.
--
-- A = first 80% of cumulative revenue
-- B = next 15% of cumulative revenue
-- C = final 5% of cumulative revenue
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_product_abc_analysis AS

WITH product_revenue AS (

    SELECT
        oi.product_id,

        SUM(oi.price)::numeric AS product_revenue

    FROM order_items AS oi

    INNER JOIN orders AS o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY oi.product_id
),

ranked_products AS (

    SELECT
        product_id,
        product_revenue,

        SUM(product_revenue) OVER (
            ORDER BY product_revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue,

        SUM(product_revenue) OVER () AS total_revenue

    FROM product_revenue
),

classified_products AS (

    SELECT
        product_id,
        product_revenue,

        ROUND(
            (
                100.0 * cumulative_revenue
                / NULLIF(total_revenue, 0)
            )::numeric,
            2
        ) AS cumulative_revenue_pct,

        CASE
            WHEN 100.0 * cumulative_revenue
                 / NULLIF(total_revenue, 0) <= 80
                THEN 'A - High Value'

            WHEN 100.0 * cumulative_revenue
                 / NULLIF(total_revenue, 0) <= 95
                THEN 'B - Medium Value'

            ELSE 'C - Low Value'
        END AS abc_class

    FROM ranked_products
)

SELECT
    abc_class,

    COUNT(*) AS number_of_products,

    ROUND(
        SUM(product_revenue)::numeric,
        2
    ) AS class_revenue,

    ROUND(
        (
            100.0 * SUM(product_revenue)
            / SUM(SUM(product_revenue)) OVER ()
        )::numeric,
        2
    ) AS revenue_share_pct,

    ROUND(
        AVG(product_revenue)::numeric,
        2
    ) AS average_revenue_per_product

FROM classified_products

GROUP BY abc_class

ORDER BY
    CASE abc_class
        WHEN 'A - High Value' THEN 1
        WHEN 'B - Medium Value' THEN 2
        WHEN 'C - Low Value' THEN 3
    END;

-- ------------------------------------------------------------
-- 4. CUSTOMER SATISFACTION BY PRODUCT CATEGORY
-- Purpose:
-- Compare categories using average review scores and the
-- percentage of positive and negative customer reviews.
--
-- Positive review = score of 4 or 5
-- Negative review = score of 1 or 2
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_category_satisfaction AS

WITH order_review_scores AS (

    SELECT
        order_id,

        AVG(review_score)::numeric AS average_review_score

    FROM reviews

    GROUP BY order_id
),

order_categories AS (

    SELECT DISTINCT
        oi.order_id,

        COALESCE(
            pct.product_category_name_english,
            p.product_category_name,
            'Uncategorised'
        ) AS product_category

    FROM order_items AS oi

    INNER JOIN products AS p
        ON oi.product_id = p.product_id

    LEFT JOIN category_translation AS pct
        ON p.product_category_name = pct.product_category_name
)

SELECT
    oc.product_category,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(ors.average_review_score)::numeric,
        2
    ) AS average_review_score,

    ROUND(
        (
            100.0 * COUNT(*) FILTER (
                WHERE ors.average_review_score >= 4
            ) / COUNT(*)
        )::numeric,
        2
    ) AS positive_review_pct,

    ROUND(
        (
            100.0 * COUNT(*) FILTER (
                WHERE ors.average_review_score <= 2
            ) / COUNT(*)
        )::numeric,
        2
    ) AS negative_review_pct

FROM order_categories AS oc

INNER JOIN order_review_scores AS ors
    ON oc.order_id = ors.order_id

GROUP BY oc.product_category

HAVING COUNT(*) >= 100

ORDER BY average_review_score DESC;

-- ------------------------------------------------------------
-- 5. CATEGORY BUSINESS PRIORITIES
-- Purpose:
-- Combine revenue, freight and customer satisfaction to identify
-- high-value categories that require protection or improvement.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_category_business_priorities AS

WITH category_sales AS (

    SELECT
        COALESCE(
            pct.product_category_name_english,
            p.product_category_name,
            'Uncategorised'
        ) AS product_category,

        COUNT(DISTINCT oi.order_id) AS total_orders,

        SUM(oi.price)::numeric AS product_revenue,

        (
            100.0 * SUM(oi.freight_value)
            / NULLIF(SUM(oi.price), 0)
        )::numeric AS freight_to_revenue_pct

    FROM order_items AS oi

    INNER JOIN orders AS o
        ON oi.order_id = o.order_id

    INNER JOIN products AS p
        ON oi.product_id = p.product_id

    LEFT JOIN category_translation AS pct
        ON p.product_category_name = pct.product_category_name

    WHERE o.order_status = 'delivered'

    GROUP BY
        COALESCE(
            pct.product_category_name_english,
            p.product_category_name,
            'Uncategorised'
        )
),

order_review_scores AS (

    SELECT
        order_id,
        AVG(review_score)::numeric AS average_review_score

    FROM reviews

    GROUP BY order_id
),

order_categories AS (

    SELECT DISTINCT
        oi.order_id,

        COALESCE(
            pct.product_category_name_english,
            p.product_category_name,
            'Uncategorised'
        ) AS product_category

    FROM order_items AS oi

    INNER JOIN products AS p
        ON oi.product_id = p.product_id

    LEFT JOIN category_translation AS pct
        ON p.product_category_name = pct.product_category_name
),

category_reviews AS (

    SELECT
        oc.product_category,

        COUNT(*) AS reviewed_orders,

        AVG(ors.average_review_score)::numeric
            AS average_review_score,

        (
            100.0 * COUNT(*) FILTER (
                WHERE ors.average_review_score <= 2
            ) / COUNT(*)
        )::numeric AS negative_review_pct

    FROM order_categories AS oc

    INNER JOIN order_review_scores AS ors
        ON oc.order_id = ors.order_id

    GROUP BY oc.product_category
),

combined_categories AS (

    SELECT
        cs.product_category,
        cs.total_orders,
        cs.product_revenue,
        cs.freight_to_revenue_pct,
        cr.reviewed_orders,
        cr.average_review_score,
        cr.negative_review_pct,

        DENSE_RANK() OVER (
            ORDER BY cs.product_revenue DESC
        ) AS revenue_rank

    FROM category_sales AS cs

    LEFT JOIN category_reviews AS cr
        ON cs.product_category = cr.product_category
)

SELECT
    revenue_rank,
    product_category,
    total_orders,

    ROUND(
        product_revenue,
        2
    ) AS product_revenue,

    ROUND(
        freight_to_revenue_pct,
        2
    ) AS freight_to_revenue_pct,

    reviewed_orders,

    ROUND(
        average_review_score,
        2
    ) AS average_review_score,

    ROUND(
        negative_review_pct,
        2
    ) AS negative_review_pct,

    CASE
        WHEN revenue_rank <= 10
             AND average_review_score < 4.10
            THEN 'Critical: High revenue / lower satisfaction'

        WHEN revenue_rank <= 10
            THEN 'Protect: High revenue / strong satisfaction'

        WHEN average_review_score < 4.00
            THEN 'Improve customer experience'

        WHEN freight_to_revenue_pct >= 25
            THEN 'Review logistics costs'

        ELSE 'Monitor'
    END AS business_priority

FROM combined_categories

ORDER BY revenue_rank;


SELECT
    table_name
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name IN (
      'vw_product_category_performance',
      'vw_top_products',
      'vw_product_abc_analysis',
      'vw_category_satisfaction',
      'vw_category_business_priorities'
  )
ORDER BY table_name;