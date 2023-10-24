-- ## Semana 3 - Parte A

-- 1.Crear una vista con el resultado del ejercicio donde unimos la cantidad de gente que ingresa a tienda usando los dos sistemas.(tablas market_count y super_store_count)
-- . Nombrar a la lista `stg.vw_store_traffic`
-- . Las columnas son `store_id`, `date`, `traffic`

create view stg.vw_store_traffic as (
	
with trafico as (
select store_id, 
TO_DATE(TO_CHAR(date, '99999999'), 'YYYYMMDD') AS date,
traffic
from stg.market_count
union all
select store_id,
TO_DATE(date, 'YYYY-MM-DD') AS date,
traffic
from  stg.super_store_count
)

select store_id, date, sum(traffic)
from trafico
group by store_id, date
order by date, store_id)

-- 2. Recibimos otro archivo con ingresos a tiendas de meses anteriores. Subir el archivo a stg.super_store_count_aug y agregarlo a la vista del ejercicio anterior. Cual hubiese sido la diferencia si hubiesemos tenido una tabla? (contestar la ultima pregunta con un texto escrito en forma de comentario)
create view stg.vw_store_traffic as (

with trafico as (
select store_id, 
TO_DATE(TO_CHAR(date, '99999999'), 'YYYYMMDD') AS date,
traffic
from stg.market_count
union all
select store_id,
TO_DATE(date, 'YYYY-MM-DD') AS date,
traffic
from  stg.super_store_count
union all
select store_id,
TO_DATE(date, 'YYYY-MM-DD') AS date,
traffic
from  stg.super_store_count_aug
	
)

select store_id, date, sum(traffic)
from trafico
group by store_id, date
order by date, store_id
	)
	

-- 3. Crear una vista con el resultado del ejercicio del ejercicio de la Parte 1 donde calculamos el margen bruto en dolares. Agregarle la columna de ventas, promociones, creditos, impuestos y el costo en dolares para poder reutilizarla en un futuro. Responder con el codigo de creacion de la vista.
-- El nombre de la vista es stg.vw_order_line_sale_usd
-- Los nombres de las nuevas columnas son sale_usd, promotion_usd, credit_usd, tax_usd, y line_cost_usd
create view stg.vw_order_line_sale_usd as
  With margen as (
  SELECT 
  order_number,
  product,
  case when currency='ARS' then (sale)/fx_rate_usd_peso 
		when currency='URU' then (sale)/fx_rate_usd_uru
		when currency='EUR' then (sale)/fx_rate_usd_eur
			end as Sale_USD,
  case when currency='ARS' then (coalesce(promotion,0))/fx_rate_usd_peso 
		when currency='URU' then (coalesce(promotion,0))/fx_rate_usd_uru
		when currency='EUR' then (coalesce(promotion,0))/fx_rate_usd_eur
			end as promotion_USD,
  case when currency='ARS' then (coalesce(credit,0))/fx_rate_usd_peso 
		when currency='URU' then (coalesce(credit,0))/fx_rate_usd_uru
		when currency='EUR' then (coalesce(credit,0))/fx_rate_usd_eur
			end as credit_USD,
 case when currency='ARS' then (coalesce(tax,0))/fx_rate_usd_peso 
		when currency='URU' then (coalesce(tax,0))/fx_rate_usd_uru
		when currency='EUR' then (coalesce(tax,0))/fx_rate_usd_eur
			end as tax_USD, 
	  
 quantity*product_cost_usd as  line_cost_usd
 FROM stg.order_line_sale ol
 left join stg.cost c on c.product_code=ol.product
 left join stg.monthly_average_fx_rate fx on date_trunc('month',date)=fx.month
	  )
	  select 
	    order_number,
  		product,
		Sale_USD,
		promotion_USD,
		credit_USD,
		tax_USD,
		line_cost_usd,
		Sale_USD-promotion_USD-Costo_USD as Margen_USD
		from margen
	
