
--use TCDS
--;With dataA  (Product,cost,sum_rows_for_cost,sum_rows_for_product) as
--(
--select p.Product, cost
--	 , count(*) as sum_rows_for_cost
--	 , max(sum_rows_for_product) as sum_rows_for_product
--	 --, max(sum_rows_for_product)/count(*) as ratio
--FROM [TCDS].[dbo].[Data] as p
--left join (select Product, count(*) as sum_rows_for_product FROM [TCDS].[dbo].[Data] group by Product) as pr on pr.Product=p.Product
----where p.Product in ('7290000059259')
--group by p.Product, cost
--),  
--dataB (Product, cost, sum_rows_for_cost, sum_rows_for_product, max_rows_for_product) as
--(
--select Product, cost, sum_rows_for_cost, sum_rows_for_product
--     , max(sum_rows_for_cost) over (partition by Product) as max_rows_for_product
--  --   , max(sum_rows_for_product) as max_rows_for_product_2  
--	 --, min(ratio)
--from dataA 
--),
--Product_Price (Product, Standart_Price) as
--(
--select Product, cost as Standart_Price  --- sum_rows_for_cost, sum_rows_for_product , cost*sum_rows_for_product
--from dataB 
--where sum_rows_for_cost=max_rows_for_product --and Product in ('7290000059259')
--)
--select * 
----into Standart_Price
--from Product_Price


--select top 1000* from Standart_Price

--alter table [dbo].[Data] alter column [Month] varchar (20)
------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------
--select * from data as d where  d.Product='17' and d.Customer=416000001 order by Weeknum
--select * from  [dbo].[Weeknum]
--select * from [dbo].[Product for Pred]
use TCDS
;With Quantity_Y (Weeknum,Weeknum_1,Product, Customer, Sum_Quantity,Avg_Cost) as
(
select  d.Weeknum, d.Weeknum-1 as Weeknum_1, d.Product, d.Customer
     , sum(case when d.quantity is null then 0 else d.quantity end) as Sum_Quantity
	 , avg(case when d.cost is null then 0 else d.cost end)         as Avg_Cost
from Data as d
where    d.Product in (select Product from [dbo].[Product for Pred] group by Product) 
 --    and d.Product='17' and d.Customer=416000001
group by d.Weeknum, d.Product, d.Customer
--order by d.Weeknum
), Total_Quantity (Product, Customer,Total_Quantity) as
(
select  d.Product, d.Customer
     , sum(case when d.quantity is null then 0 else d.quantity end) as Total_Quantity
from Data as d
where    d.Product in (select Product from [dbo].[Product for Pred] group by Product) 
     and d.Weeknum in (select Weeknum from [dbo].[Weeknum] group by Weeknum)
   -- and d.Product='7290000211503' and d.Customer=416000100
group by d.Product, d.Customer
) --select * from Total_Quantity
, Quantity_Y_union (Weeknum, Product, Customer) as
(
select q.Weeknum, q.Product, q.Customer 
from 
(select Weeknum   as Weeknum, Product, Customer from Quantity_Y
 union all
 select Weeknum_1 as Weeknum, Product, Customer from Quantity_Y) as q
group by q.Weeknum, q.Product, q.Customer
) --select * from Quantity_Y_union
, Quantity (Weeknum, Product, Customer,Sum_Quantity,Avg_Cost,Sum_Quantity_1,Avg_Cost_1,Sum_Quantity_1_minus_Sum_Quantity,Avg_Quantity_for_Week,Avg_Quantity_for_PO,all_week,count_week_PO) as
(
select q.Weeknum, q.Product, q.Customer
     , sum(case when d.quantity     is null then 0 else d.quantity end)             as Sum_Quantity
	 , max(case when d.Cost         is null then 0 else d.Cost end)                 as Avg_Cost
	 , max(case when y.Sum_Quantity is null then 0 else y.Sum_Quantity end)         as Sum_Quantity_1
	 , max(case when y.Avg_Cost     is null then 0 else y.Avg_Cost end)             as Avg_Cost_1
	 , sum(case when y.Sum_Quantity is null then 0 else y.Sum_Quantity end) - sum(case when d.quantity is null then 0 else d.quantity end)   as Sum_Quantity_1_minus_Sum_Quantity
	 , case when (max(q.Weeknum) over (partition by q.Product, q.Customer)-min(q.Weeknum) over (partition by q.Product, q.Customer)) >0 then max(Total_Quantity)/(max(q.Weeknum) over (partition by q.Product, q.Customer)-min(q.Weeknum) over (partition by q.Product, q.Customer)) else 0 end as Avg_Quantity_for_Week
	 , case when sum(case when sum(case when d.quantity is null then 0 else d.quantity end)>0 then 1 end) over (partition by q.Product, q.Customer)>0 then max(Total_Quantity)/sum(case when sum(case when d.quantity is null then 0 else d.quantity end)>0 then 1 end) over (partition by q.Product, q.Customer) else 0 end as Avg_Quantity_for_PO 
	 ,(max(q.Weeknum) over (partition by q.Product, q.Customer)-min(q.Weeknum) over (partition by q.Product, q.Customer)) as all_week
	 , sum(case when sum(case when d.quantity is null then 0 else d.quantity end)>0 then 1 end) over (partition by q.Product, q.Customer) as count_week_PO
from Quantity_Y_union as q
left join [dbo].[Data]    as d on d.Weeknum  =q.Weeknum and d.Product=q.Product and d.Customer=q.Customer
left join Quantity_Y      as y on y.Weeknum_1=q.Weeknum and y.Product=q.Product and y.Customer=q.Customer
left join Total_Quantity  as t on                           t.Product=q.Product and t.Customer=q.Customer
where q.Weeknum in (select Weeknum from [dbo].[Weeknum] group by Weeknum)
group by q.Weeknum, q.Product, q.Customer
having sum(case when d.quantity is null then 0 else d.quantity end) +sum(case when y.Sum_Quantity is null then 0 else y.Sum_Quantity end) >0
) --select * from Quantity
, Total_Q (Customer,Total_Quantity_for_Customer,Total_Quantity) as
(
select d.Customer
     , sum(d.quantity) as Total_Quantity_for_Customer, max(Total_Quantity) as Total_Quantity
from Data as d
left join (select year, sum(quantity) as Total_Quantity from Data group by year) as t on t.year=d.year
group by d.Customer
),
Final_Table  ( Weeknum, Product, Customer,Sum_Quantity,Avg_Cost,Sum_Quantity_1,Avg_Cost_1,Sum_Quantity_1_minus_Sum_Quantity,Avg_Quantity_for_Week,Avg_Quantity_for_PO,all_week,count_week_PO
              ,Standart_Price,Upper_Standart_Price,Under_Standart_Price,Total_Quantity_for_Customer,Total_Quantity,Holiday,Temp_Hi,Temp_Lo,Temp_Rain) as
