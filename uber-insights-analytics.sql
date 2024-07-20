select * from trips;
select * from trips_details4;
select * from loc;
select * from duration;
select * from payment;

--total trips
select count(*) from trips --contains all successfull trips

select count(*) from trips_details4 where end_ride=1 -- contains all the action trails/ searches made by the customer while booking a trip. It includes successfull, unsuccessfull and no action taken trips

---check if trip id is duplicate
select tripid, count(*) from trips_details4
group by tripid
order by count(*) desc

select tripid, count(*) from trips
group by tripid
order by count(*) desc

---number of distinct drivers
select count(distinct driverid) as total_drivers from trips
---total number of earnings
select sum(fare) as total_fare from trips

---total number of trips
select count(*) as total_trips from trips

--total_searches
select sum(searches) as total_searches 
from trips_details4

--total searches which got estimate (fare estimations)
select sum(searches_got_estimate) as total_search_estimates
from trips_details4
where searches=1

--total search for quotes (search for drivers)
select sum(searches_for_quotes) as total_search_quotes
from trips_details4
where searches=1 and searches_got_estimate=1

--total got quotes
select sum(searches_got_quotes) as total_quotes 
from trips_details4

---trips cancelled by driver
select count(driver_not_cancelled) as total_trips_cancelled_driver
from trips_details4
where driver_not_cancelled=0

--total otp enterred
select sum(otp_entered) as total_otp_enterred
from trips_details4

--total end_trip 
select sum(end_ride) as total_otp_enterred
from trips_details4

--avg distance per trip
select avg(distance) as avg_dist_trips
from trips

--avg fare per trip
select avg(fare) as avg_dist_trips
from trips


select pay.method,faremethod, count(faremethod) as total_number 
from trips join payment as pay 
on trips.faremethod=pay.id
group by pay.method,faremethod
order by total_number  desc

--The highest payment was done thrigh which method

select tripid,faremethod,pay.method, fare from trips
join payment as pay on trips.faremethod = pay.id
where fare in (
select max(fare) as highest_fare
from trips)

--Two locations which had the most number of trips (to_loc and from_loc)
select b.*, loc.assembly1 as to_address from loc
join
(select a.loc_from, (loc.assembly1) from_address , a.loc_to, total_trips from loc 
join
(select top 2 loc_from, loc_to, count(*) as total_trips from trips
group by loc_from, loc_to
order by total_trips desc) as a
on loc.id=a.loc_from ) as b on loc.id=b.loc_to

---top 5 earning drivers
select top 5 driverid, sum(fare) as total_fare from trips
group by driverid
order by total_fare desc

--ue dense_rank to get the above result this is beacuse there might me some drivers earning the same highest price

With cte as (
select *, DENSE_RANK() over(order by total_fare desc ) as ranking from(
select  driverid, sum(fare) as total_fare from trips
group by driverid) as a)

select * from cte where ranking<6

---Which (hour) duration has more trips?

select * from(
select a.*, RANK() over(order by total_trips desc) as ranking  from (
select duration, count(tripid) as total_trips 
from trips
group  by duration) as a) as b
where ranking=1

-- which customer and driver combinations were more
with cte as (
select *, DENSE_RANK() over(order by total_trips desc) as ranking
from(
select driverid, custid, count(tripid) as total_trips  from trips
group by driverid, custid) as a
)

select * from cte where ranking =1

--search to estimate rate
select sum(searches_got_estimate)*1.0/sum(searches)*100  as estimate_rate from trips_details4

--which area got highest number of trips and in which duration?( calculate only for loc_from)

select b.* from (
select a.*, DENSE_RANK() over (order by total_trips desc) as ranking
from (
select loc_from, duration, count(tripid) as total_trips from trips
group by loc_from, duration) as a
) as b
where ranking=1

--which areas have the highest trips and at what duration?( calculate only for loc_from)

select b.* from (
select a.*, rank() over (partition by loc_from order by total_trips desc) as ranking
from (
select loc_from, duration, count(tripid) as total_trips from trips
group by loc_from, duration) as a)
as b
where ranking=1

---Which area has got the highest fare, cancellation, trips?

--highest fare

with cte as (
select a.*, rank() over(order by total_fare desc) as ranking from 
(select loc_from, sum(fare) as total_fare from trips
group by loc_from) as a )

select * from cte where ranking=1

--customer cancellations
with cte as (
select a.*, rank() over(order by cus_cancellations desc ) as ranking from
(select  loc_from, count(customer_not_cancelled)as cus_cancellations from trips_details4
where customer_not_cancelled =0
group by loc_from) as a
)
select * from cte where ranking=1

--driver cancellations

with cte as (
select a.*, rank() over(order by driver_cancellations desc ) as ranking from
(select  loc_from, count(driver_not_cancelled)as driver_cancellations from trips_details4
where driver_not_cancelled =0
group by loc_from) as a
)
select * from cte where ranking=1

--highest number of trips 
with cte as (
select a.*, rank() over(order by total_trips desc) as ranking from 
(select loc_from, count(tripid) as total_trips from trips
group by loc_from) as a )

select * from cte where ranking =1

--- duration with highest fares
 select * from(
select a.*, rank() over(order by max_fare desc) as ranking from 
(select duration, max(fare) as max_fare from trips
group by duration) as a ) as b
where ranking=1

--- duration with highest trips
 select * from(
select a.*, rank() over(order by max_trips desc) as ranking from 
(select duration, count(tripid) as max_trips from trips
group by duration) as a ) as b
where ranking=1
