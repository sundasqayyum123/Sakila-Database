-- Problem_01: What are the highest and least demand movies category-wise?

USE sakila;

SELECT 
	c.name AS category,
    COUNT(DISTINCT cu.customer_id) AS Times_rented
FROM category AS c
INNER JOIN film_category AS fc
	ON c.category_id = fc.category_id
INNER JOIN film AS f
    ON fc.film_id = f.film_id
INNER JOIN inventory AS i
    ON f.film_id = i.film_id
INNER JOIN rental AS r
	ON i.inventory_id = r.inventory_id
INNER JOIN customer AS cu
	ON r.customer_id = cu.customer_id
GROUP BY category
ORDER BY Times_rented DESC;


-- Problem_02: What is the return time for rented films? 

WITH Return_table AS 
(
SELECT 
CASE
	WHEN rental_duration > DATEDIFF(return_date, rental_date) THEN "Returned early"
    WHEN rental_duration = DATEDIFF(return_date, rental_date) THEN "Returned on time"
    WHEN return_date IS NULL AND rental_duration > DATEDIFF(r.last_update, rental_date) THEN "In transit"
    WHEN return_date IS NULL AND rental_duration < DATEDIFF(r.last_update, rental_date) THEN "Bad returns"
    ELSE "Returned late"
    END AS Return_Status
FROM rental AS r
INNER JOIN inventory
	USING(inventory_id)
INNER JOIN film
	USING(film_id)
)
SELECT
	Return_Status,
    COUNT(*) AS Total_num_of_rentals
FROM Return_table
GROUP BY Return_Status
ORDER BY 2 DESC;


-- Problem_03: In which countries do Sakila DVD gives rental services, number of customers in that particular country. 
-- And which country generates highest sales? 

SELECT
    country, 
    COUNT(DISTINCT customer_id) AS clientele,
    SUM(amount) AS sales
FROM country
LEFT JOIN city
	USING(country_id)
LEFT JOIN address
	USING(city_id)
LEFT JOIN customer
	USING(address_id)
LEFT JOIN payment
	USING(customer_id)
GROUP BY country
ORDER BY clientele DESC;


-- Problem_04: Identify the top 3 customers per total sales and extract their details for rewarding those customers.

WITH Top_customers AS
(
SELECT
	DENSE_RANK() OVER (ORDER BY SUM(amount) DESC) AS Top_3,
    first_name, 
    last_name, 
    phone, 
    email, 
    city, 
    country,
    SUM(amount) AS purchases
FROM country
LEFT JOIN city
	USING(country_id)
LEFT JOIN address
	USING(city_id)
LEFT JOIN customer
	USING(address_id)
LEFT JOIN payment
	USING(customer_id)
GROUP BY 2,3,4,5,6,7
)
SELECT *
FROM Top_customers
WHERE Top_3 IN (1,2,3);


-- Problem 05: Where are the company’s stores?

select store.store_id, country.country , count(customer_id) as Total_number_of_customers from store
join address using ( address_id)
join city using (city_id)
join country using (country_id)
join customer using (store_ID)
group by store.store_id, country.country;



-- Problem 06: What are the most profitable movie categories?

select category.name as categories, count(distinct customer.customer_id) as Most_Demanded, sum(payment.amount) as Total_sale
from category
join film_category on film_category.category_id=category.category_id
join film on film.film_id= film_category.film_id
join inventory on film.film_id= inventory.film_id
join rental on inventory.inventory_id= rental.inventory_id
join customer on rental. customer_id= customer.customer_id
join payment on rental.rental_id= payment.rental_id
group by 1
order by 2 desc;

-- Problem 07 : What is the average rental rate for each categories?

select name as categories , avg(film.rental_rate) as avg_rental_rate
from category
join film_category
using (category_id)
join film
using (film_id)
group by 1
order by 2 desc;

-- Problem 08 : Select actors with most rented movies.

SELECT first_name, last_name, count(*) films
FROM actor AS a
JOIN film_actor AS fa USING (actor_id)
GROUP BY actor_id, first_name, last_name
ORDER BY films DESC
limit 10;


-- Problem_09: What are the total sales for each store? 

USE sakila;

SELECT 
	store_id,
    SUM(amount) as total_sales
FROM store 
LEFT JOIN staff
	USING (store_id)
LEFT JOIN payment p
	USING (staff_id)
GROUP BY store_id


-- Problem_10: Calculate the total sales per month for each store? 

SELECT
    DATE_FORMAT(p.payment_date, '%Y-%m') as month_year,
    s.store_id,
    SUM(p.amount) as total_sales,
    RANK() OVER (ORDER BY SUM(p.amount) desc) as sales_rank
from payment p
join rental r on p.rental_id = r.rental_id
join inventory i on r.inventory_id = i.inventory_id
join store s on i.store_id = s.store_id
group by DATE_FORMAT(p.payment_date, '%Y-%m'), store_id;


-- Problem_11: Measure the rate at which customers stop using services.


with week_customers as (
select 
customer_id,
dense_rank() over(partition by customer_id order by rental_date asc) order_rank,  
week(rental_date) as rental_week,  
lag(week(rental_date),1) over (partition by customer_id) as previous_rent_week, 
week(rental_date) - lag(week(rental_date),1) over (partition by customer_id) as diff_week 
from rental 
where year(rental_date) != '2006' 
) 
 ,
  _list as (
 select 
rental_week,
count(distinct customer_id) as total_customers,
count(distinct case when order_rank=1 then customer_id end) as new_customers,
count(distinct case when diff_week=1 or diff_week=2 then customer_id end) as retain_customers,
-- count(distinct if(rental_week IN (24,27,30,33),
--    case when diff_week=2 then customer_id end,
--     case when diff_week=1 then customer_id end))as retain_customers,
count(distinct case when diff_week>2 then customer_id end) as returning_customers,
lag(count(distinct customer_id) , 1) over(order by rental_week) prev_week_customer 
from week_customers
group by rental_week 
)
select * ,
retain_customers*100/prev_week_customer as retention_rate, 
100- (retain_customers*100/prev_week_customer) as churn_rate 
from _list;



-- Problem_12: Identify the peak dates in each month when most rentals occur.

with count_rentals as (
    select date(rental_date) as rental_date, COUNT(rental_id) as rental_count
    from rental
    group by date(rental_date)
),
count_rank as (
    select rental_date, rental_count,
	row_number() OVER (PARTITION BY date_format(rental_date, '%Y-%m') ORDER BY rental_count DESC) as ranking
    from count_rentals
)
select
rental_date as peak_date, date_format(rental_date, '%Y-%m') as month_year, rental_count
from count_rank
where ranking = 1 AND rental_date != '2006-02-14'
order by rental_date;






