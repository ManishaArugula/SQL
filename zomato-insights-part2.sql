--6.Which item was first purchased after getting a gold membership
select * from goldusers_signup
select * from sales

--6a. get records for all those products purchased after a gold_signup
select s.userid,s.product_id, s.created_date,g.gold_signup_date from sales s
join goldusers_signup as g
on s.userid=g.userid
where created_date>=gold_signup_date

--6b The first prodcut purchased after a goldsignup

select * from 
(select *, rank() over(partition by userid order by created_date asc) as first_order from 
(select s.userid,s.product_id, s.created_date,g.gold_signup_date from sales s
join goldusers_signup as g
on s.userid=g.userid
where created_date>=gold_signup_date) as tbl_after_membership
) as orderd_sales
where first_order=1

--7. Which item was purchased juts before the user became the gold member
with latest_order as (
select s.userid,s.product_id, s.created_date,g.gold_signup_date, RANK() over(partition by s.userid order by created_date desc) as last_item from sales s
join goldusers_signup as g
on s.userid=g.userid
where created_date<gold_signup_date
)

select * from latest_order
where last_item =1

--8 . What is the total number of orders and total amount spend by the users before a gold memebership

select  userid, sum(price) as amount_spend, count(product_id) as num_orders from 
(select a.*, p.price from 
(select s.userid,s.product_id, s.created_date,g.gold_signup_date from sales s
join goldusers_signup as g on s.userid=g.userid
where created_date<gold_signup_date) as a
join product as p on a.product_id =p.product_id
) as b
group by userid

-- 9. If buying each product will generated 2 points, Example for every 5 rupees you will get 2 zomato points
--Each product has its own points, example -for p1(5rs = 1pts), p2(10rs =5 pts) p3(5rs =1pt) we can give p2(2rs =1pts) -- #If it is equated to 1 then it will be easier for dividing
go

with cte as (
select b.* , case (product_id) when 1 then 5 when 2 then 2 when 3 then 5 end as rupee_per_pts from
(select userid, product_id ,sum(price) as total_prod_price from
(select s.userid,s.product_id, p.price
from sales as s
join product p on s.product_id =p.product_id) as a
group by userid, product_id
) as b
)

select *, (total_prod_price/rupee_per_pts) as zomato_pts
from cte

--9b total points earned by each customer
select c.userid, sum(total_prod_price/rupee_per_pts) as total_zomato_pts from
(select b.* , case (product_id) when 1 then 5 when 2 then 2 when 3 then 5 end as rupee_per_pts from
(select userid, product_id ,sum(price) as total_prod_price from
(select s.userid,s.product_id, p.price
from sales as s
join product p on s.product_id =p.product_id) as a
group by userid, product_id
) as b
)c
group by userid

--9c which product earns the most points
select c.product_id, sum(total_prod_price/rupee_per_pts) as total_zomato_pts from
(select b.* , case (product_id) when 1 then 5 when 2 then 2 when 3 then 5 end as rupee_per_pts from
(select userid, product_id ,sum(price) as total_prod_price from
(select s.userid,s.product_id, p.price
from sales as s
join product p on s.product_id =p.product_id) as a
group by userid, product_id
) as b
)c
group by product_id
order by total_zomato_pts desc

---10. In first one year after the user joins the gold program(including the joining date), irrespective of what they have purchased they earn 5 pts for every 10 rs spend. How eaned more and what was their point earnings in first year?
--10rs -- 5pt ==> 2rs --1pt 

---Cannot add or subtract dates, use usdateadd
select a.*, p.price , (p.price/2) as zomato_pts from
(select  s.userid, s.created_date,s.product_id,g.gold_signup_date  from sales as s
join goldusers_signup as g on
s.userid = g.userid 
where (created_date>=gold_signup_date) and created_date<=(Dateadd(year, 1,gold_signup_date)) )as a
join product p on a.product_id =p.product_id

--11. rank all the transactions of all customers

select rank() over(partition by userid order by created_date asc) as trans ,*
from sales

--12. give a rank to all transactions for gold members for non- members return na


 select s.userid,created_date,product_id,gold_signup_date, 
 case  when gold_signup_date is null then 'NA' else cast(rank() over(partition by s.userid order by created_date) as varchar(5) )end
 as trans 
 from sales  as s
 left join goldusers_signup as g on
 s.userid=g.userid