-- 4. Generar una query que me sirva para verificar que el nivel de agregacion de la tabla de ventas (y de la vista) no se haya afectado. Recordas que es el nivel de agregacion/detalle? Lo vimos en la teoria de la parte 1! Nota: La orden M202307319089 parece tener un problema verdad? Lo vamos a solucionar mas adelante.
select order_number, product
	,count(1)
	from stg.order_line_sale
	group by order_number, product
	having count(1)>1

-- 5. Calcular el margen bruto a nivel Subcategoria de producto. Usar la vista creada stg.vw_order_line_sale_usd. La columna de margen se llama margin_usd
select subcategory, sum(Margen_USD) as margin_usd
from stg.vw_order_line_sale_usd olsu
left join stg.product_master pm on olsu.product=pm.Product_code  
group by  subcategory

-- 6. Calcular la contribucion de las ventas brutas de cada producto al total de la orden.
with ventas_totales as(
select 
	order_number,
	sum(sale) as  ventas_por_orden
	FROM stg.order_line_sale
	group by order_number
)

SELECT ols.order_number, product, sum(sale),(sum(sale)/ventas_por_orden) participacion_por_producto
	FROM stg.order_line_sale ols
	left join ventas_totales vt on ols.order_number=vt.order_number
	group by ols.order_number, product, ventas_por_orden

-- 7. Calcular las ventas por proveedor, para eso cargar la tabla de proveedores por producto. Agregar el nombre el proveedor en la vista del punto stg.vw_order_line_sale_usd. El nombre de la nueva tabla es stg.suppliers
Observación: esta tabla no  tiene clave primaria. Deberiamos crearle un indice?.
--Cargar Tabla de proveedores
CREATE TABLE IF NOT EXISTS stg.suppliers
(
    product_id character varying(255) COLLATE pg_catalog."default" NOT NULL,
    name character varying(255) COLLATE pg_catalog."default",
    is_primary boolean
 );

--Nueva Vista 
create view stg.vw_order_line_sale_usd as
  With margen as (
  SELECT 
  order_number,
  product,
  case when currency='ARS' then (sale)/fx_rate_usd_peso 
		when currency='URU' then (sale)/fx_rate_usd_uru
		when currency='EUR' then (sale)/fx_rate_usd_eur
			end as Sale_USD,
  case when currency='ARS' then (coalesce(promotion,0))/fx_rate_usd_peso 
		when currency='URU' then (coalesce(promotion,0))/fx_rate_usd_uru
		when currency='EUR' then (coalesce(promotion,0))/fx_rate_usd_eur
			end as promotion_USD,
  case when currency='ARS' then (coalesce(credit,0))/fx_rate_usd_peso 
		when currency='URU' then (coalesce(credit,0))/fx_rate_usd_uru
		when currency='EUR' then (coalesce(credit,0))/fx_rate_usd_eur
			end as credit_USD,
 case when currency='ARS' then (coalesce(tax,0))/fx_rate_usd_peso 
		when currency='URU' then (coalesce(tax,0))/fx_rate_usd_uru
		when currency='EUR' then (coalesce(tax,0))/fx_rate_usd_eur
			end as tax_USD, 
	  
 quantity*product_cost_usd as  line_cost_usd,
	  s.name as Suppliers
	 
 FROM stg.order_line_sale ol
 left join stg.cost c on c.product_code=ol.product
 left join stg.monthly_average_fx_rate fx on date_trunc('month',date)=fx.month
 left join stg.suppliers s  on s.product_id=ol.product
	  
 where is_primary='True'
	  )
	  select 
	    order_number,
  		product,
		Sale_USD,
		promotion_USD,
		credit_USD,
		tax_USD,
		line_cost_usd,
		Sale_USD-promotion_USD-line_cost_usd as Margen_USD,
		Suppliers
		from margen;

--Calcular ventas por proveedor
select 
	suppliers,
	sum(sale_usd)
	FROM stg.vw_order_line_sale_usd
	group by suppliers

  


