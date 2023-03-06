#CODEBASICS SQL CHALLENGE

SELECT * FROM dim_customer;
SELECT * FROM dim_product;
SELECT * FROM fact_gross_price;
SELECT * FROM fact_manufacturing_cost;
SELECT * FROM fact_pre_invoice_deductions;
SELECT * FROM fact_sales_monthly;

#REQUEST1
SELECT DISTINCT market
FROM dim_customer
WHERE customer='Atliq Exclusive' AND region='APAC';

#REQUEST2
WITH products AS 
(
SELECT fiscal_year, COUNT(DISTINCT Product_code) as unique_products 
FROM fact_gross_price 
GROUP BY fiscal_year
)
SELECT 
up_2020.unique_products AS unique_products_2020,
up_2021.unique_products AS unique_products_2021,
ROUND((up_2021.unique_products - up_2020.unique_products)/up_2020.unique_products * 100,2) AS percentage_change
FROM products AS up_2020
CROSS JOIN products AS up_2021
WHERE up_2020.fiscal_year = 2020 AND up_2021.fiscal_year = 2021;

#REQUEST3
SELECT segment,COUNT(DISTINCT product_code) AS Total_Count
FROM dim_product
GROUP BY segment
ORDER BY Total_Count DESC;

#REQUEST4
WITH unique_products AS (
SELECT P.segment, S.fiscal_year, COUNT(DISTINCT S.product_code) AS unique_products 
FROM fact_sales_monthly AS S 
JOIN dim_product AS P
ON S.product_code=P.product_code
GROUP BY 
segment, fiscal_year
)
SELECT 
up_2020.segment, 
up_2020.unique_products AS product_count_2020, 
up_2021.unique_products AS product_count_2021, 
up_2021.unique_products - up_2020.unique_products AS difference
FROM unique_products AS up_2020 
JOIN unique_products AS up_2021 
ON up_2020.segment = up_2021.segment 
WHERE up_2020.fiscal_year = 2020 AND up_2021.fiscal_year = 2021
ORDER BY difference DESC;

#REQUEST5       
SELECT C.product_code,P.product,C.manufacturing_cost
FROM dim_product AS P
JOIN fact_manufacturing_cost AS C
ON P.product_code=C.product_code
WHERE C.manufacturing_cost=(SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost)
OR C.manufacturing_cost=(SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost);

#REQUEST6
SELECT C.customer_code,C.customer,ROUND(AVG(I.pre_invoice_discount_pct),4) AS Average_Discount_Percentage
FROM fact_pre_invoice_deductions AS I
JOIN dim_customer AS C
ON I.customer_code=C.customer_code
WHERE I.fiscal_year=2021 AND C.market='India'
GROUP BY C.customer_code,C.customer
ORDER BY Average_Discount_Percentage DESC 
LIMIT 5;

#REQUEST7
SELECT MONTHNAME(S.date) AS Month,YEAR(S.date) AS Year,
CONCAT('$',ROUND(SUM(G.gross_price * S.sold_quantity)/1000000, 2),'M') AS gross_sales_amount
FROM fact_sales_monthly AS S
JOIN dim_customer AS C
ON S.customer_code=C.customer_code
JOIN fact_gross_price AS G
ON S.product_code=G.product_code
WHERE customer='Atliq Exclusive'
GROUP BY Month,Year
ORDER BY Year;

#REQUEST8
SELECT CASE
WHEN monthname(date) IN ('September','October','November') THEN 'Q1'
WHEN monthname(date) IN ('December','January','February') THEN 'Q2'
WHEN monthname(date) IN ('March','April','May') THEN 'Q3'
WHEN monthname(date) IN ('June','July','August') THEN 'Q4'
END AS Quarter,ROUND(SUM(sold_quantity)/1000000,2) AS Total_Sold_Quantity_In_MIllions
FROM fact_sales_monthly
WHERE fiscal_year=2020
GROUP BY Quarter
ORDER BY Total_Sold_Quantity_In_MIllions DESC;

#REQUEST9
WITH CTE AS 
(
SELECT C.channel,
ROUND(SUM(G.gross_price*S.sold_quantity)/1000000,2)
AS gross_sales_mln
FROM fact_sales_monthly AS S
JOIN dim_customer AS C
ON S.customer_code = C.customer_code
JOIN fact_gross_price AS G
ON G.product_code = S.product_code
WHERE S.fiscal_year = 2021
GROUP BY C.channel 
ORDER BY gross_sales_mln DESC
)
SELECT *,ROUND((gross_sales_mln*100)/sum(gross_sales_mln)
OVER(),2) AS Percentage
FROM CTE;

#REQUEST10
WITH CTE AS 
(SELECT P.division,S.product_code,P.product,
SUM(S.sold_quantity) AS Total_Sold_Quantity,
DENSE_RANK() OVER(PARTITION BY P.division ORDER BY SUM(S.sold_quantity) DESC) AS Rank_Order
FROM dim_product AS P
JOIN fact_sales_monthly AS S
ON P.product_code=S.product_code
WHERE S.fiscal_year=2021
GROUP BY P.division,S.product_code,P.product)
SELECT * FROM CTE
WHERE Rank_Order<=3;