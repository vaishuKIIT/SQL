Case Study 2 : Pizza

-- making blank valuses null in customer order

drop table if exists customer_orders_edit;

create temp table customer_orders_edit as
select order_id, customer_id,pizza_id,
nullif(exclusions,'') as exclusions,
nullif(extras,'') as extras,
order_time from pizza_runner.customer_orders;

-- modifying data in runner orders (km/min)

drop table if exists runner_orders_edit;

create temp table runner_orders_edit as
select order_id, runner_id, pickup_time, 
cast
(nullif(regexp_replace(distance,'[a-z]+',''),'') as decimal(3,1))
as distance,
cast
(nullif(regexp_replace(duration,'[a-z]+',''),'') as int)
as duration,
nullif (cancellation,'') cancellation
from pizza_runner.runner_orders;


-- 1. How many pizzas were ordered?
select count(order_id) from pizza_runner.customer_orders;

-- 2. How many unique customer orders were made?
select count(distinct order_id) from pizza_runner.customer_orders;

-- 3. How many successful orders were delivered by each runner?
select runner_id, count(order_id) from runner_orders_edit 
where distance is not null
group by runner_id order by runner_id asc;

-- 4. How many of each type of pizza was delivered?
select pizza_id, count(pizza_id) 
from runner_orders_edit join customer_orders_edit
on runner_orders_edit.order_id = customer_orders_edit.order_id
where distance is not null group by pizza_id;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
with cte1 as (
	select customer_id, pizza_id, count(pizza_id) as meatlover
	from customer_orders_edit where pizza_id = 1
	group by customer_id, pizza_id order by customer_id, pizza_id
),
cte2 as (
	select customer_id, pizza_id, count(pizza_id) as vegetarian
	from customer_orders_edit where pizza_id = 2
	group by customer_id, pizza_id order by customer_id, pizza_id
)
select distinct cte1.customer_id, meatlover, veglover from cte1, cte2;

-- 6. What was the maximum number of pizzas delivered in a single order?
select order_id, count(order_id)
from customer_orders_edit
group by order_id
order by count(order_id) desc limit 1

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
select c.customer_id,
  SUM(
    CASE WHEN c.exclusions != ' ' OR c.extras != ' ' THEN 1
    ELSE 0
    END) AS at_least_1_change,
  SUM(
    CASE WHEN c.exclusions = ' ' AND c.extras = ' ' THEN 1 
    ELSE 0
    END) AS no_change
FROM customer_orders c
JOIN runner_orders r
  ON c.order_id = r.order_id
WHERE r.distance != 0
GROUP BY c.customer_id
ORDER BY c.customer_id;

8. How many pizzas were delivered that had both exclusions and extras?
SELECT  
  SUM(
    CASE WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN 1
    ELSE 0
    END) AS pizza_count_w_exclusions_extras
FROM customer_orders c
JOIN runner_orders r
ON c.order_id = r.order_id
WHERE r.distance >= 1 
AND exclusions <> ' ' 
AND extras <> ' ';
