
-- General 
-- - Ventas brutas, netas y margen (USD)

with Valores_en_dolares as (
 select
 to_char(date, 'YYYY-MM') AS mes_y_anio,	
 order_number,
 sale/fx_rate_usd_peso as Sale_en_dolares,
 coalesce(promotion,0)/fx_rate_usd_peso as Promotion_en_dolares,
 coalesce(credit,0)/fx_rate_usd_peso as Creditos_en_dolares,
 coalesce(tax,0)/fx_rate_usd_peso as Tax_en_dolares,
 product_cost_usd/fx_rate_usd_peso as Costo_en_dolares
 FROM stg.order_line_sale ol
left join stg.cost c on c.product_code=ol.product
left join stg.monthly_average_fx_rate fx on date_trunc('month',date)=fx.month
)
 select 
 mes_y_anio,
 sum(Sale_en_dolares) as sales_usd,
 sum(Sale_en_dolares-Promotion_en_dolares) as net_sales_usd, 
 sum(Sale_en_dolares-Costo_en_dolares-Promotion_en_dolares-Creditos_en_dolares-Tax_en_dolares)as margin_usd
 from Valores_en_dolares
 group by mes_y_anio;

-- - Margen por categoria de producto (USD)
with Valores_en_dolares as (
 select
 to_char(date, 'YYYY-MM') AS mes_y_anio,	
 order_number,
 sale*fx_rate_usd_peso as Sale_en_dolares,
 coalesce(promotion,0)/fx_rate_usd_peso as Promotion_en_dolares,
 coalesce(credit,0)/fx_rate_usd_peso as Creditos_en_dolares,
 coalesce(tax,0)/fx_rate_usd_peso as Tax_en_dolares,
 product_cost_usd/fx_rate_usd_peso as Costo_en_dolares,
	pm.category
 FROM stg.order_line_sale ol
left join stg.cost c on c.product_code=ol.product
left join stg.monthly_average_fx_rate fx on date_trunc('month',date)=fx.month
	left join stg.product_master pm on pm.product_code=ol.product
)
 select 
 mes_y_anio,
 category,
 sum(Sale_en_dolares-Costo_en_dolares-Promotion_en_dolares-Creditos_en_dolares-Tax_en_dolares)as margin_usd
 from Valores_en_dolares
 group by mes_y_anio,category

-- - ROI por categoria de producto. ROI = ventas netas / Valor promedio de inventario (USD)
with Ventas as (	
	select 
	to_char(s.date, 'YYYY-MM') AS mes_y_anio,
	product, 
	sum(s.sale-coalesce (s.promotion,0)) as ventas_netas,
	avg((inv.initial+inv.final)/2)as inventario_promedio
		from stg.order_line_sale s
			left join stg.cost c on c.product_code=s.product
			left join stg.product_master pm on s.product = pm.product_code
			left join stg.inventory inv on s.product = inv.item_id
								and s.store = inv.store_id
								and s.date = inv.date
			group by mes_y_anio, product
			order by mes_y_anio, product
		)
		
		select 
		mes_y_anio,
		category,
		sum(ventas_netas/fx_rate_usd_peso)as Total_ventas_netas,
		sum(inventario_promedio*product_cost_usd) valor_promedio_inventario,
		sum(ventas_netas/fx_rate_usd_peso)/sum(inventario_promedio*product_cost_usd) as Roi
		from Ventas v
		left join stg.cost c on v.product=c.product_code
		left join stg.product_master pm on v.product = pm.product_code
		LEFT JOIN stg.monthly_average_fx_rate fx ON TO_DATE(v.mes_y_anio || '-01', 'YYYY-MM-DD') = fx.month  -- Convierte a fecha
		
		group by mes_y_anio, category
		order by mes_y_anio, category
		
		 


-- - AOV (Average order value), valor promedio de la orden. (USD)
	with ventas as (
		Select
		to_char(date, 'YYYY-MM') AS mes_y_anio,
		AVG(sale) as aov
		FROM stg.order_line_sale ols
		group by to_char(date, 'YYYY-MM') 
		order by to_char(date, 'YYYY-MM')
		)
		Select 
		mes_y_anio,
		aov/fx_rate_usd_peso as aov_USD
		from ventas v
		LEFT JOIN stg.monthly_average_fx_rate fx ON TO_DATE(v.mes_y_anio || '-01', 'YYYY-MM-DD') = fx.month 



