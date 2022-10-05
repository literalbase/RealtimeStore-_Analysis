select top 5
    *
from [dbo].[sales_data_sample]
select distinct status
from sales_data_sample
--Plot in power Bi
select distinct [YEAR_ID]
from sales_data_sample

select distinct [PRODUCTLINE]
from sales_data_sample

select distinct [COUNTRY]
from sales_data_sample

--Finding the sum of sales made on each Product
select [PRODUCTLINE], sum([SALES]) as revenue
--Visualize with a vertical bar chart 
from sales_data_sample
group by PRODUCTLINE
order by 2 DESC

--Finding the sum of sales made in each year
select [YEAR_ID], sum([SALES]) as revenue
--Visualize with a line graph
from sales_data_sample
group by [YEAR_ID]
order by 2 DESC

--Finding the sum of sales made on each deal 

select [DEALSIZE], sum([SALES]) as revenue
-- Visualize with a pie chart 
from sales_data_sample
group by [DEALSIZE]
order by 2 DESC

--- When was the best month  for sales in  a specific year 
select [MONTH_ID], SUM([SALES]) as revenue , count(ORDERLINENUMBER) as frequency
from sales_data_sample
where YEAR_ID=2003
group by MONTH_ID
order by 2 DESC

-- Since november seems to be the best month what product are they selling in november
select [MONTH_ID], PRODUCTLINE, SUM([SALES]) as revenue , count(ORDERLINENUMBER) as frequency
from sales_data_sample
where YEAR_ID=2003 and MONTH_ID = 11
group by MONTH_ID,PRODUCTLINE
order by 3 DESC;
--Checking authenticity
select CUSTOMERNAME, sum(SALES)
from sales_data_sample
where CUSTOMERNAME = 'Daedalus Designs Imports'
GROUP BY
CUSTOMERNAME
---Lets Perform an RFM analysis for who our best customers are and nthile
DROP TABLE IF EXISTS #rfm_analysis
with
    rfm_table
    AS
    (

        select [CUSTOMERNAME],
            SUM(SALES) as MonetaryValue, AVG(SALES) as AvgMonetaryValue,
            COUNT(ORDERNUMBER) as frequency,
            MAX(ORDERDATE) as last_order_date,
            (Select max(ORDERDATE)
            from sales_data_sample ) max_order_date,
            DATEDIFF(DD,max(ORDERDATE),  (Select max(ORDERDATE)
            from sales_data_sample )) as Recency
        from
            sales_data_sample
        group by [CUSTOMERNAME]
    ),
    rfm_calc
    as
    (

        select r.*,
            NTILE(4)OVER(ORDER BY Recency) rfm_recency,
            NTILE(4)OVER(ORDER BY frequency) rfm_frequency,
            NTILE(4)OVER(ORDER BY MonetaryValue) rfm_Monetary

        from rfm_table r
    )
select
    c.*, rfm_recency+rfm_frequency+rfm_Monetary as rfm_cell,
    CAST(rfm_recency as varchar) + CAST(rfm_frequency  as varchar) + CAST(rfm_Monetary  as varchar) as rfm_cell_string

INTO #rfm_analysis
from rfm_calc c;
select *
from #rfm_analysis

Select CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_Monetary,

    CASE
    When rfm_cell_string in (211,121,112,122,311) then 'Third class customers'
     When rfm_cell_string in (411,222,123,421,412,232,133,233,322,143,134) then 'Sencond Class customers'
      When rfm_cell_string in (432,333,243,144,244,344) then 'First Class Customers'
      END rfm_segment
from
    #rfm_analysis



--- Criteria according to rfm_cell
-- Using rank might be better
-- Next analysis is what product are often sold together
SELECT*
from
    (select distinct ORDERNUMBER, STUFF(

(select ','+ PRODUCTCODE
        from
            sales_data_sample p
        where  ORDERNUMBER IN (

select ORDERNUMBER
            from
                (

select ORDERNUMBER, COUNT(*) as rn
                from sales_data_sample
                where [STATUS] ='Shipped'
                GROUP BY
ORDERNUMBER
) x
            where 
rn=4
)
            AND p.ORDERNUMBER = s.ORDERNUMBER
        for XML PATH('')),1,1,'') productcodes
    FROM
        sales_data_sample s
)q
where 
productcodes is not null