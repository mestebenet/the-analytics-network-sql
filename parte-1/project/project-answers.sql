-- General 
-- - Ventas brutas, netas y margen (USD)

-- - Margen por categoria de producto (USD)

-- - ROI por categoria de producto. ROI = ventas netas / Valor promedio de inventario (USD)

-- - AOV (Average order value), valor promedio de la orden. (USD)

with consolidado as (
	select *, 
		ols.date as fecha_completa,
		extract(year from ols.date) as año, 
		extract(month from ols.date) as mes,
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
			then ((ols.sale-coalesce(ols.promotion,0)-coalesce(ols.credit,0)-coalesce(ols.tax,0))/fx.fx_rate_usd_peso)
			when ols.currency = 'EUR'
			then ((ols.sale-coalesce(ols.promotion,0)-coalesce(ols.credit,0)-coalesce(ols.tax,0))/fx.fx_rate_usd_eur)
			when ols.currency = 'URU'
			then ((ols.sale-coalesce(ols.promotion,0)-coalesce(ols.credit,0)-coalesce(ols.tax,0))/fx.fx_rate_usd_uru)
			else ols.sale-coalesce(ols.promotion,0)-coalesce(ols.credit,0)-coalesce(ols.tax,0)
			end as net_sales_usd,
		case
			when ols.currency = 'ARS'
			then ((ols.sale-coalesce(ols.promotion,0)-coalesce(ols.credit,0)-coalesce(ols.tax,0))/fx.fx_rate_usd_peso)-c.product_cost_usd
			when ols.currency = 'EUR'
			then ((ols.sale-coalesce(ols.promotion,0)-coalesce(ols.credit,0)-coalesce(ols.tax,0))/fx.fx_rate_usd_eur)-c.product_cost_usd
			when ols.currency = 'URU'
			then ((ols.sale-coalesce(ols.promotion,0)-coalesce(ols.credit,0)-coalesce(ols.tax,0))/fx.fx_rate_usd_uru)-c.product_cost_usd
			else ols.sale-coalesce(ols.promotion,0)-coalesce(ols.credit,0)-coalesce(ols.tax,0)-c.product_cost_usd
			end as margin_usd
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
)

select 
		año, mes,
		sum (sales_usd) as sales_usd,
		sum (net_sales_usd) as net_sales_usd,
		sum (margin_usd) as margin_usd,
		(sum (sales_usd))/(count(order_number)) as aov
from consolidado
group by 1,2
order by 1,2		
		
select 
		año, mes,
		category,
		sum (margin_usd) as margin_usd,
		(sum (net_sales_usd)/(avg ((initial+final)/2))) as ROI
from consolidado
group by 1,2,3
order by 1,2,3


-- Contabilidad (USD)
-- - Impuestos pagados

-- - Tasa de impuesto. Impuestos / Ventas netas 

-- - Cantidad de creditos otorgados

-- - Valor pagado final por order de linea. Valor pagado: Venta - descuento + impuesto - credito

select 
		año, mes,
		sum (tax_usd) as tax_usd,
		(sum (tax_usd))/(sum (net_sales_usd)) as tax_rate,
		sum (credit_usd) as credit_usd,
		(sum (net_sales_usd)) - (sum (promotion_usd)) + (sum (tax_usd)) - (sum (credit_usd)) as amount_paid_usd
from consolidado
group by 1,2
order by 1,2	


-- Supply Chain (USD)
-- - Costo de inventario promedio por tienda
select 
		año, mes,
		store,
		sum (product_cost_usd)/(avg ((initial+final)/2)) as inventory_cost_usd
from consolidado
group by 1,2
order by 1,2

-- - Costo del stock de productos que no se vendieron por tienda

with inv_cost as (
select 
	*,
	extract(year from i.date) as año, 
	extract(month from i.date) as mes,
	extract(day from i.date) as dia
from stg.inventory as i
left join stg.cost as c
	on i.item_id = c.product_code
order by 2,3,1
)

select 
	store_id,
	año, mes,
	(sum(product_cost_usd*((initial+final)/2))) as inventario
from inv_cost
group by store_id,año, mes
order by store_id,año, mes



-- - Cantidad y costo de devoluciones

select
	extract(year from rm.date) as año, 
	extract(month from rm.date) as mes,
	(sum (rm.quantity)) as quantity,
	(sum (rm.quantity*c.product_cost_usd)) as returned_sales_usd
from stg.return_movements as rm
left join stg.cost as c
	on rm.item = c.product_code
group by 1,2
order by 1,2		



-- Tiendas
-- - Ratio de conversion. Cantidad de ordenes generadas / Cantidad de gente que entra
with conteo_total as (
SELECT store_id, TO_DATE(TO_CHAR(to_date(date::text, 'YYYYMMDD'), 'YYYY-MM-DD'),'YYYY-MM-DD') AS date, traffic
FROM stg.market_count
UNION ALL
SELECT store_id, TO_DATE(date,'YYYY-MM-DD') as date, traffic
FROM stg.super_store_count
)

select  
	extract(year from ols.date) as año, 
	extract(month from ols.date) as mes,
	(((count (distinct ols.order_number))*1.00)/((sum(traffic))*1.00)) as cvr 
from stg.order_line_sale as ols
left join conteo_total as ct
on ols.store = ct.store_id
and ols.date = ct.date
group by 1,2
order by 1,2
