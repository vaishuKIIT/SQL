Case Study 1 - Danny Diner
   
--- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, sum(me.price)
from dannys_diner.menu me join dannys_diner.sales s
on me.product_id = s.product_id
group by s.customer_id
order by s.customer_id;

--- 2. How many days has each customer visited the restaurant?

SELECT s.customer_id, count(distinct s.order_date) as total_days
from  dannys_diner.sales s
group by s.customer_id
order by s.customer_id;

--- 3. What was the first item from the menu purchased by each customer?

with cte as    
(
  SELECT s.customer_id, me.product_name, s.order_date,
  dense_rank() over (partition by s.customer_id order by s.order_date) 
  as ranks
  from dannys_diner.sales s join dannys_diner.menu me
  on me.product_id = s.product_id
)
select customer_id, product_name
from cte
where ranks = 1
group by customer_id, product_name

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

with total_product as
(
  SELECT count(s.product_id) as total_sale, me.product_name
  from dannys_diner.sales s join dannys_diner.menu me
  on me.product_id = s.product_id
  group by s.product_id, me.product_name
)
select total_sale, product_name from total_product
order by total_sale desc limit 1

-- 5. Which item was the most popular for each customer?

with cte as
(
SELECT s.customer_id,me.product_name,count(s.product_id) as total_sale, 
rank() over 
(partition by s.customer_id order by count(s.product_id) desc) as ranking
 from dannys_diner.sales s join dannys_diner.menu me
  on s.product_id = me.product_id
  group by s.customer_id,  me.product_name
 )
 select customer_id, product_name from cte 
 where ranking = 1
 
 
-- 6. Which item was purchased first by the customer after they became a member?

with cte as (
SELECT mem.customer_id, s.product_id, s.order_date, 
row_number() over (partition by mem.customer_id order by s.order_date)as num
from dannys_diner.members mem join dannys_diner.sales s
on mem.customer_id = s.customer_id
and s.order_date > mem.join_date
)
select cte.customer_id, cte.product_id, me.product_name 
from cte join dannys_diner.menu me 
on cte.product_id = me.product_id
and num = 1
order by customer_id

-- 7. Which item was purchased just before the customer became a member?

with cte as (
SELECT mem.customer_id, s.product_id, s.order_date, 
row_number() over (partition by mem.customer_id order by s.order_date desc)as num
from dannys_diner.members mem join dannys_diner.sales s
on mem.customer_id = s.customer_id
and s.order_date < mem.join_date
)
select cte.customer_id, cte.product_id, me.product_name 
from cte join dannys_diner.menu me 
on cte.product_id = me.product_id
and num = 1
order by customer_id

-- 8. What is the total items and amount spent for each member before they became a member?

with cte as (
SELECT mem.customer_id, s.product_id, s.order_date, 
row_number() over (partition by mem.customer_id order by s.order_date desc)as num
from dannys_diner.members mem join dannys_diner.sales s
on mem.customer_id = s.customer_id
and s.order_date < mem.join_date
)
select cte.customer_id,count(cte.customer_id) as total_items,
sum(me.price) as amount_spent
from cte join dannys_diner.menu me 
on cte.product_id = me.product_id
group by customer_id
order by customer_id


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id, sum(case when s.product_id = 1 then me.price*20
else me.price*10 end) as total_poitns
from dannys_diner.sales s join dannys_diner.menu me
on s.product_id = me.product_id
group by s.customer_id
order by s.customer_id


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

select s.customer_id, sum(case when s.order_date >= mem.join_date and 
s.order_date < (mem.join_date + INTERVAL '7 day') then me.price*20
when s.product_id = 1 then me.price*20
else me.price*10 end) as total_points
from dannys_diner.sales s join dannys_diner.menu me
on s.product_id = me.product_id
join dannys_diner.members mem
on s.customer_id = mem.customer_id
group by s.customer_id
order by s.customer_id