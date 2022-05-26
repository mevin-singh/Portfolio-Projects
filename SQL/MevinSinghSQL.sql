/*	
	Name: Mevin Singh
	Skills used: Joins, Aggregations, Window functions
*/


------------------------------------------- Question 1 -------------------------------------------------------------------------------
/* 
	How much revenue was generated on each item sold in each transaction in April 2019?
*/

SELECT ot.*, CAST(RIGHT(current_retail_price, LENGTH(current_retail_price) - 1) AS numeric) AS price, CAST(RIGHT(current_retail_price, LENGTH(current_retail_price) - 1) AS numeric) * quantity AS revenue 
FROM operations.transactions AS ot
INNER JOIN operations.products AS op
ON ot.product_id = op.product_id;



------------------------------------------- Question 2 -------------------------------------------------------------------------------
/*
	How much revenue was generated on each transaction in April 2019?
*/

SELECT transaction_sn, sales_outlet_id, transaction_date, SUM(CAST(RIGHT(current_retail_price, LENGTH(current_retail_price) - 1) AS numeric) * quantity) AS revenue
FROM operations.transactions AS ot
INNER JOIN operations.products AS op
ON ot.product_id = op.product_id
GROUP BY transaction_sn, sales_outlet_id, transaction_date
ORDER BY transaction_sn, sales_outlet_id, transaction_date;



------------------------------------------- Question 3 -------------------------------------------------------------------------------
/*
	How much revenue was generated by each store in April 2019?
*/

SELECT sales_outlet_id, SUM(CAST(RIGHT(current_retail_price, LENGTH(current_retail_price) - 1) AS numeric) * quantity) AS revenue
FROM operations.transactions AS ot
INNER JOIN operations.products AS op
ON ot.product_id = op.product_id
GROUP BY sales_outlet_id
ORDER BY sales_outlet_id;



------------------------------------------- Question 4 -------------------------------------------------------------------------------
/*
	 How much revenue was generated by each store in each week of April 2019?
*/

SELECT sales_outlet_id, DATE_PART('week', transaction_date) AS week, SUM(CAST(RIGHT(current_retail_price, LENGTH(current_retail_price) - 1) AS numeric) * quantity) AS revenue
FROM operations.transactions AS ot
INNER JOIN operations.products AS op
ON ot.product_id = op.product_id
GROUP BY sales_outlet_id, week
ORDER BY sales_outlet_id, week;



------------------------------------------- Question 5 -------------------------------------------------------------------------------
/*
	Is the daily inventory table accurate?
*/

SELECT * 
FROM
	(SELECT od.*, quantity_sold_trans,
	CASE 
		WHEN quantity_sold = quantity_sold_trans THEN 1
		ELSE 0
	END AS match
	FROM
		(SELECT sales_outlet_id, transaction_date, product_id, SUM(quantity) AS quantity_sold_trans
		FROM operations.transactions
		GROUP BY sales_outlet_id, transaction_date, product_id
		ORDER BY sales_outlet_id, transaction_date, product_id) AS sub
	INNER JOIN operations.daily_inventory_pastry AS od
	ON sub.sales_outlet_id = od.sales_outlet_id AND sub.transaction_date = od.transaction_date AND sub.product_id = od.product_id) AS subsub
WHERE match = 0;

/* 
	From the query output, there are many 0s present in the match column which means quantity_bought from transactions table does not match quantity_sold from the
	the daily_inventory_pastry table does not match. Thus, the quantity_sold column is dirty with 138 rows not matching.
*/

------------------------------------------- Question 6 ----------------------------------------------------------------------------------------
/*
	Which pastry should each outlet we stop selling?
*/

SELECT * 
FROM
	(SELECT *, RANK() OVER(PARTITION BY sales_outlet_id ORDER BY waste DESC) AS Ranking
	FROM
		(SELECT sales_outlet_id, product_id, SUM(start_of_day - quantity_sold) AS waste
		FROM operations.daily_inventory_pastry
		GROUP BY sales_outlet_id, product_id
		ORDER BY sales_outlet_id, SUM(start_of_day - quantity_sold) DESC) AS sub) AS subsub
WHERE Ranking = 1;

/* 
	From the query output above, all 3 stores should stop selling product_id 72 as it generated the most amount of waste in April 2019 across 
	all 3 stores.
*/

------------------------------------------- Question 7 -------------------------------------------------------------------------------
/*
	What are the top 3 products for each store?
*/

