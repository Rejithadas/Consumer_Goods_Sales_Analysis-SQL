CODE BASICS DATA CHALLENGE 

select * from dim_customer;
select * from dim_product;
select * from fact_gross_price;
select * from fact_manufacturing_cost;
select * from fact_pre_invoice_deductions;
select * from fact_sales_monthly;

/* 1. Provide the list of markets in which customer  "Atliq  Exclusive"  operates its business in the  APAC  region. */
select distinct market 
from dim_customer 
where customer='Atliq Exclusive' and region='APAC';

/* 2. What is the percentage of unique product increase in 2021 vs. 2020? */
with unique_products_20 as (
select count(distinct product_code) as unique_products_2020
from fact_sales_monthly
where fiscal_year=2020),

unique_products_21 as (
select count(distinct product_code) as unique_products_2021
from fact_sales_monthly
where fiscal_year=2021)
select 
	unique_products_2020,
	unique_products_2021,
	round(((unique_products_2021-unique_products_2020)/unique_products_2020)*100,2) as percentage_chg
from unique_products_20,unique_products_21;

/* 3. Provide a report with all the unique product counts for each  segment  and sort them in descending order of product counts. */
select 
	segment,
    count(distinct product_code) as product_count
from  dim_product 
group by segment
order by product_count desc ;
    
/* 4. Which segment had the most increase in unique products in 2021 vs 2020? */
with product_count as (
select 
	p.segment,
    s.fiscal_year,
    count(distinct s.product_code) as product_count
from  dim_product p
join  fact_sales_monthly s 
	on p.product_code=s.product_code
group by p.segment,
    s.fiscal_year
    )
 select 
	pc_2020.segment,
    pc_2020.product_count as product_count_2020,
	pc_2021.product_count as product_count_2021,
    pc_2021.product_count-pc_2020.product_count as difference
from product_count pc_2020
join product_count pc_2021
	on pc_2020.segment=pc_2021.segment
where pc_2020.fiscal_year=2020 
		and pc_2021.fiscal_year=2021
order by difference desc ;

/* 5. Get the products that have the highest and lowest manufacturing costs. */
select 
	m.product_code,
    p.product,
	m.manufacturing_cost
from dim_product p 
join fact_manufacturing_cost m
	on p.product_code=m.product_code
where manufacturing_cost in ((select min(manufacturing_cost) from fact_manufacturing_cost),
							(select max(manufacturing_cost) from fact_manufacturing_cost));
                            
/* 6. Generate a report which contains the top 5 customers who received an average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the Indian  market. */
select 
	pre.customer_code,
	c.customer,
    round(avg(pre.pre_invoice_discount_pct),4) as average_discount_percentage
from dim_customer c
join fact_pre_invoice_deductions pre
	on c.customer_code=pre.customer_code
where c.market='India' 
		and pre.fiscal_year=2021
group by pre.customer_code,c.customer
order by average_discount_percentage desc
limit 5;

/* 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive”  for each month. */
select 
	monthname(s.date) as month,
	year(s.date) as year,
	concat('$',round(sum(g.gross_price*s.sold_quantity/1000000),2),'M') as gross_sales_amount
from fact_sales_monthly s
join fact_gross_price g
	on s.product_code=g.product_code and s.fiscal_year=g.fiscal_year
join dim_customer c
	on s.customer_code=c.customer_code
where c.customer='Atliq Exclusive'
group by month,year
order by year;

/* 8. In which quarter of 2020, got the maximum total_sold_quantity? */
select 
	case when month(date) in (9,10,11) then 'Q1'
		 when month(date) in (12,1,2) then 'Q2'
         when month(date) in (3,4,5) then 'Q3'
         else 'Q4' end as quarter,
	round((sum(sold_quantity)/1000000),2) as total_sold_quantity
from fact_sales_monthly
where fiscal_year=2020
group by quarter
order by total_sold_quantity desc ;

/* 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?  */
with channel_gs as (
select 
	channel,
    round((sum(gross_price*sold_quantity)/1000000),2) as gross_sales_mln 
from fact_sales_monthly s
join dim_customer c
	on s.customer_code=c.customer_code
join fact_gross_price g
	on s.product_code=g.product_code and s.fiscal_year=g.fiscal_year
where s.fiscal_year=2021
group by channel
)
select 
	*,
	round((gross_sales_mln)*100/sum(gross_sales_mln) over(),2) as percentage
from channel_gs
order by percentage desc; 

/* 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? */
with top_product as ( 
select 
	p.division,
    s.product_code,
    p.product,
    sum(sold_quantity) as total_sold_quantity,
    dense_rank() over(partition by p.division order by sum(sold_quantity) desc) as rank_order
from fact_sales_monthly s
join dim_customer c
	on s.customer_code=c.customer_code
join dim_product p
	on s.product_code=p.product_code
where s.fiscal_year=2021
group by division,s.product_code,p.product
)
select * from top_product
where rank_order<=3;
