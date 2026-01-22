/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/
-- =============================================================================
-- Create Report: dwh_gold.report_products
-- =============================================================================

/*--------------------------------------------------------------------------
  1. Gathers essential fields such as product name, category, subcategory, and cost.
  -------------------------------------------------------------------------*/
DROP VIEW IF EXISTS dwh_gold.report_products;
CREATE VIEW dwh_gold.report_products AS (
		WITH products AS (
			SELECT 
			f.order_number,
			f.order_date,
			f.customer_key,
			f.sales,
			f.quantity,
			p.product_key,
			p.product_id,
			p.product_name,
			p.category,
			p.subcategory,
			p.product_amount
			FROM dwh_gold.fact_sales f 
			LEFT JOIN dwh_gold.dim_product p 
			ON p.product_key = f.product_key
		),
		/*---------------------------------------------------------------------------
		2) Product Aggregations: Summarizes key metrics at the product level
		---------------------------------------------------------------------------*/
		product_aggregations AS (
			SELECT
			product_key,
			product_name,
			category,
			subcategory,
			product_amount,
			COUNT(DISTINCT order_number) AS total_order,
			SUM(sales) AS total_sales,
			SUM(quantity) AS total_quantity,
			COUNT(DISTINCT customer_key) AS total_Customer,
			MIN(order_date) AS first_order,
			MAX(order_date) AS last_order,
			TIMESTAMPDIFF(MONTH, MIN(order_date),MAX(order_date)) AS lifespan_months
			FROM products
			GROUP BY product_key,
					 product_name,
					 category,
					 subcategory, 
					 product_amount
		)
		/*---------------------------------------------------------------------------
		  3) Final Query: Combines all product results into one output
		---------------------------------------------------------------------------*/
		SELECT 
		product_key,
		product_name,
		category,
		subcategory,
		product_amount,
		total_order,
		total_sales,
		total_quantity,
		total_Customer,
		lifespan_months,
		CASE WHEN total_sales >= 50000 THEN 'High-Performer'
			 WHEN total_sales >=10000 THEN 'Mid-Range'
			 ELSE 'Low-Performer'
		END AS performance,
		last_order,
		TIMESTAMPDIFF(MONTH, last_order, CURDATE()) AS recency_months,
		CASE WHEN total_order = 0 THEN 0
			 ELSE total_sales/total_order
		END AS average_revenue_order,
		CASE WHEN lifespan_months = 0 THEN total_sales
			 ELSE total_sales/lifespan_months
		END AS average_monthly_orders
		FROM product_aggregations
);