-- 8. Verificar que el nivel de detalle de la vista stg.vw_order_line_sale_usd no se haya modificado, en caso contrario que se deberia ajustar? Que decision tomarias para que no se genereren duplicados?
    -- - Se pide correr la query de validacion.
    -- - Modificar la query de creacion de stg.vw_order_line_sale_usd  para que no genere duplicacion de las filas. 
    -- - Explicar brevemente (con palabras escrito tipo comentario) que es lo que sucedia.

--Query de Validación. Agregue proveedor. 
select order_number, product, suppliers
,count(1)
from stg.vw_order_line_sale_usd
group by order_number, product,suppliers
having count(1)>1

	 En la vista,  se agrego  where is_primary='True', debido a que como cada producto, tenia más de un proveedor, era necesario  especificar que proveedor era el correcto. 
	Caso contrario,  traia un resultado (o linea), para cada proveedor. Lo que duplicaba, triplicaba, ect. los resultados. 


-- ## Semana 3 - Parte B

-- 1. Calcular el porcentaje de valores null de la tabla stg.order_line_sale para la columna creditos y descuentos. (porcentaje de nulls en cada columna)

SELECT 
 sum(case when promotion is null then 1 else 0 end) as promotion_null,
 sum(case when credit is null then 1 else 0 end) as credit_null,
 count(order_number) as Total,
 (sum(case when credit is null then 1.0 else 0 end))/count(order_number)*100 as porcent_cred_null
	FROM stg.order_line_sale

-- 2. La columna is_walkout se refiere a los clientes que llegaron a la tienda y se fueron con el producto en la mano (es decia habia stock disponible). Responder en una misma query:
   --  - Cuantas ordenes fueron walkout por tienda?
   --  - Cuantas ventas brutas en USD fueron walkout por tienda?
   --  - Cual es el porcentaje de las ventas brutas walkout sobre el total de ventas brutas por tienda?

with ordenes as (
SELECT distinct(olsu.order_number) ordenes, 
olsu.store as tienda,
is_walkout as walkout
	FROM stg.vw_order_line_sale_usd olsu
	left join stg.order_line_sale ols on ols.order_number=olsu.order_number
									 and ols. product=olsu. product
	
),
total_sale_USD as (

select tienda,ordenes, sum(sale_usd) total_sale_USD,
	walkout
	 from ordenes o 
left join stg.vw_order_line_sale_usd olsu on olsu.order_number= o.ordenes
group by tienda, ordenes,walkout
	)
	
	Select 
	 tienda,
	 sum(case when walkout='true' then 1 else 0 end) as cant_walkout,
	sum( case when walkout='true' then total_sale_USD else 0 end) as ventas_Walkout,
	sum(total_sale_USD) as ventas_totales,
	sum(case when walkout='true' then total_sale_USD else 0 end)/sum(total_sale_USD) as porcentaje
	from total_sale_USD
	group by tienda
	order by tienda
	
-- 3. Siguiendo el nivel de detalle de la tabla ventas, hay una orden que no parece cumplirlo. Como identificarias duplicados utilizando una windows function? 
-- Tenes que generar una forma de excluir los casos duplicados, para este caso particular y a nivel general, si llegan mas ordenes con duplicaciones.
with stg_sales as(
Select 
order_number,
product,
row_number() over(partition by order_number, product order by product asc) as rn
FROM stg.order_line_sale
	)
select *  
from stg_sales
where rn=1
	
-- Identificar los duplicados.
with stg_sales as(
Select 
order_number,
product,
row_number() over(partition by order_number, product order by product asc) as rn
FROM stg.order_line_sale
	)
select *  
from stg_sales
where rn!=1
-- Eliminar las filas duplicadas. Podes usar BEGIN transaction y luego rollback o commit para verificar que se haya hecho correctamente.
BEGIN;

WITH stg_sales AS (
  SELECT 
    order_number,
    product,
    ROW_NUMBER() OVER (PARTITION BY order_number, product ORDER BY product ASC) AS rn
  FROM stg.order_line_sale
)

-- Supongamos que deseas eliminar la fila duplicada con rn != 1
DELETE FROM stg.order_line_sale
WHERE (order_number, product) IN (
  SELECT order_number, product
  FROM stg_sales
  WHERE rn != 1
);

