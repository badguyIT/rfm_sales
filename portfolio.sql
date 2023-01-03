

SELECT * FROM dbo.sales_data_sample

--Check Unique Value
SELECT DISTINCT STATUS FROM dbo.sales_data_sample
SELECT DISTINCT sales_data_sample.YEAR_ID FROM dbo.sales_data_sample 
SELECT DISTINCT sales_data_sample.MONTH_ID FROM dbo.sales_data_sample WHERE sales_data_sample.YEAR_ID = 2003 ORDER BY sales_data_sample.MONTH_ID
SELECT DISTINCT sales_data_sample.PRODUCTLINE FROM dbo.sales_data_sample
SELECT DISTINCT sales_data_sample.COUNTRY FROM dbo.sales_data_sample

--analysis

SELECT sales_data_sample.PRODUCTLINE,
	   SUM(sales_data_sample.SALES) REVENUE
FROM dbo.sales_data_sample
GROUP BY sales_data_sample.PRODUCTLINE
ORDER BY 2 DESC


SELECT sales_data_sample.YEAR_ID,
	   SUM(sales_data_sample.SALES) REVENUE
FROM dbo.sales_data_sample
GROUP BY sales_data_sample.YEAR_ID
ORDER BY 2 DESC


SELECT sales_data_sample.DEALSIZE,
	   SUM(sales_data_sample.SALES) REVENUE
FROM dbo.sales_data_sample
GROUP BY sales_data_sample.DEALSIZE
ORDER BY 2 DESC

--best month for sales in a specific year?earned that month?

WITH best_month AS(
	SELECT sales_data_sample.MONTH_ID,
			SUM(sales_data_sample.SALES) REVENUE,
			COUNT(sales_data_sample.ORDERLINENUMBER) Frequency
	FROM sales_data_sample
	WHERE sales_data_sample.YEAR_ID=2004 --change year
	GROUP BY sales_data_sample.MONTH_ID
	--ORDER BY sales_data_sample.MONTH_ID  DESC
)
SELECT * FROM best_month ORDER BY MONTH_ID

-- November, What product they sell in Nov
SELECT sales_data_sample.MONTH_ID,
	   sales_data_sample.PRODUCTLINE,
	   SUM(sales_data_sample.SALES) REVENUE,
	   COUNT(sales_data_sample.ORDERNUMBER) COUNTT
FROM dbo.sales_data_sample
WHERE sales_data_sample.YEAR_ID=2004 AND sales_data_sample.MONTH_ID=11 --change year
GROUP BY sales_data_sample.MONTH_ID,sales_data_sample.PRODUCTLINE
ORDER BY 3 DESC


-- best custumer
DROP TABLE IF EXISTS #rfm;
WITH rfm AS (
	SELECT sales_data_sample.CUSTOMERNAME,
			SUM(sales_data_sample.SALES) MonteryValue,
			AVG(sales_data_sample.SALES) AVG_Value,
			COUNT(sales_data_sample.ORDERNUMBER) Frenquency,
			MAX(sales_data_sample.ORDERDATE) Last_OrderDare,
			(SELECT MAX(sales_data_sample.ORDERDATE) FROM dbo.sales_data_sample) AS max_order_date,
			DATEDIFF(DD,MAX(sales_data_sample.ORDERDATE),(SELECT MAX(sales_data_sample.ORDERDATE) FROM sales_data_sample)) Recency
	FROM dbo.sales_data_sample
	GROUP BY sales_data_sample.CUSTOMERNAME
),
rfm_calc AS (
	SELECT r.*,
			NTILE(4) OVER (ORDER BY Recency DESC) rfm_recency,
			NTILE(4) OVER (ORDER BY Frenquency) rfm_frequency,
			NTILE(4) OVER (ORDER BY MonteryValue) rfm_monetery
	FROM rfm r
)
SELECT c.*,
		rfm_recency + rfm_frequency + rfm_monetery AS rfm_cell,
		CAST(rfm_recency AS VARCHAR) + CAST(rfm_frequency AS VARCHAR) + CAST(rfm_monetery AS VARCHAR) rfm_cell_string
INTO #rfm
FROM rfm_calc c

SELECT * FROM #rfm;

SELECT CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetery,
	CASE 
		WHEN rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) THEN 'lost_customers'  --lost customers
		WHEN rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) THEN 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		WHEN rfm_cell_string in (311, 411, 331) THEN 'new customers'
		WHEN rfm_cell_string in (222, 223, 233, 322) THEN 'potential churners'
		WHEN rfm_cell_string in (323, 333,321, 422, 332, 432) THEN 'active' --(Customers who buy often & recently, but at low price points)
		WHEN rfm_cell_string in (433, 434, 443, 444) THEN 'loyal'
	END rfm_segment

FROM #rfm

-- What products are most often sold together?


SELECT DISTINCT s.ORDERNUMBER, 
				STUFF(
					(SELECT  ',' + s.PRODUCTCODE
					FROM dbo.sales_data_sample p
					WHERE ORDERNUMBER IN(
						SELECT s.ORDERNUMBER
						FROM(
							SELECT sales_data_sample.ORDERNUMBER, COUNT(*) rn
							FROM dbo.sales_data_sample
							WHERE sales_data_sample.STATUS = 'Shipped'
							GROUP BY sales_data_sample.ORDERNUMBER
							) m
							WHERE rn = 3
						)
						AND p.ORDERNUMBER = s.ORDERNUMBER
						FOR XML PATH('')
					),
					1,1,''
				) ProductCodes
FROM dbo.sales_data_sample s
ORDER BY 2 DESC

--what is the best product in US

SELECT sales_data_sample.COUNTRY,
		sales_data_sample.YEAR_ID,
		sales_data_sample.PRODUCTLINE,
		SUM(sales_data_sample.SALES) Revenue
FROM dbo.sales_data_sample
WHERE sales_data_sample.COUNTRY = 'USA'
GROUP BY sales_data_sample.COUNTRY,sales_data_sample.YEAR_ID,sales_data_sample.PRODUCTLINE
ORDER BY 4 DESC


