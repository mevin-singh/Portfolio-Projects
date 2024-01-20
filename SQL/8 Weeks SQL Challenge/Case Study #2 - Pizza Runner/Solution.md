# 🍕 Case Study #2 - Pizza Runner
<img src = "https://8weeksqlchallenge.com/images/case-study-designs/2.png"
alt = "Image" width = "500" height = "520">

## Data Cleaning and Preprocessing
```sql
-- Cleaning runner_orders
CREATE OR REPLACE VIEW runner_orders_cleaned AS (
	SELECT 
		order_id,
		runner_id,
		CASE
			WHEN pickup_time = 'null' THEN NULL
			ELSE CAST(pickup_time AS TIMESTAMP)
		END AS pickup_time,
		CASE
			WHEN distance = 'null' THEN NULL
			ELSE CAST(REPLACE(TRIM(distance), 'km', '') AS NUMERIC)
		END AS distance,
		CASE
			WHEN duration = 'null' THEN NULL
			ELSE CAST(SUBSTRING(duration, '[0-9]+') AS NUMERIC)
		END AS duration_mins,
		-- assuming null or empty string means not cancelled
		CASE 
			WHEN cancellation IN ('', 'null') OR cancellation IS NULL THEN 0
			ELSE 1
		END AS cancellation
	FROM pizza_runner.runner_orders
)
```
***

```sql
-- Cleaning customer_orders
CREATE OR REPLACE VIEW customer_orders_cleaned AS (
	WITH customer_orders AS (
	SELECT 
		order_id,
		customer_id,
		pizza_id,
		-- adding a 'null' to where appropriate - to be replaced later
		-- if not added, nulls would be removed when unnesting in the next cte
		CASE WHEN exclusions IN ('') THEN 'null' ELSE exclusions END AS exclusions,
		CASE WHEN extras = '' OR extras IS NULL THEN 'null' ELSE extras END AS extras,
		order_time
	FROM pizza_runner.customer_orders
),

customer_orders_intermediate AS (
	SELECT
		order_id,
		customer_id,
		pizza_id,
		-- string_to_array then unnest to remove comma into a new row
		UNNEST(STRING_TO_ARRAY(exclusions, ', ')) AS exclusions,
		UNNEST(STRING_TO_ARRAY(extras, ', ')) AS extras,
		order_time,
		EXTRACT(hour FROM order_time) AS order_hour,
		TO_CHAR(order_time, 'Day') AS day_of_week
	FROM customer_orders
)

	SELECT
		order_id,
		customer_id,
		pizza_id,
		CAST(CASE WHEN exclusions = 'null' THEN NULL ELSE exclusions END AS NUMERIC) AS exclusions,
		CAST(CASE WHEN extras = 'null' THEN NULL ELSE extras END AS NUMERIC) AS extras,
		order_time,
		order_hour,
		day_of_week
	FROM customer_orders_intermediate
)
```
*** 

```sql
-- Cleaning pizza_toppings
CREATE OR REPLACE VIEW pizza_toppings_cleaned AS (
	WITH pizza_recipe AS (
		SELECT
		pizza_id,
		CAST(UNNEST(STRING_TO_ARRAY(toppings, ', ')) AS NUMERIC) AS topping_id
	FROM pizza_runner.pizza_recipes
	)
	
	SELECT 
		pizza_id,
		topping_id,
		topping_name
	FROM pizza_recipe
	INNER JOIN pizza_runner.pizza_toppings USING (topping_id)
	ORDER BY pizza_id, topping_id
)
```
## Case Study Questions

### A. Pizza Metrics

#### 1. How many pizzas were ordered?

````sql
SELECT COUNT(*) AS n_pizzas
FROM #customer_orders;
````
| number_of_pizza_ordered |
| ----------------------- |
| 14                      |

***

#### 2. How many unique customer orders were made?

````sql
SELECT customer_id,
	COUNT(DISTINCT order_id) AS unique_customer_orders
FROM pizza_runner.customer_orders
GROUP BY 1
  ````

| customer_id | unique_customer_orders |
| ----------- | ---------------------- |
| 101         | 3                      |
| 102         | 2                      |
| 103         | 2                      |
| 104         | 2                      |
| 105         | 1                      |

***

#### 3. How many successful orders were delivered by each runner?
```sql
SELECT RUNNER_ID, COUNT(*) AS N_SUCCESSFUL
FROM RUNNER_ORDERS_CLEANED
WHERE CANCELLATION = 0
GROUP BY 1
```
| runner_id | delivered_orders |
| --------- | ---------------- |
| 1         | 4                |
| 2         | 3                |
| 3         | 1                |

