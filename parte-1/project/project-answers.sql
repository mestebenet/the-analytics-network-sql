
-- General 
-- - Ventas brutas, netas y margen (USD)

with Valores_en_dolares as (
 select
 to_char(date, 'YYYY-MM') AS mes_y_anio,	
 order_number,
 sale*fx_rate_usd_peso as Sale_en_dolares,
 coalesce(promotion,0)*fx_rate_usd_peso as Promotion_en_dolares,
 coalesce(credit,0)*fx_rate_usd_peso as Creditos_en_dolares,
 coalesce(tax,0)*fx_rate_usd_peso as Tax_en_dolares,
 product_cost_usd*fx_rate_usd_peso as Costo_en_dolares
 FROM stg.order_line_sale ol
left join stg.cost c on c.product_code=ol.product
left join stg.monthly_average_fx_rate fx on date_trunc('month',date)=fx.month
)
 select 
 mes_y_anio,
 sum(Sale_en_dolares) as sales_usd,
 sum(Sale_en_dolares-Costo_en_dolares) as net_sales_usd, 
 sum(Sale_en_dolares-Costo_en_dolares-Promotion_en_dolares-Creditos_en_dolares-Tax_en_dolares)as margin_usd
 from Valores_en_dolares
 group by mes_y_anio;

-- - Margen por categoria de producto (USD)
with Valores_en_dolares as (
 select
 to_char(date, 'YYYY-MM') AS mes_y_anio,	
 order_number,
 sale*fx_rate_usd_peso as Sale_en_dolares,
 coalesce(promotion,0)*fx_rate_usd_peso as Promotion_en_dolares,
 coalesce(credit,0)*fx_rate_usd_peso as Creditos_en_dolares,
 coalesce(tax,0)*fx_rate_usd_peso as Tax_en_dolares,
 product_cost_usd*fx_rate_usd_peso as Costo_en_dolares,
	pm.category
 FROM stg.order_line_sale ol
left join stg.cost c on c.product_code=ol.product
left join stg.monthly_average_fx_rate fx on date_trunc('month',date)=fx.month
	left join stg.product_master pm on pm.product_code=ol.product
)
 select 
 category,
 sum(Sale_en_dolares-Costo_en_dolares-Promotion_en_dolares-Creditos_en_dolares-Tax_en_dolares)as margin_usd
 from Valores_en_dolares
 group by category;

-- - ROI por categoria de producto. ROI = ventas netas / Valor promedio de inventario (USD)

-- - AOV (Average order value), valor promedio de la orden. (USD)

-- Contabilidad (USD)
-- - Impuestos pagados

-- - Tasa de impuesto. Impuestos / Ventas netas 

-- - Cantidad de creditos otorgados

-- - Valor pagado final por order de linea. Valor pagado: Venta - descuento + impuesto - credito

-- Supply Chain (USD)
-- - Costo de inventario promedio por tienda

-- - Costo del stock de productos que no se vendieron por tienda

-- - Cantidad y costo de devoluciones


-- Tiendas
-- - Ratio de conversion. Cantidad de ordenes generadas / Cantidad de gente que entra