SELECT *
FROM
	(SELECT *, RANK() OVER(PARTITION BY sales_outlet_id ORDER BY total_r DESC) AS ranking
	FROM
		(SELECT sales_outlet_id, product_id, SUM(quantity) AS total_q, SUM(revenue) AS total_r
		FROM
			(SELECT op.*, ot.quantity, ot.sales_outlet_id, CAST(RIGHT(current_retail_price, LENGTH(current_retail_price) - 1) AS numeric) * quantity AS Revenue
			FROM operations.products AS op
			INNER JOIN operations.transactions AS ot
			ON op.product_id = ot.product_id) AS sub
		GROUP BY sales_outlet_id, product_id
		ORDER BY sales_outlet_id, total_r DESC) AS subsub) AS subsubsub
INNER JOIN operations.products
ON operations.products.product_id = subsubsub.product_id
WHERE Ranking IN (1, 2, 3) 
ORDER BY sales_outlet_id;

------------------------------------------- Question 8 -------------------------------------------------------------------------------
/*
	How much did generations spend on average each week in each outlet?
*/

SELECT generation, sales_outlet_id, weeknumber, SUM(revenue) AS average_spending
FROM
	(SELECT ol.*, DATE_PART('year', ol.birth_date) AS birth_year, ot.product_id, ot.quantity, ot.sales_outlet_id, ot.transaction_date, DATE_PART('week', ot.transaction_date) AS WeekNumber, op.current_retail_price, CAST(RIGHT(current_retail_price, LENGTH(current_retail_price) - 1) AS numeric) * quantity AS Revenue, oi.generation
	FROM operations.loyalty_customers AS ol
	INNER JOIN operations.transactions AS ot
	ON ol.customer_id = ot.customer_id
	INNER JOIN operations.products AS op
	ON op.product_id = ot.product_id
	INNER JOIN operations.imported_generations AS oi
	ON oi.birth_year = DATE_PART('year', ol.birth_date)) AS sub
GROUP BY generation, sales_outlet_id, weeknumber
ORDER BY generation, sales_outlet_id, weeknumber;


------------------------------------------- Question 9 -------------------------------------------------------------------------------
/* 
	Who should get the best customer award for April 2019 in each store?
*/	

-- visits
SELECT sales_outlet_id, customer_id, COUNT(*) AS visits
FROM
	(SELECT DISTINCT ON (transaction_sn)*
	FROM operations.transactions
	WHERE customer_id IS NOT NULL) AS sub
GROUP BY sales_outlet_id, customer_id;

-- spending
SELECT sales_outlet_id, customer_id, SUM(spent) AS total_spent
FROM
	(SELECT sales_outlet_id, customer_id, ot.product_id, CAST(RIGHT(current_retail_price, LENGTH(current_retail_price) - 1) AS numeric) * quantity AS spent
	FROM operations.transactions AS ot
	INNER JOIN operations.products AS op
	ON ot.product_id = op.product_id) AS sub
WHERE customer_id IS NOT NULL
GROUP BY sales_outlet_id, customer_id
ORDER BY sales_outlet_id, total_spent DESC

-- combining both visits and spending
SELECT sales_outlet_id, customer_id, visits, total_spent
FROM
	(SELECT *, RANK() OVER(PARTITION BY sales_outlet_id ORDER BY visits DESC, total_spent DESC) AS ranking
	FROM
		(SELECT sub1.sales_outlet_id, sub1.customer_id, visits, total_spent
		FROM
		(SELECT sales_outlet_id, customer_id, COUNT(*) AS visits
		FROM
			(SELECT DISTINCT ON (sales_outlet_id, transaction_sn, transaction_date)*
			FROM operations.transactions
			WHERE customer_id IS NOT NULL) AS sub
		GROUP BY sales_outlet_id, customer_id) AS sub1
		INNER JOIN
		(SELECT sales_outlet_id, customer_id, SUM(spent) AS total_spent
		FROM
			(SELECT sales_outlet_id, customer_id, ot.product_id, CAST(RIGHT(current_retail_price, LENGTH(current_retail_price) - 1) AS numeric) * quantity AS spent
			FROM operations.transactions AS ot
			INNER JOIN operations.products AS op
			ON ot.product_id = op.product_id) AS sub
		WHERE customer_id IS NOT NULL
		GROUP BY sales_outlet_id, customer_id
		ORDER BY sales_outlet_id, total_spent DESC) AS sub2
		ON sub1.customer_id = sub2.customer_id AND sub1.sales_outlet_id = sub2.sales_outlet_id
		ORDER BY sub1.sales_outlet_id, visits DESC, total_spent DESC) AS sub3) AS sub4
