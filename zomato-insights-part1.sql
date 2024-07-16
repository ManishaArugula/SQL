--Basic EDA 

---1. Get total amount spend by each user in zomato
select top 1* from sales
select top 1* from product

select userid,sum(price) as total_amt_spent from sales as s
join product as p on 
s.product_id =p.product_id
group by userid

---2. Display the number of times a customer has  visited the zomato website

select userid,count(created_date) as cust_visits from sales as s
group by userid
order by cust_visits

-- user 1 has made the most visists (7) followed by user3 (5) and then user2 (4)

--3. First product purchased by each customer
go

with first_orders as (
select  userid, s.product_id, p.product_name,p.price,s.created_date,ROW_NUMBER() over(partition by userid order by created_date) as row_num --- order by to show on what bases the ranks must be provided.
from sales as s
join product as p on 
s.product_id =p.product_id
)
select * from first_orders
where row_num =1
order by created_date 

--Insights ** product p1 is the first product purchased by all the customers.

--4a. Which is the most purchased item on the menue ?
go

select top 1 p.product_id, count(*) as purchase_cnt from product as p
join sales as s on 
p.product_id =s.product_id
group by p.product_id
order by purchase_cnt desc

-- product_id 2 has been purchased the most

--4b. How many times the most purchased item was purchased by all customers
select s.userid, count(*) as purchase_count from sales as s
where s.product_id = (
select top 1 p.product_id from product as p
join sales as s on 
p.product_id =s.product_id
group by p.product_id
order by count(*) desc)
group by s.userid

--User 1 and 3 have purchased this item the most

---5.Which is the favourite product of according to each customer?,


select * from (
select *, rank() over( partition by userid order by prod_cnt desc) prd_rank from
(select userid, product_id, count(product_id) as prod_cnt
from sales 
group by userid, product_id) as tbl_item_count
) as tbl_item_rank
where prd_rank =1

--product 2 is mostly liked by customers