(
select  q.Weeknum, q.Product, q.Customer,Sum_Quantity,Avg_Cost,Sum_Quantity_1,Avg_Cost_1,Sum_Quantity_1_minus_Sum_Quantity,Avg_Quantity_for_Week,Avg_Quantity_for_PO,all_week,count_week_PO
      , max(sp.Standart_Price) as Standart_Price
	  , case when Avg_Cost>max(sp.Standart_Price) then 1 else 0 end as Upper_Standart_Price, case when Avg_Cost<max(sp.Standart_Price) then 1 else 0 end as Under_Standart_Price 
      , max(Total_Quantity_for_Customer) as Total_Quantity_for_Customer, max(Total_Quantity) as Total_Quantity
	  , max(case when hol.Weeknum is not null then 1 else 0 end) as Holiday
	  , max(Temp_Hi) as Temp_Hi, max(Temp_Lo) as Temp_Lo, max(Temp_Rain) as Temp_Rain
from Quantity as q
left join Standart_Price as sp on sp.Product=q.Product
left join Total_Q on q.Customer=Total_Q.Customer 
left join (select DATEPART(week,date) as Weeknum, max(name) as Hol_Name from Holiday group by DATEPART(week,date)) as hol on hol.Weeknum=q.Weeknum
left join (select DATEPART(week,date) as Weeknum, avg(Hi) as Temp_Hi, avg(Low) as Temp_Lo, max(Rain) as Temp_Rain from weather2018 group by DATEPART(week,date)) as w on w.Weeknum=q.Weeknum
group by q.Weeknum, q.Product, q.Customer,Sum_Quantity,Avg_Cost,Sum_Quantity_1,Avg_Cost_1,Sum_Quantity_1_minus_Sum_Quantity,Avg_Quantity_for_Week,Avg_Quantity_for_PO,all_week,count_week_PO
) --select * from Final_Table

select   *
	  , case when Avg_Cost  >Standart_Price*1.5 or Avg_Cost  <Standart_Price*0.5 then Standart_Price else Avg_Cost   end as Avg_Price_Change
	  , case when Avg_Cost_1>Standart_Price*1.5 or Avg_Cost_1<Standart_Price*0.5 then Standart_Price else Avg_Cost_1 end as Avg_Price_Change_1
from Final_Table
--where  Product='17' and Customer=416000001 order by Weeknum
;

--select * from data as d where  d.Product='17' and d.Customer=416000001 order by Weeknum