-- Decide si deseas confirmar o revertir la transacción
-- Si estás seguro de que deseas eliminar la fila, utiliza COMMIT
--COMMIT;

-- Si deseas revertir los cambios, utiliza ROLLBACK
-- ROLLBACK;


-- 4. Obtener las ventas totales en USD de productos que NO sean de la categoria TV NI esten en tiendas de Argentina. Modificar la vista stg.vw_order_line_sale_usd con todas las columnas necesarias. 

--Modificar vista, agregando columnas necesarias. 
create view stg.vw_order_line_sale_usd as
  With margen as (
  SELECT 
  order_number,
  product,
  store,
  case when currency='ARS' then (sale)/fx_rate_usd_peso 
		when currency='URU' then (sale)/fx_rate_usd_uru
		when currency='EUR' then (sale)/fx_rate_usd_eur
			end as Sale_USD,
  case when currency='ARS' then (coalesce(promotion,0))/fx_rate_usd_peso 
		when currency='URU' then (coalesce(promotion,0))/fx_rate_usd_uru
		when currency='EUR' then (coalesce(promotion,0))/fx_rate_usd_eur
			end as promotion_USD,
  case when currency='ARS' then (coalesce(credit,0))/fx_rate_usd_peso 
		when currency='URU' then (coalesce(credit,0))/fx_rate_usd_uru
		when currency='EUR' then (coalesce(credit,0))/fx_rate_usd_eur
			end as credit_USD,
 case when currency='ARS' then (coalesce(tax,0))/fx_rate_usd_peso 
		when currency='URU' then (coalesce(tax,0))/fx_rate_usd_uru
		when currency='EUR' then (coalesce(tax,0))/fx_rate_usd_eur
			end as tax_USD, 
	  
 quantity*product_cost_usd as  line_cost_usd,
	  s.name as Suppliers
	 
 FROM stg.order_line_sale ol
	   
 left join stg.cost c on c.product_code=ol.product
 left join stg.monthly_average_fx_rate fx on date_trunc('month',date)=fx.month
 left join stg.suppliers s  on s.product_id=ol.product
	  
 where is_primary='True'
	  )
	  select 
	    order_number,
  		product,
		store,
		Sale_USD,
		promotion_USD,
		credit_USD,
		tax_USD,
		line_cost_usd,
		Sale_USD-promotion_USD-line_cost_usd as Margen_USD,
		Suppliers
		from margen
--Obtener ventas totales: 

SELECT
sum(sale_usd) as ventas_totales
FROM stg.vw_order_line_sale_usd olsu
left join stg.store_master sm on sm.store_id=olsu.store
left join stg.product_master pm on pm.product_code=olsu.product
	where country<>'Argentina' 
	and subsubcategory<>'TV'

-- 5. El gerente de ventas quiere ver el total de unidades vendidas por dia junto con otra columna con la cantidad de unidades vendidas una semana atras y la diferencia entre ambos.Diferencia entre las ventas mas recientes y las mas antiguas para tratar de entender un crecimiento.

with Total_por_dia as(
Select 
date,
sum(quantity) as suma_por_dia
	FROM stg.order_line_sale
	group by date
	order by  date
	)
	
	Select *,
	lAg(suma_por_dia,7)over ( order by date asc) venta_7_dias_anteriores,
	suma_por_dia-(lAg(suma_por_dia,7)over ( order by date asc)) Diferencia
	from Total_por_dia