WHERE ranking = 1;


------------------------------------------- Question 10 -------------------------------------------------------------------------------
/* 
	For each store, what is the distribution of the generation of customer visits? By knowing this information, the coffeeshop management can then decide and evaluate their 
	current marketing strategies, possibly continuing or changing it to improve customer visits in order to appeal to the generation of people who visit that particular outlet
 	the most. 
*/

SELECT sales_outlet_id, generation, SUM(count) AS visits
FROM
	(SELECT DISTINCT ON(customer_id)*, COUNT(*)
	FROM
		(SELECT sales_outlet_id, ot.customer_id, generation
		FROM operations.transactions AS ot
		INNER JOIN operations.imported_dates AS oid
		ON ot.transaction_date = oid.transaction_date
		INNER JOIN operations.loyalty_customers AS ol
		ON ot.customer_id = ol.customer_id
		INNER JOIN operations.imported_generations AS oig
		ON oig.birth_year = DATE_PART('year', ol.birth_date)) AS sub
	GROUP BY sub.sales_outlet_id, sub.customer_id, sub.generation) AS subsub
GROUP BY sales_outlet_id, generation
ORDER BY sales_outlet_id, SUM(count) DESC;

/*
	From the query output, it seems outlet 3 attracts the least Younger Millenials. As such, they can do market research on what these 
	generation like to drink and eat using surveys to bring the numbers up. They can also do so for all other stores and all other outlet 
	as deemed neccessary. 
*/

------------------------------------------- Question 11 -------------------------------------------------------------------------------
/* 
   For each store, what are the top 3 product category did each generation of customers buy the least? Using this information, the coffeeshop 
   can understand their customers better than sell more of the products that the customers like. 
*/
   
SELECT * 
FROM
	(SELECT *, DENSE_RANK() OVER(PARTITION BY sales_outlet_id ORDER BY purchase_freq) AS ranking
	FROM
		(SELECT *, COUNT(*) AS purchase_freq
		FROM
			(SELECT sales_outlet_id, op.product_category, oig.generation 
			FROM operations.transactions AS ot
			INNER JOIN operations.products AS op
			ON ot.product_id = op.product_id
			INNER JOIN operations.loyalty_customers AS ol
			ON ol.customer_id = ot.customer_id
			INNER JOIN operations.imported_generations AS oig
			ON oig.birth_year = DATE_PART('year', ol.birth_date)) AS sub
		GROUP BY sales_outlet_id, product_category, generation
		ORDER BY sales_outlet_id, COUNT(*) ASC) AS subsub) AS subsubsub
WHERE ranking IN (1, 2, 3);

/*
	From the query output, we can see that across outlets 3, 5 and 8, branded, loose tea and packages chocolate seems be the least favourite. 
	The coffeeshop can now decide if they would want to continue with these product category as it may not profitable to do so. If they wish to continue, they can 
   	then decide the next steps forward. 
*/

------------------------------------------- Question 12 -------------------------------------------------------------------------------
/* 
	For each store, how much profits were generated for each week in April 2019? Knowing this information can help the management of the coffeeshop to see how much they have earned
  	as well as see if they have met their pre-determined target for the month. 
*/

SELECT sales_outlet_id, week, SUM(profit)
FROM
	(SELECT sales_outlet_id, week, (CAST(RIGHT(current_retail_price, LENGTH(current_retail_price) - 1) AS numeric) - estimated_cost_price) * quantity AS profit
	FROM operations.transactions AS ot
	INNER JOIN operations.imported_dates AS oid
	ON ot.transaction_date = oid.transaction_date
	INNER JOIN operations.products AS op
	ON op.product_id = ot.product_id) AS sub
GROUP BY sales_outlet_id, week
ORDER BY sales_outlet_id, week, SUM(profit) DESC;

/* 
	From the query output, it seems for each store, week 18 generated the least profit. This is due to the fact that week 18 only has 2 dates which are 29th and 30th April.
	Apart from that, the profit seems to be relatively constant around 10k to 13k. The coffeeshop can use these numbers to check against their own targets and make any changes 
	to their business processess if needed.
*/