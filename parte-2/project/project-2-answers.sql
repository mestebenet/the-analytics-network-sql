--Create View viz. rder_sale_line as 
 with
 	sales as (	
	select 
	ols.date,
	extract(day from ols.date) as Day,
	extract(month from ols.date) as month,
    extract(year from ols.date) as year,
	case 	
		when ols.date BETWEEN '20210201' AND '20220131' then 'FY2021'
		when ols.date BETWEEN '20220201' AND '20230131' then 'FY2022' 	
			else 'FY2023' 
		end as fiscal_year_label,
	case 
		when extract(month from ols.date) in (2,3,4) then 'Q1'
		when extract(month from ols.date) in (5,6,7) then 'Q2'
		when extract(month from ols.date) in (8,9,10) then 'Q3'
		when extract(month from ols.date) in (11,12,1) then 'Q4'
		end as fiscal_quarter_label,
	ols.order_number,
	pm.product_code,
	pm.category,
	pm.subcategory,
	pm.subsubcategory,
	s.name as supplier_name,
	ols.store, 
	sm.country, 
	sm.province,
	sm.name as Nombre_Tienda,
	ols.is_walkout,
	ols.quantity,
	Sale as gross_sales,
	etl.convert_usd(currency,sale,date) as gross_sales_usd,
	coalesce (promotion,0)as promotion,
	coalesce (etl.convert_usd(currency,promotion,date),0) as promotion_USD,
	coalesce (tax,0) as tax,
	coalesce (etl.convert_usd(currency,tax,date),0) as tax_USD,
	coalesce (credit,0) as credit,
	coalesce (etl.convert_usd(currency,credit,date),0)as credit_USD,
	(product_cost_usd*ols.quantity)as sale_line_cost_usd
		FROM stg.order_line_sale ols
		left join stg.store_master sm on ols.store=sm.store_id 
		left join stg.product_master pm on ols.product=pm.product_code
		left join stg.suppliers s on ols.product=s.product_id
		left join stg.cost c on ols.product= c.product_code
		 where s.is_primary= 'True' 
	),
	
	adjusted_sale as (
	
	Select *,
	(gross_sales-promotion-credit)as net_sales,
	(gross_sales_usd-promotion_USD-credit_USD) as  net_sales_usd,
	(gross_sales-promotion-credit+tax) as amount_paid,
	(gross_sales_usd-promotion_USD-credit_USD+ tax_usd) as amount_paid_usd,
	(gross_sales_usd - sale_line_cost_usd) as gross_margin_usd,
	case
		when supplier_name LIKE '%Philips%' AND EXTRACT(YEAR FROM date) = 2022
		then (gross_sales_usd - sale_line_cost_usd -(20000/(SELECT sum(ols.quantity)
									FROM stg.order_line_sale ols
									LEFT JOIN stg.suppliers s ON ols.product = s.product_id
									WHERE s.name LIKE '%Philips%' AND EXTRACT(YEAR FROM ols.date) = 2022
									GROUP BY s.name)))
		when supplier_name LIKE '%Philips%' AND EXTRACT(YEAR FROM date) = 2023
		then (gross_sales_usd - sale_line_cost_usd -(5000/(SELECT sum(ols.quantity)
									FROM stg.order_line_sale ols
									LEFT JOIN stg.suppliers s ON ols.product = s.product_id
									WHERE s.name LIKE '%Philips%' AND EXTRACT(YEAR FROM ols.date) = 2023
									GROUP BY s.name)))
		else (gross_sales_usd - sale_line_cost_usd)
			  end as adjusted_gross_margin_usd
	
	 from sales	
	 )
	 
	 select adj.* ,
	 coalesce(r.quantity,0) as quantity_returned,
	 (coalesce(r.quantity,0)* amount_paid_usd) as amount_returned_usd,
	first_value (from_location) over(partition by r.return_id order by movement_id asc) as first_location,
	last_value (to_location) over(partition by r.return_id) as last_location 
	from adjusted_sale adj 
	left join stg.returns r on adj.product_code=r.itemcharacter
							and adj.date = r.date
							and adj.order_number= r.order_id
	
	
	
	
	

	
	
	
 				
