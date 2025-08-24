Create table city(
		city_id int primary key,
		city_name varchar(30),
		population int,
		estimated_rent int,
		city_rank int 
		)

Create table sales(
		sale_id int,
		sale_date date,
		product_id int,
		customer_id int,
		total int,
		rating int
		)

alter table sales
		add constraint fk_product_id
		foreign key (product_id)
		references product(product_id)

alter table sales
		add constraint fk_customer_id
		foreign key (customer_id)
		references customer(customer_id)

alter table sales add primary key (sale_id)

Create table product(
		product_id int primary key,
		product_name varchar(40),
		price int
		)

Create table customer(
		customer_id int,
		customer_name varchar(20),
		city_id int
		)

alter table customer add primary key (customer_id)

alter table customer
		add constraint fk_city_id
		foreign key (city_id)
		references city(city_id)

/* Q1.Coffee Consumers Count
How many people in each city are estimated to consume coffee, given that 25% of the population does*/

		select city_name,round((population*0.25)/1000000,2)
		as coffee_consumers_in_million,city_rank
		from city
		order by coffee_consumers_in_million desc

/*Q2.Total Revenue from Last Quarter of 2023
What is the total revenue generated from across all cities in the last quarter of 2023?*/

		select  *,
		extract (quarter from sale_date) as qtr,
		extract (year from sale_date)as year
		from sales
		where extract (year from sale_date) = '2023' and extract (quarter from sale_date) = '4'

/*Q3.Sales Count for Each Product
How many units of each coffee product have been sold?*/

		select product_id , count(*) as product_count
		from sales
		group by product_id
		order by product_count desc

/*Q4.Average Sales Amount per City
What is the average sales amount per customer in each city?*/

		select ct.city_name,round(avg(total),2) as Average_Sales
		from sales as s
		join customer as c on s.customer_id = c.customer_id
		join city as ct on ct.city_id = c.city_id
		group by 1
		order by Average_Sales desc

/*Q5.City Population and Coffee Consumers
Provide a list of cities along with their populations and estimated coffee consumers(25%).*/

		select ct.city_name, ct.population, count (ct.population*0.25) as estd_cof_csmrs
		from sales as s
		join customer as c on s.customer_id = c.customer_id
		join city as ct on ct.city_id = c.city_id
		group by 1,2
		order by estd_cof_csmrs desc

/*Q6.Top Selling Products by City
What are the top 3 selling products in each city based on sales volume?*/

with city_rank as 
		(select ct.city_name, p.product_name, count(s.sale_id) as no_of_products,
		dense_rank () over (partition by ct.city_name order by count(s.sale_id) desc) as ranks
		from sales as s
		join customer as c on s.customer_id = c.customer_id
		join product as p on p.product_id = s.product_id
		join city as ct on ct.city_id = c.city_id
		group by 1,2
		)
select * from city_rank
where ranks <= 3

/*Q7.Customer Segmentation by City
How many unique customers are there in each city who have purchased coffee products?*/

		select ct.city_name, count(distinct c.customer_id) as coffee_prod_cx
		from city as ct
		join customer as c on ct.city_id = c.city_id
		join sales as s on s.customer_id = c.customer_id
		join product as p on p.product_id = s.product_id
		where p.product_id between '1' and '14'
		group by 1
		order by 2 desc

/*Q8.Average Sale vs Rent
Find each city and their average sale per customer and avg rent per customer*/

with sales_avg 
		as
		(select ct.city_name, count(distinct c.customer_id) as unique_cx,
		sum (s.total)/count(distinct c.customer_id) as avg_sales
		from sales as s
		join customer as c on s.customer_id = c.customer_id
		join city as ct on ct.city_id = c.city_id
		group by 1
		order by 3 desc
		),
		city_rent
as
		(select city_name, estimated_rent
		from city)

				select cr.city_name,cr.estimated_rent,sa.unique_cx,sa.avg_sales,
				cr.estimated_rent/sa.unique_cx as avg_rent_per_cx
				from city_rent as cr
				join sales_avg as sa on sa. city_name = cr.city_name
				order by 4 desc


/*Q9.Monthly Sales Growth
Sales growth rate: Calculate the percentage growth (or decline) 
in sales over different time periods (monthly).*/

with monthly_sale as
	(
	select ct.city_name, 
	extract(month from sale_date) as months,
	extract(year from sale_date)as years,
	sum(s.total) as total_sale
	from sales as s
	join customer as c on c.customer_id = s.customer_id
	join city as ct on ct.city_id = c.city_id
	group by 1,2,3
	order by 1,3,2
	),
	
			growth_ratio as
			(select city_name, months, years,total_sale as current_month_sale,
				lag (total_sale,1) over (partition by city_name ) as last_month_sale
				from monthly_sale
				order by 1,3,2)

				select city_name,months,years,current_month_sale,last_month_sale,
				round(
				(current_month_sale-last_month_sale) ::numeric / last_month_sale ::numeric
				* 100,2) as percentage
				from growth_ratio
				where last_month_sale is not null

			
				
/* Q10.Market Potential Analysis
Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers,
estimated coffee consumer*/

	with unique_cx as
		(select ct.city_name, count(distinct c.customer_id) as unique_cx_customer,
		round((ct.population * 0.25)/1000000,2) as coffee_consumers,
		sum(s.total) as total_sale
		from sales as s
		join customer as c on s.customer_id = c.customer_id
		join city as ct on ct.city_id = c.city_id
		group by city_name,3
		order by total_sale desc),

		    rent as
			(select city_name, estimated_rent
			from city)

			select r.city_name, u.unique_cx_customer, u.total_sale, coffee_consumers,
			r.estimated_rent/u.unique_cx_customer as avg_rent
			from rent as r
			join unique_cx as u on r.city_name = u.city_name
			order by 3 desc