-- 6. Crear una vista de inventario con la cantidad de inventario promedio por dia, tienda y producto, que ademas va a contar con los siguientes datos:
/* - Nombre y categorias de producto: `product_name`, `category`, `subcategory`, `subsubcategory`
- Pais y nombre de tienda: `country`, `store_name`
- Costo del inventario por linea (recordar que si la linea dice 4 unidades debe reflejar el costo total de esas 4 unidades): `inventory_cost`
- Inventario promedio: `avg_inventory`
- Una columna llamada `is_last_snapshot` para el inventario de la fecha de la ultima fecha disponible. Esta columna es un campo booleano.
- Ademas vamos a querer calcular una metrica llamada "Average days on hand (DOH)" `days_on_hand` que mide cuantos dias de venta nos alcanza el inventario. Para eso DOH = Unidades en Inventario Promedio / Promedio diario Unidades vendidas ultimos 7 dias.
- El nombre de la vista es `stg.vw_inventory`
- Notas:
    - Antes de crear la columna DOH, conviene crear una columna que refleje el Promedio diario Unidades vendidas ultimos 7 dias. `avg_sales_last_7_days`
    - El nivel de agregacion es dia/tienda/sku.
    - El Promedio diario Unidades vendidas ultimos 7 dias tiene que calcularse para cada dia.
*/

CREATE OR REPLACE VIEW stg.vw_inventory AS

with inventario as(
Select 
i.date,
i.item_id as product_code,
pm.name as product_name,
category,
subcategory,
subsubcategory,
i.store_id as Tienda,
sm.country,
sm.name as store_name,
avg(i.initial+i.final/2) as avg_inventory,
ROW_NUMBER() OVER (PARTITION BY i.item_id, i.store_id ORDER BY date DESC) AS rn
from stg.inventory i
left join  stg.product_master pm on i.item_id=pm.product_code
left join stg.store_master sm on i.store_id=sm.store_id
left join stg.cost c on i.item_id=c.product_code
group by i.date, i.store_id, i.item_id,
pm.name,
pm.category,
pm.subcategory,
pm.subsubcategory,
sm.country,
sm.name
)
Select
inv.date,
store_name,
product_name,
category,
subcategory,
subsubcategory,
country,
avg_inventory,
(avg_inventory* product_cost_usd) as inventory_cost,
CASE WHEN rn = 1 THEN TRUE ELSE FALSE END AS is_last_snapshot,
SUM(avg_inventory) OVER (
    ORDER BY date
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) / 7.0 AS avg_sales_last_7_days,
  
  avg_inventory/(SUM(avg_inventory) OVER (
    ORDER BY date
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) / 7.0 )as days_on_hand
from inventario inv
left join stg.cost c on inv.product_code=c.product_code

        

-- ## Semana 4 - Parte A

-- 1. Calcular la contribucion de las ventas brutas de cada producto al total de la orden utilizando una window function. Mismo objetivo que el ejercicio de la parte A pero con diferente metodologia.
with ventas as (
Select 
order_number, product,
sale,
sum(sale) over(partition by order_number) as total_sales
from stg.order_line_sale
)
select order_number, product,
(sale)*1.00/(total_sales)*1.00 as sale_contribution
from ventas

-- 2. La regla de pareto nos dice que aproximadamente un 20% de los productos generan un 80% de las ventas. Armar una vista a nivel sku donde se pueda identificar por orden de contribucion, ese 20% aproximado de SKU mas importantes. Nota: En este ejercicios estamos construyendo una tabla que muestra la regla de Pareto. 
-- El nombre de la vista es `stg.vw_pareto`. Las columnas son, `product_code`, `product_name`, `quantity_sold`, `cumulative_contribution_percentage`
create view stg.vw_pareto as
with cte as(
select 
product,
sum(quantity) as qty_sold
from stg.order_line_sale ols
group by product
order by product desc)
, cte2 as (
select 
product,
qty_sold,
sum(qty_sold) over() as total_qty,
sum(qty_sold) over(order by qty_sold) as total_qty_running_sum
from cte)

select 
product  as product_code, 
pm.name as product_name,
qty_sold as quantity_sold,
total_qty_running_sum  as acumulative_contribution,
(total_qty_running_sum)*1.00/(total_qty)*1.00 as acumulative_contribution_percentage
from cte2 c2
left join stg.product_master pm on pm.product_code=c2.product

	
-- 3. Calcular el crecimiento de ventas por tienda mes a mes, con el valor nominal y el valor % de crecimiento.