***

#### 4. How many of each type of pizza was delivered?
```sql
WITH combined AS (
	SELECT * 
	FROM pizza_runner.customer_orders
	INNER JOIN pizza_runner.pizza_names USING (pizza_id)
	INNER JOIN runner_orders_cleaned USING (order_id)
	WHERE cancellation = 0
)

SELECT 
	PIZZA_NAME, 
	COUNT(*) AS n_pizzas 
FROM combined
GROUP BY 1
ORDER BY 1, 2
```

| pizza_name | n_pizzas |
| ---------- | -------------------------- |
| Meatlovers | 9                          |
| Vegetarian | 3                          |

***

#### 5. How many Vegetarian and Meatlovers were ordered by each customer?
```sql
WITH combined AS (
	SELECT * 
	FROM pizza_runner.customer_orders
	LEFT JOIN pizza_runner.pizza_names USING (pizza_id)
	LEFT JOIN runner_orders_cleaned USING (order_id)
	WHERE cancellation = 0
)

SELECT 
 	customer_id, 
 	SUM(CASE WHEN pizza_name = 'Meatlovers' THEN 1 ELSE 0 END) AS n_meatlovers,
 	SUM(CASE WHEN pizza_name = 'Vegetarian' THEN 1 ELSE 0 END) AS n_vegetarian
FROM combined
GROUP BY 1
ORDER BY 1
```
| customer_id | n_meatlovers | n_vegetarian |
| ----------- | ---------- | -------------------------- |
| 101         | 2          | 0                          |
| 102         | 2          | 1                          |
| 103         | 2          | 1                          |
| 104         | 3          | 0                          |
| 105         | 0          | 1                         |

***

#### 6. What was the maximum number of pizzas delivered in a single order?
```sql
WITH combined AS (
	SELECT * 
	FROM pizza_runner.customer_orders
	INNER JOIN runner_orders_cleaned USING (order_id)
	WHERE cancellation = 0
)

SELECT 
	order_id,
	COUNT(*) AS n_pizzas
FROM combined
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1
```
| order_id | n_pizzas       |
| -------- | -------------- |
| 4        | 3              |

***

#### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
```sql
WITH combined AS (
	SELECT *
	FROM customer_orders_cleaned
	INNER JOIN runner_orders_cleaned USING (order_id)
	WHERE cancellation = 0
)

SELECT 
	customer_id,
	SUM(CASE WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1 ELSE 0 END) AS n_at_least_1_change,
	SUM(CASE WHEN exclusions IS NULL AND extras IS NULL THEN 1 ELSE 0 END) AS n_no_change 
FROM combined
GROUP BY 1
ORDER BY 1
```
| customer_id | n_at_least_1_change | n_no_change |
| ----------- | ---------- | -------------------------- |
| 101         | 0          | 2                          |
| 102         | 0          | 3                          |
| 103         | 3          | 0                          |
| 104         | 3          | 1                          |
| 105         | 1          | 0                          |

***

#### 8. How many pizzas were delivered that had both exclusions and extras?
```sql
WITH combined AS (
	SELECT 
		*
	FROM customer_orders_cleaned
	INNER JOIN runner_orders_cleaned USING (order_id)
	WHERE cancellation = 0
)

SELECT 
	COUNT(DISTINCT order_id) AS n_pizzas
FROM combined
WHERE exclusions IS NOT NULL AND extras IS NOT NULL 
```
| n_pizzas |
| ---------------- |
| 1                |

***

#### 9. What was the total volume of pizzas ordered for each hour of the day?
```sql
SELECT 
	order_hour,
	COUNT(*) AS n_orders
FROM customer_orders_cleaned
GROUP BY 1 
ORDER BY 1
```
| order_hour | n_orders|
| ----- | -------------- |
| 11    | 2              |
| 13    | 3              |
| 18    | 4              |
| 19    | 1              |
| 21    | 3              |
| 23    | 3              |

***

#### 10. What was the volume of orders for each day of the week?
```sql
SELECT 
	day_of_week,
	COUNT(*) AS n_orders
FROM customer_orders_cleaned
GROUP BY 1 
ORDER BY 1
```
| day_of_week | n_orders |
| ----------- | -------------- |
| Friday      | 2              |
| Saturday    | 6               |
| Thursday    | 3              |
| Wedneday    | 5              |

***

### B. Runner and Customer Experience

#### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
```sql
WITH week_nums AS (
	SELECT 
		*,
		CASE
			-- '2021-01-01' is the starting week so change to 1
			WHEN DATE_PART('week', registration_date) = 53 THEN 1 
			ELSE DATE_PART('week', registration_date) + 1
		END AS week_num
	FROM pizza_runner.runners
)

SELECT 
	week_num,
	COUNT(runner_id) AS n_runners
FROM week_nums
GROUP BY 1
ORDER BY 1
```

| week_num | n_runners |
| -------------- | ----------------------- |
| 1         | 2                       |
| 2         | 1                       |
| 3         | 1                       |

***

#### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
```sql
WITH combined AS (
	SELECT 
		runner_id,
		order_id,
		order_time,
		pickup_time
	FROM customer_orders_cleaned
	INNER JOIN runner_orders_cleaned USING (order_id)
	WHERE cancellation = 0
),

arrival_times AS (
	SELECT
		runner_id,
		order_id,
		EXTRACT(MINUTE FROM (pickup_time - order_time)) + EXTRACT(SECOND FROM (pickup_time - order_time))/60  AS time_to_arrive
	FROM combined
	WHERE pickup_time - order_time IS NOT NULL
)

SELECT
	runner_id,
	ROUND(AVG(time_to_arrive), 2) AS avg_time_to_arrive
FROM arrival_times
GROUP BY 1
ORDER BY 1
```
| runner_id | avg_time_to_arrive |
| --------- | ------------------------------ |
| 1         | 15.65                          |
| 2         | 23.72                          |
| 3         | 10.47                          |

***

#### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
```sql
WITH combined AS (
	SELECT 
		runner_id,
		order_id,
		order_time,
		pickup_time
	FROM customer_orders_cleaned
	INNER JOIN runner_orders_cleaned USING (order_id)
	WHERE cancellation = 0
),

arrival_times AS (
	SELECT
		order_id,
		EXTRACT(MINUTE FROM (pickup_time - order_time)) + EXTRACT(SECOND FROM (pickup_time - order_time))/60  AS prep_time_mins
	FROM combined
	WHERE pickup_time - order_time IS NOT NULL
),

num_pizzas AS (
	SELECT 
		COUNT(order_id) AS num_pizza,
		SUM(prep_time_mins) AS total_prep_time_mins
	FROM arrival_times
	GROUP BY order_id
)

SELECT 
	num_pizza,
	ROUND(AVG(total_prep_time_mins), 2) AS avg_prep_time_mins
FROM num_pizzas
GROUP BY 1 
ORDER BY 1
```
| num_pizza | avg_prep_time_mins |
| --------- | ------------------------------ |
| 1         | 12.36                          |
| 2         | 42.47                          |
| 3         | 67.20                          |

Preparation time increases as the number of pizza in the order increases.

***

#### 4. What was the average distance travelled for each customer?
```sql
WITH combined AS (
	SELECT 
		customer_id,
		distance
	FROM customer_orders_cleaned
	INNER JOIN runner_orders_cleaned USING (order_id)
	WHERE cancellation = 0
)

SELECT 
	customer_id,
	ROUND(AVG(distance), 2) AS avg_dist
FROM combined
GROUP BY 1
ORDER BY 1
```
| customer_id | average_distance_km  |
| ----------- | -------------------  |
| 101         | 20.00                |
| 102         | 16.73                |
| 103         | 23.40                |
| 104         | 10.00                |
| 105         | 25.00                |  

***

#### 5. What was the difference between the longest and shortest delivery times for all orders?
```sql
WITH combined AS (
	SELECT 
		DISTINCT order_id,
		duration_mins
	FROM customer_orders_cleaned
	INNER JOIN runner_orders_cleaned USING (order_id)
	WHERE cancellation = 0
)

SELECT 
	MAX(duration_mins) AS longest_delivery_mins,
	MIN(duration_mins) AS shortest_delivery_mins,
	MAX(duration_mins) - MIN(duration_mins) AS difference_mins
FROM combined
```
| longest_delivery_mins| shortest_delivery_mins | difference_mins |
| -------------------- | ---------------------- | --------------- |
| 40                   | 10                     |   30            |

***

#### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
```sql
WITH combined AS (
	SELECT 
		order_id,
		runner_id,
		distance,
		duration_mins/60 AS duration_hrs
	FROM customer_orders_cleaned
	INNER JOIN runner_orders_cleaned USING (order_id)
	-- order is only delivering then there is no cancellation
	WHERE cancellation = 0
)

SELECT 
    DISTINCT
	order_id,
	runner_id,
	-- average speed since total distance/total time and not avg aggregation function
	ROUND(distance/duration_hrs, 2) AS avg_speed_kmph
FROM combined
```
| order_id | runner_id | avg_speed_kmph |
| -------- | --------- | -------------------- |
| 1        | 1         | 37.50                |
| 2        | 1         | 44.44                |
| 3        | 1         | 40.20                |
| 4        | 2         | 35.10                |
| 5        | 3         | 40.00                |
| 7        | 2         | 60.00                |
| 8        | 2         | 93.60                |
| 10       | 1         | 60.00                | 

The max speed for runner 2 in order_id 8 is around 94 km/h which is very fast as compared to the other speeds. Safety should be emphasized during deliveries even if deliveries are late or delayed.

***

#### 7. What is the successful delivery percentage for each runner?
```sql
SELECT 
	runner_id,
	SUM(CASE WHEN cancellation = 0 THEN 1 ELSE 0 END) AS succesful_orders,
	COUNT(*) AS n_orders,
	ROUND(CAST(SUM(CASE WHEN cancellation = 0 THEN 1 ELSE 0 END) AS NUMERIC)/CAST(COUNT(*) AS NUMERIC) * 100, 2) AS success_perc
FROM runner_orders_cleaned
GROUP BY 1
ORDER BY 1
```
| runner_id | successful_orders  | n_orders | success_perc |
| --------- | ------------------ | -------- | ------------ |
| 1         | 4                  | 4        | 100          |
| 2         | 3                  | 4        | 75           |
| 3         | 1                  | 2        | 50           |

***

### C. Ingredient Optimisation

#### 1. What are the standard ingredients for each pizza?
```sql
SELECT 
	*
FROM pizza_toppings_cleaned 
```
| pizza_id | topping_id | topping_name |
|----------|------------|--------------|
| 1        | 1          | "Bacon"      |
| 1        | 2          | "BBQ Sauce"  |
| 1        | 3          | "Beef"       |
| 1        | 4          | "Cheese"     |
| 1        | 5          | "Chicken"    |
| 1        | 6          | "Mushrooms"  |
| 1        | 8          | "Pepperoni"  |
| 1        | 10         | "Salami"     |
| 2        | 4          | "Cheese"     |
| 2        | 6          | "Mushrooms"  |
| 2        | 7          | "Onions"     |
| 2        | 9          | "Peppers"    |
| 2        | 11         | "Tomatoes"   |
| 2        | 12         | "Tomato Sauce"|

Meatlovers (pizza_id 1) contains the ingredients: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami

Vegetarian (pizza_id 2) contains the ingredients: Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce  

***

#### 2. What was the most commonly added extra?
```sql
WITH most_common_extra AS (
	SELECT 
		extras,
		COUNT(*) AS n_times
	FROM customer_orders_cleaned
	WHERE extras IS NOT NULL
	GROUP BY 1
)

SELECT
	DISTINCT
	topping_name,
	n_times
FROM most_common_extra AS a
INNER JOIN pizza_toppings_cleaned AS b
ON a.extras = b.topping_id
ORDER BY n_times DESC
LIMIT 1
```
| topping_name     | n_times |
| ---------------- | ---------------- |
| Bacon            | 4                |

***

#### 3. What was the most common exclusion?
```sql
WITH most_common_exclusion AS (
	SELECT 
		exclusions,
		COUNT(*) AS n_times
	FROM customer_orders_cleaned
	WHERE exclusions IS NOT NULL
	GROUP BY 1
)

SELECT
	DISTINCT
	topping_name,
	n_times
FROM most_common_exclusion AS a
INNER JOIN pizza_toppings_cleaned AS b
ON a.exclusions = b.topping_id
ORDER BY n_times DESC
LIMIT 1
```
| topping_name     | n_times |
| ---------------- | ---------------- |
| Cheese           | 4                |

***

