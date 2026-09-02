-- ============================================================
-- CUSTOMER & REVENUE INTELLIGENCE PLATFORM
-- COHORT RETENTION ANALYSIS
-- ============================================================

-- Purpose:
-- Measure customer retention by grouping customers according
-- to their first delivered purchase month and tracking whether
-- they return in later months.

-- ------------------------------------------------------------
-- 1. CUSTOMER FIRST PURCHASE MONTH
-- Business Question:
-- In which month was each customer first acquired?
-- ------------------------------------------------------------

SELECT
    c.customer_unique_id,

    DATE_TRUNC(
        'month',
        MIN(o.order_purchase_timestamp::timestamp)
    ) AS cohort_month

FROM customers AS c

INNER JOIN orders AS o
    ON c.customer_id = o.customer_id

WHERE o.order_status = 'delivered'

GROUP BY c.customer_unique_id

ORDER BY cohort_month;

-- ------------------------------------------------------------
-- 2. COHORT SIZE
-- Business Question:
-- How many customers were acquired in each first-purchase month?
-- ------------------------------------------------------------

WITH customer_cohorts AS (

    SELECT
        c.customer_unique_id,

        DATE_TRUNC(
            'month',
            MIN(o.order_purchase_timestamp::timestamp)
        ) AS cohort_month

    FROM customers AS c

    INNER JOIN orders AS o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
)

SELECT
    cohort_month,
    COUNT(*) AS cohort_size

FROM customer_cohorts

GROUP BY cohort_month

ORDER BY cohort_month;

"2016-09-01 00:00:00"	1
"2016-10-01 00:00:00"	262
"2016-12-01 00:00:00"	1
"2017-01-01 00:00:00"	717
"2017-02-01 00:00:00"	1628
"2017-03-01 00:00:00"	2503
"2017-04-01 00:00:00"	2256
"2017-05-01 00:00:00"	3451
"2017-06-01 00:00:00"	3037
"2017-07-01 00:00:00"	3752
"2017-08-01 00:00:00"	4057
"2017-09-01 00:00:00"	4004
"2017-10-01 00:00:00"	4328
"2017-11-01 00:00:00"	7060
"2017-12-01 00:00:00"	5338
"2018-01-01 00:00:00"	6842
"2018-02-01 00:00:00"	6288
"2018-03-01 00:00:00"	6774
"2018-04-01 00:00:00"	6582
"2018-05-01 00:00:00"	6506
"2018-06-01 00:00:00"	5878
"2018-07-01 00:00:00"	5949
"2018-08-01 00:00:00"	6144

-- ------------------------------------------------------------
-- 3. CUSTOMER ACTIVE MONTHS
-- Purpose:
-- Identify every month in which each customer placed at least
-- one delivered order.
-- ------------------------------------------------------------

SELECT DISTINCT
    c.customer_unique_id,

    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp::timestamp
    ) AS purchase_month

FROM customers AS c

INNER JOIN orders AS o
    ON c.customer_id = o.customer_id

WHERE o.order_status = 'delivered'

ORDER BY customer_unique_id,
         purchase_month;


-- ------------------------------------------------------------
-- 4. COHORT ACTIVITY
-- Purpose:
-- Combine each customer's acquisition month with every month
-- in which they made a delivered purchase.
-- ------------------------------------------------------------

WITH customer_cohorts AS (

    SELECT
        c.customer_unique_id,

        DATE_TRUNC(
            'month',
            MIN(o.order_purchase_timestamp::timestamp)
        ) AS cohort_month

    FROM customers AS c

    INNER JOIN orders AS o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
),

customer_activity AS (

    SELECT DISTINCT
        c.customer_unique_id,

        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp::timestamp
        ) AS purchase_month

    FROM customers AS c

    INNER JOIN orders AS o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'
)

SELECT
    cc.customer_unique_id,
    cc.cohort_month,
    ca.purchase_month

FROM customer_cohorts AS cc

INNER JOIN customer_activity AS ca
    ON cc.customer_unique_id = ca.customer_unique_id

ORDER BY cc.customer_unique_id,
         ca.purchase_month;
