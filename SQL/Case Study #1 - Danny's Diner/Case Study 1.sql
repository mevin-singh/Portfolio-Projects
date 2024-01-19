-- 1. What is the total amount each customer spent at the restaurant?
WITH combined AS (
	SELECT * 
	FROM dannys_diner.menu
	INNER JOIN dannys_diner.sales USING (product_id)
)

SELECT customer_id, SUM(price) AS total_spent
FROM combined
GROUP BY 1
ORDER BY 2 DESC


-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS n_vists 
FROM dannys_diner.sales
GROUP BY 1


-- 3. What was the first item from the menu purchased by each customer?
WITH combined AS (
	SELECT *
	FROM dannys_diner.sales
	INNER JOIN dannys_diner.menu USING (product_id)
)

SELECT customer_id, product_name AS first_item_purchased
FROM
	(SELECT *, RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS rnk
	FROM combined) a
WHERE rnk = 1


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH combined AS (
	SELECT *
	FROM dannys_diner.sales
	INNER JOIN dannys_diner.menu USING (product_id)
)

SELECT product_name, COUNT(*) AS n_times 
FROM combined
GROUP BY 1
ORDER BY 2 DESC


-- 5. Which item was the most popular for each customer?
WITH combined AS (
	SELECT *
	FROM dannys_diner.sales
	INNER JOIN dannys_diner.menu USING (product_id)
),

popularity AS (
	SELECT customer_id, product_name, COUNT(*) AS n_times
	FROM combined
	GROUP BY 1,2
),

ranked AS (
	SELECT *, RANK() OVER (PARTITION BY customer_id ORDER BY n_times DESC) AS rnk
	FROM popularity
)

SELECT * FROM ranked
WHERE rnk = 1


-- 6. Which item was purchased first by the customer after they became a member?
WITH combined AS (
	SELECT * 
	FROM dannys_diner.members
	INNER JOIN dannys_diner.sales USING (customer_id)
	INNER JOIN dannys_diner.menu USING (product_id)
	WHERE order_date > join_date
),

ranked AS (
	SELECT *, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) AS row_num
	FROM combined	
)

SELECT customer_id, product_name
FROM ranked
WHERE row_num = 1


-- 7. Which item was purchased just before the customer became a member?
WITH combined AS (
	SELECT * 
	FROM dannys_diner.members
	INNER JOIN dannys_diner.sales USING (customer_id)
	INNER JOIN dannys_diner.menu USING (product_id)
	WHERE order_date < join_date
),

ranked AS (
	SELECT *, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) AS row_num
	FROM combined	
)

SELECT customer_id, product_name
FROM ranked
WHERE row_num = 1


-- 8. What is the total items and amount spent for each member before they became a member?
WITH before_member AS (
	SELECT * 
	FROM dannys_diner.members
	INNER JOIN dannys_diner.sales USING (customer_id)
	INNER JOIN dannys_diner.menu USING (product_id)
	WHERE order_date < join_date
)

SELECT customer_id, COUNT(*) AS n_times, SUM(price) AS total_spent 
FROM before_member
GROUP BY 1


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH spending AS (
	SELECT * 
	FROM dannys_diner.sales
	INNER JOIN dannys_diner.menu USING (product_id)
),

points AS (
	SELECT 
		customer_id, 
		product_name, 
		price,
		CASE 
			WHEN product_name = 'sushi' THEN price * 10 * 2 
			ELSE price * 10
		END AS num_points
	FROM spending
)

SELECT customer_id, SUM(num_points) AS total_points 
FROM points
GROUP BY 1
ORDER BY 2 DESC

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH first_week AS (
	SELECT 
		*,
		CAST(join_date + INTERVAL '1 week' AS DATE)  AS first_week
	FROM dannys_diner.members
),

combined AS (
	SELECT * 
	FROM first_week
	INNER JOIN dannys_diner.sales USING (customer_id)
	INNER JOIN dannys_diner.menu USING (product_id)
	WHERE (order_date < '2021-02-01') AND (order_date > join_date)
),

spending AS (
	SELECT 
		customer_id, 
		CASE
			WHEN order_date BETWEEN join_date AND first_week THEN price * 10 * 2
			WHEN (order_date NOT BETWEEN join_date AND first_week) AND (product_name = 'sushi') THEN price * 10 * 2
			ELSE price * 10
		END AS num_points
	FROM combined
)

SELECT customer_id, SUM(num_points) AS total_points 
FROM spending
GROUP BY 1
ORDER BY 2 DESC

-- Bonus Question 1: Join All the Things
WITH combined AS (
	SELECT *
	FROM dannys_diner.sales
	LEFT JOIN dannys_diner.members USING (customer_id)
	LEFT JOIN dannys_diner.menu USING (product_id)
)

SELECT 
	customer_id, 
	order_date,
	product_name,
	price, 
	CASE 
		WHEN (join_date IS NULL) OR (order_date < join_date) THEN 'N'
		WHEN (order_date >= join_date) THEN 'Y'
	END AS member
FROM combined
ORDER BY 1,2,3,4


-- Bonus Question 2: Rank All the Things
WITH combined AS (
	SELECT *
	FROM dannys_diner.sales
	LEFT JOIN dannys_diner.members USING (customer_id)
	LEFT JOIN dannys_diner.menu USING (product_id)
),

complete AS (
	SELECT 
		customer_id, 
		order_date,
		product_name,
		price, 
		CASE 
			WHEN (join_date IS NULL) OR (order_date < join_date) THEN 'N'
			WHEN (order_date >= join_date) THEN 'Y'
		END AS member
	FROM combined
)

SELECT
	*,
	-- need to partition by member as well since ranking needs to start from 1 for each customer_id when member = 'Y'
	CASE
		WHEN member = 'Y' THEN RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date, price DESC)
		ELSE NULL
	END AS ranking
FROM complete