#### 4. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
```sql
WITH delivered AS (
	SELECT order_id 
	FROM runner_orders_cleaned
	WHERE cancellation = 0
),

toppings AS (
	SELECT pizza_id, topping_id, topping_name  
	FROM pizza_toppings_cleaned
),

orders AS (
	SELECT order_id, pizza_id
	FROM customer_orders_cleaned
),

exclusions AS (
	SELECT exclusions, COUNT(*) AS n_exclude 
	FROM customer_orders_cleaned
	WHERE exclusions IS NOT NULL
	GROUP BY exclusions
),

extras AS (
	SELECT extras, COUNT(*) AS n_extras
	FROM customer_orders_cleaned
	WHERE extras IS NOT NULL
	GROUP BY extras
),

n_toppings AS (
	SELECT topping_name, topping_id, COUNT(*) AS counts
	FROM orders AS o
	INNER JOIN delivered AS d 
	USING (order_id)
	INNER JOIN toppings AS t
	USING (pizza_id)
	GROUP BY topping_name, topping_id
)

SELECT topping_name, counts 
FROM n_toppings
ORDER BY counts DESC
```
| topping_name | counts |
|--------------|--------|
| "Cheese"     | 13     |
| "Mushrooms"  | 13     |
| "Chicken"    | 10     |
| "Beef"       | 10     |
| "BBQ Sauce"  | 10     |
| "Bacon"      | 10     |
| "Pepperoni"  | 10     |
| "Salami"     | 10     |
| "Tomato Sauce" | 3    |
| "Tomatoes"   | 3      |
| "Onions"     | 3      |
| "Peppers"    | 3      |

***

### D. Pricing and Ratings

#### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
```sql
WITH COMBINED AS
	(SELECT PIZZA_NAME
		FROM CUSTOMER_ORDERS_CLEANED
		INNER JOIN PIZZA_RUNNER.PIZZA_NAMES USING (PIZZA_ID)),
		
	NUM_PIZZAS AS
	(SELECT PIZZA_NAME,
			COUNT(*) AS N_PIZZAS
		FROM COMBINED
		GROUP BY 1),
		
	REVENUE AS
	(SELECT SUM(CASE
					WHEN PIZZA_NAME = 'Meatlovers' THEN N_PIZZAS * 12
					ELSE N_PIZZAS * 10
					END) AS TOTAL_REVENUE
		FROM NUM_PIZZAS)

SELECT *
FROM REVENUE
```

| Revenue           |
| ----------------- |
| 184               |

***

#### 2. What if there was an additional $1 charge for any pizza extras?

#### - Add cheese is $1 extra

```sql
WITH COMBINED AS
	(SELECT PIZZA_NAME,
			EXTRAS
		FROM CUSTOMER_ORDERS_CLEANED
		INNER JOIN PIZZA_RUNNER.PIZZA_NAMES USING (PIZZA_ID)),
		
	NUM_PIZZAS AS
	(SELECT PIZZA_NAME,
			EXTRAS,
			COUNT(*) AS N_PIZZAS
		FROM COMBINED
		GROUP BY 1, 2),
		
	REVENUE AS
	(SELECT SUM(CASE
					WHEN PIZZA_NAME = 'Meatlovers' AND EXTRAS IS NOT NULL THEN N_PIZZAS * (12 + 1)
					WHEN PIZZA_NAME = 'Vegetarian' AND EXTRAS IS NOT NULL THEN N_PIZZAS * (10 + 1)
					WHEN PIZZA_NAME = 'Meatlovers' AND EXTRAS IS NULL THEN N_PIZZAS * 12
					ELSE N_PIZZAS * 10
					END) AS TOTAL_REVENUE
		FROM NUM_PIZZAS)
		
SELECT *
FROM REVENUE
```
| Revenue           |
| ----------------- |
| 190               |

***

#### 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
```sql
WITH SUCCESSFUL_DELIVERIES AS
	(SELECT ORDER_ID,
			DISTANCE
		FROM RUNNER_ORDERS_CLEANED
		WHERE CANCELLATION = 0 ),
		
	COMBINED AS
	(SELECT PIZZA_NAME,
			COUNT(PIZZA_NAME) AS N_PIZZAS,
			SUM(DISTANCE) AS TOTAL_DISTANCE
		FROM CUSTOMER_ORDERS_CLEANED
		INNER JOIN PIZZA_RUNNER.PIZZA_NAMES USING (PIZZA_ID)
		INNER JOIN SUCCESSFUL_DELIVERIES USING (ORDER_ID)
		GROUP BY 1),
		
	REVENUE AS
	(SELECT SUM(CASE
					WHEN PIZZA_NAME = 'Meatlovers' THEN N_PIZZAS * 12 - TOTAL_DISTANCE * 0.3
					ELSE N_PIZZAS * 10 - TOTAL_DISTANCE * 0.3
					END) AS TOTAL_PROFIT
		FROM COMBINED)
		
SELECT *
FROM REVENUE
```
| total_profit          |
| --------------------- |
| 82.38                 |  