with venta_mes as (
	select olsu.store as tienda,
	cast(date_trunc('month', date) as date) as mes,
	sum(sale_usd) venta_bruta_usd
	FROM stg.vw_order_line_sale_usd olsu
	left join stg.order_line_sale ols on ols.order_number=olsu.order_number
									and ols.product=olsu.product
	group by olsu.store, cast(date_trunc('month', date) as date)
	), 
	venta_mes_anterior as (
	select *,
	lag(venta_bruta_usd) over(partition by tienda order by mes asc) as Venta_ves_anterior	
	from venta_mes
		)
		
		select *,
		(venta_bruta_usd-Venta_ves_anterior) dif_ventas,
		((venta_bruta_usd-Venta_ves_anterior)/Venta_ves_anterior) dif_ventas_porct
		from venta_mes_anterior

-- 4. Crear una vista a partir de la tabla return_movements que este a nivel sku, item y que contenga las siguientes columnas:
/* - Orden `order_number`
- Sku `item`
- Cantidad unidated retornadas `quantity`
- Fecha: `date` Se considera la fecha de retorno aquella el cual el cliente la ingresa a nuestro deposito/tienda.
- Valor USD retornado (resulta de la cantidad retornada * valor USD del precio unitario bruto con que se hizo la venta) `sale_returned_usd`
- Features de producto `product_name`, `category`, `subcategory`
- `first_location` (primer lugar registrado, de la columna `from_location`, para la orden/producto)
- `last_location` (el ultimo lugar donde se registro, de la columna `to_location` el producto/orden)
- El nombre de la vista es `stg.vw_returns`*/

create view stg.vw_returns as
SELECT distinct (r.order_id), r.return_id, r.itemcharacter, r.quantity, r.date,
r.quantity *(
 case when currency='ARS' then (sale)/fx_rate_usd_peso 
	when currency='URU' then (sale)/fx_rate_usd_uru
	when currency='EUR' then (sale)/fx_rate_usd_eur
		end )/ols.quantity as sale_returned_usd,
	name as product_name, category, subcategory,
	
	first_value (from_location) over(partition by r.return_id order by movement_id asc) as first_location,
	last_value (to_location) over(partition by r.return_id) as last_location 

	FROM stg.returns r
	left join stg.order_line_sale ols on ols.product=r.itemcharacter
										and ols.date = r.date
										and ols.order_number= r.order_id
	left join stg.product_master pm on pm.product_code=r.itemcharacter
	left join stg.monthly_average_fx_rate fx on date_trunc('month',r.date)=fx.month
	


-- 5. Crear una tabla calendario llamada stg.date con las fechas del 2022 incluyendo el año fiscal y trimestre fiscal (en ingles Quarter). El año fiscal de la empresa comienza el primero Febrero de cada año y dura 12 meses. Realizar la tabla para 2022 y 2023. La tabla debe contener:
/* - Fecha (date) `date`
- Mes (date) `month`
- Año (date) `year`
- Dia de la semana (text, ejemplo: "Monday") `weekday`
- `is_weekend` (boolean, indicando si es Sabado o Domingo)
- Mes (text, ejemplo: June) `month_label`
- Año fiscal (date) `fiscal_year`
- Año fiscal (text, ejemplo: "FY2022") `fiscal_year_label`
- Trimestre fiscal (text, ejemplo: Q1) `fiscal_quarter_label`
- Fecha del año anterior (date, ejemplo: 2021-01-01 para la fecha 2022-01-01) `date_ly`
- Nota: En general una tabla date es creada para muchos años mas (minimo 10), en este caso vamos a realizarla para el 2022 y 2023 nada mas.. 
*/
SELECT 
    to_char(date_c, 'yyyymmdd')::int as Date_ID,
    cast(date_c as date) as date,
    extract(month from date_c) as month,
    extract(year from date_c) as year,
    to_char(date_c, 'day') as weekday,
	
    CASE WHEN to_char(date_c, 'day') like '%saturday%' THEN 'True' 
		WHEN (to_char(date_c, 'day'))like '%sunday%' THEN 'True' 
		ELSE 'False' END as is_weekend,
	
	to_char(date_c, 'month') as month_label,
	case when date_c BETWEEN '20220201' AND '20230131' then '2022' 	else '2023' end as fiscal_year,
	case when date_c BETWEEN '20220201' AND '20230131' then 'FY2022' 	else 'FY2023' end as fiscal_year_label,
	
	case when extract(month from date_c) in (2,3,4) then 'Q1'
		when extract(month from date_c) in (5,6,7) then 'Q2'
		when extract(month from date_c) in (8,9,10) then 'Q3'
		when extract(month from date_c) in (11,12,1) then 'Q4' end as fiscal_quarter_label,
		
	CAST( date_c - interval '1 year' AS date) AS date_ly
	
