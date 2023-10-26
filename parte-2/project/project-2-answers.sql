CREATE TABLE IF NOT EXISTS stg.shrinkage (
  	year numeric,
  	store_id smallint,
	item_id character varying(10),
	quantity integer
);

COPY stg.shrinkage FROM 'C:\Users\Public\shrinkage.csv' DELIMITER ',' CSV HEADER;

select * from stg.shrinkage

CREATE SCHEMA IF NOT EXISTS viz
    AUTHORIZATION postgres;
	

CREATE OR REPLACE VIEW viz.order_sale_line
 AS


with aux_egresos as (
	select sh.year,sh.store_id, sh.item_id,sh.quantity, c.product_cost_usd, 
		sh.quantity*c.product_cost_usd as egreso_total
	from stg.shrinkage sh
	left join stg.cost c
		on c.product_code = sh.item_id
	order by sh.year,sh.store_id,sh.item_id
	
), 


aux_philips as (
	select
		ols.order_number,pm.brand,
		extract (year from date) as year,
		sum(quantity) over(partition by extract (year from date)),
		case
			when extract (year from date) = 2022 then 20000
			when extract (year from date) = 2023 then 5000
			end as total_extra, 
		case
			when extract (year from date) = 2022 then (20000/(((sum(quantity) over(partition by extract (year from date))))*1.00))
			when extract (year from date) = 2023 then (5000/(((sum(quantity) over(partition by extract (year from date))))*1.00))
		end as ingreso_extra
	from stg.order_line_sale as ols
	left join stg.product_master as pm
		on ols.product = pm.product_code
	where pm.brand = 'Philips'
)

	select
	
-- tienda
	sm.country, sm.province, sm.name as nombre_tienda,
	
--SKU
	pm.category, pm.subcategory, pm.subsubcategory, sup.name as proveedor,
	
--atributos de fecha
	extract(day from ols.date) as day,
	extract(month from ols.date) as month,
	extract(year from ols.date) as year,
	case
		when extract (month from ols.date) in (1) then concat ('FY',cast(((extract(year from ols.date))-1) as text))
		else concat ('FY',cast((extract(year from ols.date)) as text))
		end as fiscal_year_label,
	case
		when extract (month from ols.date) in (2,3,4) then 'Q1'
		when extract (month from ols.date) in (5,6,7) then 'Q2'
		when extract (month from ols.date) in (8,9,10) then 'Q3'
		when extract (month from ols.date) in (11,12,1) then 'Q4'
		end as fiscal_quarter_label,
		
--pasaje a USD
	
	
		case
			when ols.currency = 'ARS'
			then fx.fx_rate_usd_peso
			when ols.currency = 'EUR'
			then fx.fx_rate_usd_eur
			when ols.currency = 'URU'
			then fx.fx_rate_usd_uru
			else ols.sale
			end as cotizacion,
		case
			when ols.currency = 'ARS'
			then ols.sale/fx.fx_rate_usd_peso
			when ols.currency = 'EUR'
			then ols.sale/fx.fx_rate_usd_eur
			when ols.currency = 'URU'
			then ols.sale/fx.fx_rate_usd_uru
			else ols.sale
			end as sales_usd,
		case
			when ols.currency = 'ARS'
			then coalesce(ols.promotion/fx.fx_rate_usd_peso,0)
			when ols.currency = 'EUR'
			then coalesce(ols.promotion/fx.fx_rate_usd_eur,0)
			when ols.currency = 'URU'
			then coalesce(ols.promotion/fx.fx_rate_usd_uru,0)
			else ols.promotion
			end as promotion_usd,
		case
			when ols.currency = 'ARS'
			then coalesce(ols.credit/fx.fx_rate_usd_peso,0)
			when ols.currency = 'EUR'
			then coalesce(ols.credit/fx.fx_rate_usd_eur,0)
			when ols.currency = 'URU'
			then coalesce(ols.credit/fx.fx_rate_usd_uru,0)
			else ols.credit
			end as credit_usd,
		case
			when ols.currency = 'ARS'
			then coalesce(ols.tax/fx.fx_rate_usd_peso,0)
			when ols.currency = 'EUR'
			then coalesce(ols.tax/fx.fx_rate_usd_eur,0)
			when ols.currency = 'URU'
			then coalesce(ols.tax/fx.fx_rate_usd_uru,0)
			else ols.tax
			end as tax_usd,	
		case
			when ols.currency = 'ARS'
			then (ols.sale-coalesce(ols.promotion,0))/fx.fx_rate_usd_peso
			when ols.currency = 'EUR'
			then (ols.sale-coalesce(ols.promotion,0))/fx.fx_rate_usd_eur
			when ols.currency = 'URU'
			then (ols.sale-coalesce(ols.promotion,0))/fx.fx_rate_usd_uru
			else ols.sale-coalesce(ols.promotion,0)
			end as net_sales_usd,
		case
			when ols.currency = 'ARS'
			then ((ols.sale-coalesce(ols.promotion,0)-coalesce(ols.tax,0))/fx.fx_rate_usd_peso)-(c.product_cost_usd*ols.quantity)
			when ols.currency = 'EUR'
			then ((ols.sale-coalesce(ols.promotion,0)-coalesce(ols.tax,0))/fx.fx_rate_usd_eur)-(c.product_cost_usd*ols.quantity)
			when ols.currency = 'URU'
			then ((ols.sale-coalesce(ols.promotion,0)-coalesce(ols.tax,0))/fx.fx_rate_usd_uru)-(c.product_cost_usd*ols.quantity)
			else ols.sale-coalesce(ols.promotion,0)-coalesce(ols.tax,0)-(c.product_cost_usd*ols.quantity)
			end as margin_usd,
	
	c.product_cost_usd, ols.order_number, rm.quantity as devoluciones,
	inv.initial, inv.final,ols.quantity,

--ingresos extras

	ap.ingreso_extra, pm.brand,

--egresos extras
	
	ae.egreso_total,
	sum(ols.quantity) over(partition by ae.year,ae.store_id,ae.item_id ),
	(((ae.quantity*c.product_cost_usd)*1.00)/((sum(ols.quantity) over(partition by ae.year,ae.store_id,ae.item_id ))*1.00)) as egreso_extra

--joins
	
	from stg.order_line_sale as ols
	left join stg.product_master as pm
		on pm.product_code = ols.product
	left join stg.cost as c
		on c.product_code = ols.product
	left join stg.monthly_average_fx_rate as fx
		on date_trunc('month',ols.date) = fx.month
	left join stg.inventory as inv
		on inv.item_id = ols.product
		and inv.date = ols.date
		and inv.store_id = ols.store
	left join stg.return_movements as rm
		on rm.order_id = ols.order_number
		and rm.item = ols.product
		and rm.movement_id = 2
	left join stg.suppliers as sup
		on sup.product_id = ols.product
		and sup.is_primary is true
	left join stg.store_master as sm
		on sm.store_id = ols.store
	left join aux_philips as ap
		on ap.order_number = ols.order_number
		and ap.brand = pm.brand
		and pm.brand = 'Philips'
		and ap.year = extract(year from ols.date)
	left join aux_egresos as ae
		on ae.year = extract(year from ols.date)
		and ae.store_id = ols.store
		and ae.item_id = ols.product
