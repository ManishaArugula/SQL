select * from customer_orders;


select * from driver;
select * from driver_order;

select * from rolls;
select * from rolls_recipes;
select * from ingredients;

-----Sales metrics
---1.how many rolls were ordered
select count(roll_id) as orders
from customer_orders

--2.display unique customers who have ordered
select distinct customer_id from customer_orders

--3.How many successfull orders were delivered by each driver
select driver_id, count(distinct order_id) as deliveries
from driver_order
where cancellation not in ('Cancellation', 'Customer Cancellation')
group by driver_id

select * from driver_order

---Data cleaning---make sure data is in consistent format
--update driver_order
--set cancellation = 'No'
--where cancellation in ('','NaN') or cancellation is null


----4.Number of orders for each roll that have been delivered successfuly?


select cus.roll_id,COUNT(roll_id) from customer_orders as cus join
(select order_id from driver_order
where cancellation='No') as deliveries on cus.order_id= deliveries.order_id
group by roll_id

--5.How many veg and non-veg rolls were ordered by each customer

select customer_id,roll_name,orders from rolls
join (select customer_id,roll_id, count(roll_id) as orders
from customer_orders
group by customer_id, roll_id) as purchase on rolls.roll_id=purchase.roll_id
order by customer_id

--6. Maximum number of rolls delivered in a single order

with cte as (
select *, rank() over (order by purchase desc) as max_order from (
select cus.order_id, count(cus.roll_id) as purchase from customer_orders as cus
join
(select order_id from driver_order
where cancellation ='No') as orders
on cus.order_id= orders.order_id
group by cus.order_id) as a
)

select order_id,purchase from cte where max_order=1


 