FROM (
    SELECT cast('2022-02-01' as date) + (n || ' day')::interval as date_c
    FROM generate_series(0, 730) n
) dd;
-- ## Semana 4 - Parte B

-- 1. Calcular el crecimiento de ventas por tienda mes a mes, con el valor nominal y el valor % de crecimiento. Utilizar self join.

with ventas_mes as (
select 
		cast(date_trunc('month', s.date) as date) as mes,
		sum(quantity) as quantity,
		store
from stg.order_line_sale s
left join stg.store_master sm
	on s.store = sm.store_id
group by 
	1, store
order by 
	1 asc
	)
select 
	v1.store,
	v1.mes as mes_anterior,
	v1.quantity as qty_mes_anterior,
	v2.mes as mes_actual,
	v2.quantity as qty_mes_actual,
	v2.quantity - v1.quantity as diff,
	(v2.quantity - v1.quantity)*1.0 / v1.quantity*1.0 as growth
from ventas_mes v1
inner join ventas_mes v2
on v1.mes = v2.mes - interval '1 month'
and v1.store = v2.store
order by 
	v1.store, v1.mes asc

-- 2. Hacer un update a la tabla de stg.product_master agregando una columna llamada brand, con la marca de cada producto con la primer letra en mayuscula. Sabemos que las marcas que tenemos son: Levi's, Tommy Hilfiger, Samsung, Phillips, Acer, JBL y Motorola. En caso de no encontrarse en la lista usar Unknown.

	Alter Table stg.product_master
add column brand varchar(255)
update stg.product_master
set brand=
 case when name like '%Levi%' then 'Levis'
 	  when name like '%Tommy%' then 'Tommy Hilfiger'
	  when name like '%Samsung%' then 'Samsung'
	  when name like '%Phillips%' then 'Phillips'
	   when name like '%Acer%' then 'Acer'
	   when name like '%JBL%' then 'JBL'
       when name like '%Motorola%' then 'Motorola'
	   end
-- 3. Un jefe de area tiene una tabla que contiene datos sobre las principales empresas de distintas industrias en rubros que pueden ser competencia y nos manda por mail la siguiente informacion: (ver informacion en md file)
create schema test
create table test.facturacion (
	rubro varchar(255),
	FacturacionTotal NUMERIC(17, 2)),
	empresa varchar(255);
		
	
insert into test.facturacion  (empresa, rubro, FacturacionTotal) 
  values ('El Corte Ingles','Departamental', 110990000000000 );
insert into test.facturacion  (empresa, rubro, FacturacionTotal) 
  values ('Mercado Libre','ECOMMERCE', 115860000000000 );	
 insert into test.facturacion  (empresa, rubro, FacturacionTotal) 
  values ('Fallabela','Departamental', 20460000);
 insert into test.facturacion  (empresa, rubro, FacturacionTotal) 
  values ('Tienda Inglesa','Departamental', 10780000 );
  insert into test.facturacion  (empresa, rubro, FacturacionTotal) 
  values ('Zara','INDUMENTARIA', 999980000);

select 
rubro,
case when sum(facturaciontotal)>=1000000000 then concat (round(sum(facturaciontotal)/1000000000000,2),'B')
 when (sum(facturaciontotal)) between (1000000,999999999)  then concat(round(sum(facturaciontotal)/1000000,2),'M')
end as facturacion_total
from test.facturacion
group by rubro
order by rubro asc
