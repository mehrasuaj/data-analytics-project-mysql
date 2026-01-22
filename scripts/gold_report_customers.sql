/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
	3. Segments customers into categories (VIP, Regular, New) and age groups
    - VIP: Customers with at least 12 months of history and spending more than €5,000.
	- Regular: Customers with at least 12 months of history but spending €5,000 or less.
	- New: Customers with a lifespan less than 12 months..
   
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/

-- =============================================================================
-- Create Report: dwh_gold.report_customers
-- =============================================================================

/*--------------------------------------------------------------------------
  1. Gathers essential fields such as names, ages, and transaction details.
  -------------------------------------------------------------------------*/
DROP VIEW IF EXISTS dwh_gold.report_customers;
CREATE VIEW dwh_gold.report_customers AS (	
	WITH customers AS (
		SELECT 
		f.order_number,
		f.product_key,
		f.order_date,
		f.shipping_date,
		f.due_date,
		f.sales,
		f.quantity,
		f.price,
		c.customer_key,
		CONCAT(c.first_name,' ',c.last_name) As customer_name,
		c.country,
		c.gender,
		TIMESTAMPDIFF(YEAR, c.birthdate, CURDATE()) AS age
		FROM dwh_gold.fact_sales f
		LEFT JOIN dwh_gold.dim_customer c
		ON c.customer_key = f.customer_key
		WHERE order_date IS NOT NULL
	  ),
	  
/*---------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
---------------------------------------------------------------------------*/
	  customer_aggregations AS (
		  SELECT 
		  customer_key,
		  customer_name,
		  country,
		  age,
		  COUNT(DISTINCT order_number) AS total_order,
		  SUM(sales) AS total_sales,
		  SUM(quantity) AS total_quantity,
		  COUNT( DISTINCT product_key) AS total_products,
		  MIN(order_date) AS first_order,
		  MAX(order_date) AS last_order,
		  TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan_months
		  FROM customers
		  GROUP BY  customer_key, customer_name, country,age
		  ORDER BY customer_key
		)
		
		/*--------------------------------------------------------------------------
	 3. Segments customers into categories (VIP, Regular, New) and age groups.
	  -------------------------------------------------------------------------*/
		SELECT
		customer_key,
		customer_name,
		country,
		age,
		CASE WHEN age <20 THEN 'Under 20'
			 WHEN age BETWEEN 20 AND 29 THEN '20-29'
			 WHEN age BETWEEN 30 AND 39 THEN '30-39'
			 WHEN age BETWEEN 40 AND 49 THEN '40-49'
			 ELSE '50 and above'
		END AS age_group,
		total_order,
		total_sales,
		total_quantity,
		total_products,
		last_order,
		lifespan_months,
		CASE WHEN lifespan_months >=12 AND total_sales > 5000 THEN 'VIP'
			WHEN lifespan_months >=12 AND total_sales < 5000 THEN 'Regular'
			ELSE 'New'
		END AS customer_segment,
		  /*4.Valuable KPIs*/
		TIMESTAMPDIFF(MONTH, last_order, CURDATE()) AS recency_month,
	   ROUND((CASE WHEN total_order = 0 THEN 0
					ELSE total_sales/total_order
			  END),2) AS average_order_value,    
		ROUND((CASE WHEN lifespan_months = 0 THEN total_sales
					ELSE total_sales/lifespan_months
			   END),2) AS average_month_spend
		 FROM customer_aggregations 
);
    

  
  