-- Contabilidad (USD)
-- - Impuestos pagados

Select 
	to_char(s.date, 'YYYY-MM') AS mes_y_anio,
	sum(tax/fx_rate_usd_peso) as tax_usd
	FROM stg.order_line_sale s
	left join stg.monthly_average_fx_rate fx on date_trunc('month',s.date)=fx.month
	group by to_char(date, 'YYYY-MM')
	order by to_char(date, 'YYYY-MM')

-- - Tasa de impuesto. Impuestos / Ventas netas 
With ventas_netas as (
		Select
		to_char(date, 'YYYY-MM') AS mes_y_anio,
		sum(sale-coalesce(promotion,0)-coalesce(credit,0)) as ventas_netas,
		sum(tax) as tax
		FROM stg.order_line_sale
		group by mes_y_anio
			)
		Select 
	mes_y_anio,
	(tax/ventas_netas) as tax_rate
	FROM ventas_netas vn
	order by mes_y_anio

-- - Cantidad de creditos otorgados

Select count(credit) as credit_usd
	FROM stg.order_line_sale; 

WITH creditos AS (
    SELECT
        to_char(date, 'YYYY-MM') AS mes_y_anio,
        SUM(credit) AS creditos
    FROM stg.order_line_sale
    GROUP BY mes_y_anio
)
SELECT 
    c.mes_y_anio,
    (creditos / fx_rate_usd_peso) as credit_usd
FROM creditos c
LEFT JOIN stg.monthly_average_fx_rate fx ON 
    to_date(c.mes_y_anio || '-01', 'YYYY-MM-DD') = fx.month
ORDER BY c.mes_y_anio;

-- - Valor pagado final por order de linea. Valor pagado: Venta - descuento + impuesto - credito
WITH creditos AS (
    SELECT
        to_char(date, 'YYYY-MM') AS mes_y_anio,
        SUM(sale-promotion+tax-credit) AS Valor_Pagado
    FROM stg.order_line_sale
    GROUP BY mes_y_anio
)
SELECT 
    c.mes_y_anio,
    (Valor_Pagado / fx_rate_usd_peso) as amount_paid_usd
FROM creditos c
LEFT JOIN stg.monthly_average_fx_rate fx ON 
    to_date(c.mes_y_anio || '-01', 'YYYY-MM-DD') = fx.month
ORDER BY c.mes_y_anio;


-- Supply Chain (USD)



-- - Costo de inventario promedio por tienda
WITH inventario AS (
    SELECT
        to_char(date, 'YYYY-MM') AS mes_y_anio,
        item_id,
        store_id,
        (avg((initial+final)/2)) as inventory_Promedio
    FROM stg.inventory
    GROUP BY mes_y_anio, item_id, store_id
)
SELECT 
    i.mes_y_anio,
    store_id,
    SUM(inventory_promedio * product_cost_usd) as inventory_cost_usd
FROM inventario i
LEFT JOIN stg.cost c ON c.product_code = i.item_id
GROUP BY i.mes_y_anio, store_id
ORDER BY i.mes_y_anio, store_id;

-- - Costo del stock de productos que no se vendieron por tienda

-- - Cantidad y costo de devoluciones
WITH devoluciones AS (
    	SELECT
        to_char(date, 'YYYY-MM') AS mes_y_anio,
        itemcharacter,
        sum(quantity) as quantity_sum
	FROM stg.returns r
	GROUP BY mes_y_anio, itemcharacter
	order by mes_y_anio, itemcharacter
)
SELECT 
    mes_y_anio,
	itemcharacter,
	quantity_sum,
	(quantity_sum*product_cost_usd)as returned_sales_usd
FROM devoluciones d
left join stg.cost c on d.itemcharacter=c.product_code
ORDER BY mes_y_anio,itemcharacter


-- Tiendas
-- - Ratio de conversion. Cantidad de ordenes generadas / Cantidad de gente que entra

select 
	to_char(s.date, 'YYYY-MM') AS mes_y_anio , 
	(count(distinct order_number))/sum(traffic*1.00) as cvr
from stg.order_line_sale s
left join stg.vw_store_traffic t
on s.store = t.store_id
and s.date = t.date
group by 
	mes_y_anio


