-----Senior most employee

select top 1* from employee
order by levels desc

--Countries having the most number of invoices

select count(invoice_id) as invoices, billing_country from  invoice 
group by billing_country
order by count(invoice_id) desc

--- Top 3 Sales values in invoices

select top 3 total from invoice
order by total desc

----Which city has the best customers accroding to revenue ?
--Return City name and sum of invoice totals
select sum(total) as Revenue, billing_city from invoice
group by billing_city
order by sum(total) desc

------ Customers who has spend the most amount
select top 1 cus.customer_id ,first_name, last_name, sum(total) as amount from customer as cus
join invoice as inv on
cus.customer_id=inv.customer_id
group by  cus.customer_id,first_name, last_name
order by amount desc

-----------return email, first name , last name of all rock music listeners, order by email in asc
select  distinct email, first_name, last_name from customer as cus
join invoice as inv on cus.customer_id=inv.customer_id 
where invoice_id in (
select invoice_id from invoice_line where invoice_id in (
select track_id from track where genre_id in (
select genre_id from genre
where name = 'Rock')))

order by email asc

-----Artists who have written the most rock music
--Return top 10 artist name and their track count 

select top 10 art.name as Name, count(trk.track_id) as Tracks from artist as art
join album as alb on art.artist_id=alb.artist_id 
join track as trk on alb.album_id=trk.album_id
join genre as gn on trk.genre_id= gn.genre_id 
where gn.name ='Rock'

group by art.name
order by Tracks desc

----Return name and length of Tracks with songs length longer than avg song length, order by song length desc
select name, milliseconds from track
where milliseconds >(select avg(milliseconds) as avg_length from track)
order by milliseconds desc

----how much money spend by each customer on top best selling artist
--return customer name, artist name and money spend

--First create a cte that contains shows the top selling artist

with best_artist as (
select top 1 artist.artist_id as ID, artist.name as Name, sum (invoice_line.unit_price*invoice_line.quantity) as Total_Sales from artist
join album on artist.artist_id=album.artist_id
join track on album.album_id =track.album_id
join invoice_line on track.track_id =invoice_line.track_id
group by artist.artist_id, artist.name
order by Total_Sales desc
)

---Using the CTE find all the customers who contributed to the best selling artist's Sales
select customer.customer_id, customer.first_name,customer.last_name, best_artist.Name,sum(invoice_line.unit_price*invoice_line.quantity) as amount_spend from customer 
join invoice on customer.customer_id=invoice.customer_id
join invoice_line on invoice.invoice_id= invoice_line.invoice_id
join track on invoice_line.track_id = track.track_id
join album on track.album_id =album.album_id
join best_artist on album.artist_id=best_artist.ID
group by customer.customer_id,customer.first_name,customer.last_name, best_artist.Name
order by amount_spend desc

---Find most popular genre of each country, genre with the most sales is the popular one
--Return Country, genre

with country_genre as (
select inv.billing_country as country ,genre.name as genre , COUNT(*) as purchase_count, ROW_NUMBER() over(partition by inv.billing_country order by count(*) desc) as row_num
from invoice as inv
join invoice_line as inv_ln on inv.invoice_id=inv_ln.invoice_id
join track on inv_ln.track_id =track.track_id
join genre on track.genre_id =genre.genre_id
group by inv.billing_country,genre.name
--order by country --(works only when there is top, offset or xml)
)

select country, genre, purchase_count from country_genre
where row_num =1 

---------customer who have spend the most on music from each country
---Return country, top customer and amount spend


with customer_spending as(
select customer.customer_id,first_name,last_name,customer.country, sum(invoice.total) as amount, ROW_NUMBER() over(partition by customer.country order by sum(invoice.total) desc ) as row_num

from customer
join invoice on customer.customer_id=invoice.customer_id
group by customer.customer_id,first_name,last_name,customer.country
--order by customer.country
)

--Highest spending customers from each country
select country,first_name, last_name, amount from customer_spending
where row_num =1
