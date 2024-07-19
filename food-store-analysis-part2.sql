---7. for each customer,how many delivered rolls had additional chages to items and how many did not
select * from customer_orders

update customer_orders
set not_include_items=0
where not_include_items in ('','NaN') or not_include_items is null


--update customer_orders
--set extra_items_included=0
--where extra_items_included in ('','NaN') or extra_items_included is null


select a.customer_id, 'changed' as change_or_nochange, count(a.roll_id) as orders from 
(
select cus.order_id,cus.customer_id, cus.not_include_items,cus.extra_items_included, cus.roll_id from customer_orders as cus
join
(select order_id from driver_order
where cancellation ='No') as deliver on cus.order_id=deliver.order_id) as a
where not_include_items <> '0' or extra_items_included <>'0'
group by customer_id 

union 

select a.customer_id, 'no change' as change_or_nochange,count(a.roll_id) as orders from 
(
select cus.order_id,cus.customer_id, cus.not_include_items,cus.extra_items_included, cus.roll_id from customer_orders as cus
join
(select order_id from driver_order
where cancellation ='No') as delivered on cus.order_id=delivered.order_id) as a
where not_include_items ='0' and extra_items_included ='0'
group by customer_id 

select * from customer_orders

--8. How many rolls were delivered that had both inclusion and exclusion of items

select count(roll_id) as rolls_with_both_changes   from (
select cus.order_id,cus.customer_id, cus.not_include_items,cus.extra_items_included, cus.roll_id from customer_orders as cus
join
(select order_id from driver_order
where cancellation ='No') as delivered on cus.order_id=delivered.order_id
where cus.not_include_items<>'0' and cus.extra_items_included<>'0') as a

---------------Another way of doing the above query
select order_customization, count(roll_id) as num_rolls from
(select cus.order_id,cus.customer_id, cus.not_include_items,cus.extra_items_included, cus.roll_id, case when (not_include_items<>'0' and extra_items_included<> '0')
then 'both changes'
when (not_include_items<>'0' or extra_items_included<> '0') then 'one change'
else 'no change' end as order_customization
from customer_orders as cus
join
(select order_id from driver_order
where cancellation ='No') as delivered on cus.order_id=delivered.order_id) as final_tbl
group by order_customization


--9. During which hours there are more number of rolls ordered, do not consider the day just the hour
--To see which time the customers are more active

select hour_bins, count(roll_id) as orders from (
select *, concat((cast(datepart(hour, order_date) as varchar )),'-' ,(cast (datepart(hour, order_date)+1 as varchar) ) ) as hour_bins from customer_orders) as a
group by hour_bins
order by orders desc

-- 13-14 , 18-19 , 21-22 and 23-24 these timings have more orders

--10. What is the number of orders in each day of the week?

select day_of_week, count(distinct order_id) as orders from (
select *, datename(DW, order_date) as day_of_week from customer_orders)
as order_count
group by day_of_week

--11. What is the average time in minutes it took the driver to drive at the food center and pick up the order?

select driver_id, AVG(pickup_time_minutes) as avg_pickuptime from
(select *, ROW_NUMBER() over(partition by order_id order by pickup_time_minutes desc ) as ranking  from
(select cus.order_id,drivers.driver_id, DATEDIFF(MINUTE,order_date,pickup_time) as pickup_time_minutes from driver_order as drivers
join customer_orders as cus
on drivers.order_id =cus.order_id 
where pickup_time is not null) as avg_pickup_time) as a
where ranking=1
group by driver_id

--12. Is there any relationship between number of rolls and time taken to prepare the order?

select order_id, count(roll_id) as num_of_rolls, sum(pickup_time_minutes)/count(roll_id) as total_time from
(select cus.order_id,cus.roll_id, DATEDIFF(MINUTE,order_date,pickup_time) as pickup_time_minutes from driver_order as drivers
join customer_orders as cus
on drivers.order_id =cus.order_id 
where pickup_time is not null) as avg_pickup_time
group by order_id
order by num_of_rolls

--13. What is the average distance traveled for each of the customer?
--Remove the multiple order ids since the duration is for overall order not for one item, data cleaning for distance column and then calculate average on  distance grouped by customer_id

select c.customer_id, avg(c.distance_km) as avg_distance_travelled_km from
(select b.*, cast(trim(REPLACE(distance, 'km', '')) as float) as distance_km from 
(select a.*, row_number() over(partition by order_id order by (select null) ) as ranking from (
select cus.order_id,customer_id, distance from driver_order as orders
join customer_orders as cus on orders.order_id =cus.order_id
where pickup_time is not null) as a
) as b
where ranking=1) as c
group by c.customer_id
order by avg_distance_travelled_km

--14. What is the difference between the longest and shortest delivery time for all the orders

select max(a.delivery_duration)as max_duration, min(a.delivery_duration) as min_duration
from (
select *,case when duration like '%min%' then trim(left(duration, CHARINDEX('m', duration)-1)) else duration 
end as delivery_duration
from driver_order
where duration is not null
) as a

--15. what is the average speed of each driver for each delivery and do you notice any trends in the values
--- speed = distance / time

select driver_id, avg(distance_km/delivery_duration) as speed from
(select a.*, row_number() over(partition by order_id order by (select null) ) as ranking from (
select cus.order_id,customer_id, driver_id, cast(trim(REPLACE(distance, 'km', '')) as float) as distance_km, case when duration like '%min%' then trim(left(duration, CHARINDEX('m', duration)-1)) else duration 
end as delivery_duration from driver_order as orders
join customer_orders as cus on orders.order_id =cus.order_id
where pickup_time is not null) as a)
as b
where ranking =1
group by driver_id

--16.. successfull delivery percentage for each driver
select b.*,(successfull_deliveries*1.0/total_deliveries)*100  as sucess_rate from 
(select driver_id, count(status) as total_deliveries , sum(status) as successfull_deliveries from
(
select *, case when cancellation <>'No' then 0 else 1 end as status
from driver_order) as a
group by driver_id
) as b
