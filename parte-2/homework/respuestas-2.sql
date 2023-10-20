-- ## Semana 3 - Parte A

-- 1.Crear una vista con el resultado del ejercicio donde unimos la cantidad de gente que ingresa a tienda usando los dos sistemas.(tablas market_count y super_store_count)
-- . Nombrar a la lista `stg.vw_store_traffic`
-- . Las columnas son `store_id`, `date`, `traffic`

CREATE OR REPLACE VIEW stg.vw_store_traffic as
SELECT store_id, TO_CHAR(to_date(date::text, 'YYYYMMDD'), 'YYYY-MM-DD') AS date, traffic
FROM stg.market_count
UNION 
SELECT store_id, date, traffic
FROM stg.super_store_count; 


-- 2. Recibimos otro archivo con ingresos a tiendas de meses anteriores. Subir el archivo a stg.super_store_count_aug y agregarlo a la vista del ejercicio anterior. Cual hubiese sido la diferencia si hubiesemos tenido una tabla? (contestar la ultima pregunta con un texto escrito en forma de comentario)
COPY stg.super_store_count FROM 'C:\Users\Public\super_store_count_aug.csv' DELIMITER ',' CSV HEADER;
-- Que la vista se actualiza con solo correrla, en cambio con una tabla producto de la unión de otras 2, al alterar algunas de estas, no cambia la unión.


-- 3. Crear una vista con el resultado del ejercicio del ejercicio de la Parte 1 donde calculamos el margen bruto en dolares. Agregarle la columna de ventas, promociones, creditos, impuestos y el costo en dolares para poder reutilizarla en un futuro. Responder con el codigo de creacion de la vista.
-- El nombre de la vista es stg.vw_order_line_sale_usd
-- Los nombres de las nuevas columnas son sale_usd, promotion_usd, credit_usd, tax_usd, y line_cost_usd

CREATE OR REPLACE VIEW stg.vw_order_line_sale_usd as
	select ols.*,
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
			end as sale_usd,
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
			then ((ols.sale-coalesce(ols.promotion,0))/fx.fx_rate_usd_peso)-c.product_cost_usd
			when ols.currency = 'EUR'
			then ((ols.sale-coalesce(ols.promotion,0))/fx.fx_rate_usd_eur)-c.product_cost_usd
			when ols.currency = 'URU'
			then ((ols.sale-coalesce(ols.promotion,0))/fx.fx_rate_usd_uru)-c.product_cost_usd
			else ols.sale-ols.promotion-c.product_cost_usd
			end as margin_usd,
		c.product_cost_usd as line_cost_usd	
	from stg.order_line_sale as ols
	left join stg.monthly_average_fx_rate as fx
	on date_trunc('month',ols.date) = fx.month
	left join stg.cost as c
	on c.product_code = ols.product

-- 4. Generar una query que me sirva para verificar que el nivel de agregacion de la tabla de ventas (y de la vista) no se haya afectado. Recordas que es el nivel de agregacion/detalle? Lo vimos en la teoria de la parte 1! Nota: La orden M202307319089 parece tener un problema verdad? Lo vamos a solucionar mas adelante.
select
	order_number,
	product,
	count (1) 
from stg.order_line_sale
group by
	order_number,
	product
having count (1)  > 1


-- 5. Calcular el margen bruto a nivel Subcategoria de producto. Usar la vista creada stg.vw_order_line_sale_usd. La columna de margen se llama margin_usd
select pm.subcategory, sum(olsu.margin_usd) as margin_usd
from stg.vw_order_line_sale_usd as olsu
left join stg.product_master as pm
	on	olsu.product = pm.product_code
group by pm.subcategory
order by pm.subcategory

-- 6. Calcular la contribucion de las ventas brutas de cada producto al total de la orden.
with ventasxorden as (	
	select order_number, sum(sale_usd) as total_orden
	from stg.vw_order_line_sale_usd as olsu
	group by order_number
	order by order_number
)

select 
	olsu.order_number,vxo.total_orden, olsu.product, 
	sum(olsu.sale_usd) as total_prod, 
	sum(olsu.sale_usd)/vxo.total_orden as contribución 
from stg.vw_order_line_sale_usd as olsu
left join ventasxorden as vxo
on vxo.order_number = olsu.order_number
group by olsu.order_number,vxo.total_orden, olsu.product
order by olsu.order_number,vxo.total_orden, olsu.product

-- 7. Calcular las ventas por proveedor, para eso cargar la tabla de proveedores por producto. Agregar el nombre el proveedor en la vista del punto stg.vw_order_line_sale_usd. El nombre de la nueva tabla es stg.suppliers
CREATE TABLE stg.suppliers (
    product_id varchar(255),
    name varchar(255),
    is_primary boolean
);

COPY stg.suppliers 
FROM 'C:\Users\Public\supplier.csv' 
DELIMITER ',' CSV HEADER;

--CREATE OR REPLACE VIEW stg.vw_order_line_sale_usd AS --> esta sentencia era para editar la original (ej3) pero me tiro de recursividad infinita
--SELECT olsu.*, sup.name as proveedor
--from stg.vw_order_line_sale_usd as olsu
--left join stg.suppliers as sup
--on sup.product_id = olsu.product
--where sup.is_primary is true


CREATE OR REPLACE VIEW stg.vw_order_line_sale_usd as
	select ols.*,
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
			end as sale_usd,
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
			then ((ols.sale-coalesce(ols.promotion,0))/fx.fx_rate_usd_peso)-c.product_cost_usd
			when ols.currency = 'EUR'
			then ((ols.sale-coalesce(ols.promotion,0))/fx.fx_rate_usd_eur)-c.product_cost_usd
			when ols.currency = 'URU'
			then ((ols.sale-coalesce(ols.promotion,0))/fx.fx_rate_usd_uru)-c.product_cost_usd
			else ols.sale-ols.promotion-c.product_cost_usd
			end as margin_usd,
		c.product_cost_usd as line_cost_usd	, sup.name as proveedor
	from stg.order_line_sale as ols
	left join stg.monthly_average_fx_rate as fx
	on date_trunc('month',ols.date) = fx.month
	left join stg.cost as c
	on c.product_code = ols.product
	left join stg.suppliers as sup
	on sup.product_id = ols.product
	where sup.is_primary is true


-- 8. Verificar que el nivel de detalle de la vista stg.vw_order_line_sale_usd no se haya modificado, en caso contrario que se deberia ajustar? Que decision tomarias para que no se genereren duplicados?
    -- - Se pide correr la query de validacion.
    -- - Modificar la query de creacion de stg.vw_order_line_sale_usd  para que no genere duplicacion de las filas. 
    -- - Explicar brevemente (con palabras escrito tipo comentario) que es lo que sucedia.

select
	order_number,
	product,
	count (1) 
from stg.vw_order_line_sale_usd
group by
	order_number,
	product
having count (1)  > 1

select *
from stg.vw_order_line_sale_usd
where order_number = 'M202307319089'

--Entiendo que el problema era que no se había considerado antes el campo 
--is_primary de la tabla de stg.suppliers, para poder filtrar aquellos 
--proveedores que ya no están activos.

-- ## Semana 3 - Parte B

-- 1. Calcular el porcentaje de valores null de la tabla stg.order_line_sale para la columna creditos y descuentos. (porcentaje de nulls en cada columna)

with totales as (
	select order_number,
	CASE
			WHEN credit IS NULL THEN 1
			ELSE 0
		END AS credit_null,
	CASE
			WHEN promotion IS NULL THEN 1
			ELSE 0
		END AS desc_null
	from stg.order_line_sale
)

select 
	(((sum(credit_null ))*1.00)/((count (order_number))*1.00)) as porc_cred_null,
	(((sum(desc_null ))*1.00)/((count (order_number))*1.00)) as porc_desc_null 
from totales


-- 2. La columna is_walkout se refiere a los clientes que llegaron a la tienda y se fueron con el producto en la mano (es decia habia stock disponible). Responder en una misma query:
   --  - Cuantas ordenes fueron walkout por tienda?
   --  - Cuantas ventas brutas en USD fueron walkout por tienda?
   --  - Cual es el porcentaje de las ventas brutas walkout sobre el total de ventas brutas por tienda?

with vtas_tienda as (
	select store, sum (sale_usd) as vtas_tot
	from stg.vw_order_line_sale_usd
	group by store
)

select 
	olsu.store, vt.vtas_tot, 
	count (distinct olsu.order_number) as orden_walkout, 
	sum (olsu.sale_usd) as vtas_walkout, 
	((sum (olsu.sale_usd))/ vt.vtas_tot) as porc_vtas_walkout
from stg.vw_order_line_sale_usd as olsu
left join vtas_tienda as vt
	on vt.store = olsu.store
where olsu.is_walkout is true
group by olsu.store, vt.vtas_tot


-- 3. Siguiendo el nivel de detalle de la tabla ventas, hay una orden que no parece cumplirlo. Como identificarias duplicados utilizando una windows function? 
-- Tenes que generar una forma de excluir los casos duplicados, para este caso particular y a nivel general, si llegan mas ordenes con duplicaciones.
-- Identificar los duplicados.
-- Eliminar las filas duplicadas. Podes usar BEGIN transaction y luego rollback o commit para verificar que se haya hecho correctamente.

select  order_number, product, count (1)
from stg.order_line_sale
group by order_number, product
having count (1)>1

select  order_number, product, dense_rank() over(order by order_number, product asc) as rn, count (1) 
from stg.order_line_sale
group by order_number, product
having count (1)>1


begin;
delete from stg.order_line_sale
where (select  order_number, product, count (1)
		from stg.order_line_sale
		group by order_number, product
		having count (1)>1)
rollback;	

-- 4. Obtener las ventas totales en USD de productos que NO sean de la subcategoria TV NI esten en tiendas de Argentina. Modificar la vista stg.vw_order_line_sale_usd con todas las columnas necesarias. 
select sum (sale_usd)
from stg.vw_order_line_sale_usd as olsu
left join stg.product_master as pm
	on olsu.product = pm.product_code
left join stg.store_master as sm
	on sm.store_id = olsu.store
where pm.subcategory not in ('TV')
and sm.country not in ('Argentina')



-- 5. El gerente de ventas quiere ver el total de unidades vendidas por dia junto con otra columna con la cantidad de unidades vendidas una semana atras y la diferencia entre ambos.Diferencia entre las ventas mas recientes y las mas antiguas para tratar de entender un crecimiento.
select 
	olsu.date, 
	sum (olsu.quantity) as suma_actual, olsu2.date, 
	(sum (olsu2.quantity)) as suma_semana_antes,
	(sum (olsu.quantity)-sum (olsu2.quantity)) as dif
from stg.vw_order_line_sale_usd olsu
inner join stg.vw_order_line_sale_usd as olsu2 
	on olsu.date-7 = olsu2.date
group by 1,3
order by 1,3

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
CREATE OR REPLACE VIEW stg.vw_inventory as
	select i.date,i.store_id,i.item_id,
	pm.name, pm.category, pm.subcategory, pm.subsubcategory,
	sm.country, sm.name,
	c.product_cost_usd, (((i.initial+i.final)/2)*c.product_cost_usd) as inventory_cost,  
	((i.initial+i.final)/2) as avg_inventory,
	case
		when i.date = last_value (i.date) over (rows between UNBOUNDED PRECEDING and UNBOUNDED FOLLOWING) then 'True'
		else 'False'
		end as is_last_snapshot,
	(avg (ols.quantity) over (partition by i.store_id, i.item_id order by i.date  rows between 7 preceding and current row)) as avg_sales_last_7_days,
	(((i.initial+i.final)/2)/(avg (ols.quantity) over (rows between 7 preceding and current row))) as DOH
	
	from stg.inventory as i
	left join stg.product_master as pm
	on pm.product_code = i.item_id
	left join stg.store_master as sm
	on sm.store_id = i.store_id
	left join stg.cost as c
	on c.product_code = i.item_id
	left join stg.order_line_sale as ols
	on ols.product = i.item_id
	and ols.store = i.store_id
	and ols.date = i.date
	
     

-- ## Semana 4 - Parte A

-- 1. Calcular la contribucion de las ventas brutas de cada producto al total de la orden utilizando una window function. Mismo objetivo que el ejercicio de la parte A pero con diferente metodologia.
select 
	olsu1.product, olsu1.order_number, 
	sum (olsu1.sale_usd) as suma_producto, 
	(sum (olsu2.sale_usd) over (partition by olsu2.order_number rows between UNBOUNDED PRECEDING and UNBOUNDED FOLLOWING)) as suma_total,
	(sum (olsu1.sale_usd)/(sum (olsu2.sale_usd) over (partition by olsu2.order_number rows between UNBOUNDED PRECEDING and UNBOUNDED FOLLOWING))) as proporcion
from stg.vw_order_line_sale_usd as olsu1
inner join stg.vw_order_line_sale_usd as olsu2
	on olsu1.order_number = olsu2.order_number
	and olsu1.product = olsu2.product
group by olsu1.order_number, olsu1.product, olsu2.sale_usd,olsu2.order_number
order by olsu1.order_number, olsu1.product

-- 2. La regla de pareto nos dice que aproximadamente un 20% de los productos generan un 80% de las ventas. Armar una vista a nivel sku donde se pueda identificar por orden de contribucion, ese 20% aproximado de SKU mas importantes. Nota: En este ejercicios estamos construyendo una tabla que muestra la regla de Pareto. 
-- El nombre de la vista es `stg.vw_pareto`. Las columnas son, `product_code`, `product_name`, `quantity_sold`, `cumulative_contribution_percentage`

CREATE OR REPLACE VIEW stg.vw_pareto
 AS
with pareto as (
	select product, 
		sum (quantity) as cant_vend
	from stg.order_line_sale
	group by product
	order by cant_vend desc
)

SELECT *,
	sum (cant_vend) over (order by cant_vend desc) as acum,
	sum (cant_vend) over () as total,
	((sum (cant_vend) over (order by cant_vend desc))*1.00) / ((sum (cant_vend)over ())*1.00) as propor
FROM PARETO
group by product, cant_vend


-- 3. Calcular el crecimiento de ventas por tienda mes a mes, con el valor nominal y el valor % de crecimiento.
with aumento as (
	select 
		cast(date_trunc('month', date) as date) as fecha,
		sum (quantity) as cant
	from stg.order_line_sale
	group by fecha
	order by fecha
)

select 
	a1.fecha, a1.cant, 
	cant - sum (cant) over (rows between 1 preceding and 1 preceding) as dif_nom,
	((cant / sum (cant) over (rows between 1 preceding and 1 preceding))-1) as dif_porc
from aumento a1

-- 4. Crear una vista a partir de la tabla return_movements que este a nivel Orden de venta, item y que contenga las siguientes columnas:
/* - Orden `order_number`
- Sku `item`
- Cantidad unidated retornadas `quantity`
- Fecha: `date` Se considera la fecha de retorno aquella el cual el cliente la ingresa a nuestro deposito/tienda.
- Valor USD retornado (resulta de la cantidad retornada * valor USD del precio unitario bruto con que se hizo la venta) `sale_returned_usd`
- Features de producto `product_name`, `category`, `subcategory`
- `first_location` (primer lugar registrado, de la columna `from_location`, para la orden/producto)
- `last_location` (el ultimo lugar donde se registro, de la columna `to_location` el producto/orden)
- El nombre de la vista es `stg.vw_returns`*/
CREATE OR REPLACE VIEW stg.vw_returns
select distinct
	rm.order_id, 
	rm.item as item, 
	rm.quantity, 
	rm.date as fecha,
	rm.quantity*olsu.sale_usd/olsu.quantity as sale_returned_usd,
	pm.name as product_name, pm.category, pm.subcategory,
	(first_value (rm.from_location) over (partition by rm.order_id, rm.item order by rm.date asc, rm.movement_id asc ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING )) as first_location,
	(last_value (rm.to_location) over (partition by rm.order_id, rm.item order by rm.date asc, rm.movement_id asc ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)) as last_location
from stg.return_movements as rm
left join stg.product_master as pm
	on rm.item = pm.product_code
left join stg.vw_order_line_sale_usd as olsu
	on olsu.order_number = rm.order_id
	and olsu.product = rm.item

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
CREATE OR REPLACE VIEW stg.date

select
	date_in as date,
	extract(month from date_in) as month,
	extract(year from date_in) as year,
	to_char(date_in, 'day') as weekday,
	case
		WHEN extract(dow FROM date_in) IN (0, 6) THEN 'true'
		else false
		end as is_weekend,
	to_char(date_in, 'month') as month_label,
	to_char (date_in, 'yyyymmdd'):: INT as date_id,
	cast (date_in as date) as date_fin,
	case
		when extract (month from date_in) in (1) then concat ('FY',cast(((extract(year from date_in))-1) as text))
		else concat ('FY',cast((extract(year from date_in)) as text))
		end as fiscal_year_label,
	case
		when extract (month from date_in) in (2,3,4) then 'Q1'
		when extract (month from date_in) in (5,6,7) then 'Q2'
		when extract (month from date_in) in (8,9,10) then 'Q3'
		when extract (month from date_in) in (11,12,1) then 'Q4'
		end as fiscal_quarter_label,
	(date_trunc('year', date_in) - interval '1 year') + (date_in - DATE_TRUNC('year', date_in)) AS date_ly
	
from
	(select cast ('2022-01-01' as date) + (n || 'day')::interval as date_in
	from generate_series (0,365) n );

-- ## Semana 4 - Parte B

-- 1. Calcular el crecimiento de ventas por tienda mes a mes, con el valor nominal y el valor % de crecimiento. Utilizar self join.
with aumento as (
	select 
		cast(date_trunc('month', date) as date) as fecha,
		sum (quantity) as cant
	from stg.order_line_sale
	group by fecha
	order by fecha
)

select 
	a1.fecha, a1.cant, a2.fecha, a2.cant, 
	(a2.cant-a1.cant) as dif_nom, 
	(((a2.cant*1.00)/(a1.cant*1.00)-1)*1.00) as dif_porc
from aumento a1
inner join aumento as a2
	on a1.fecha + interval '1 month' = a2.fecha

-- 2. Hacer un update a la tabla de stg.product_master agregando una columna llamada brand, con la marca de cada producto con la primer letra en mayuscula. Sabemos que las marcas que tenemos son: Levi's, Tommy Hilfiger, Samsung, Phillips, Acer, JBL y Motorola. En caso de no encontrarse en la lista usar Unknown.
alter table stg.product_master
  add brand varchar(255);

--opción A
update stg.product_master set brand = 'Levi''s' where name like '%'||'Levi'||'%';
update stg.product_master set brand = 'Tommy Hilfiger' where name like '%'||'Tommy Hilfiger'||'%';
update stg.product_master set brand = 'Samsung' where name ilike '%'||'Samsung'||'%';
update stg.product_master set brand = 'Philips' where name ilike '%'||'Philips'||'%';
update stg.product_master set brand = 'Acer' where name like '%'||'Acer'||'%';
update stg.product_master set brand = 'JBL' where name like '%'||'JBL'||'%';
update stg.product_master set brand = 'Motorola' where name ilike '%'||'Motorola'||'%';
update stg.product_master set brand = 'Unknown' where brand is null;

--opción B
UPDATE stg.product_master
SET brand = 
  CASE
    WHEN name ILIKE '%Levi%' THEN 'Levi''s'
    WHEN name ILIKE '%Tommy Hilfiger%' THEN 'Tommy Hilfiger'
    WHEN name ILIKE '%Samsung%' THEN 'Samsung'
	WHEN name ILIKE '%Philips%' THEN 'Philips'
	WHEN name ILIKE '%Acer%' THEN 'Acer'
	WHEN name ILIKE '%JBL%' THEN 'JBL'
	WHEN name ILIKE '%Motorola%' THEN 'Motorola'
	    ELSE 'Unknown'
  END;



-- 3. Un jefe de area tiene una tabla que contiene datos sobre las principales empresas de distintas industrias en rubros que pueden ser competencia y nos manda por mail la siguiente informacion: (ver informacion en md file)

CREATE SCHEMA IF NOT EXISTS test
    AUTHORIZATION postgres;

CREATE TABLE test.facturacion (
	empresa varchar(50),
	rubro varchar(50),
	facturacion varchar(50)
);

insert into test.facturacion  
values 
	('El Corte Ingles','Departamental','$110.99B'),
	('Mercado Libre','ECOMMERCE','$115.86B'),
	('Fallabela','departamental','$20.46M'),
	('Tienda Inglesa','Departamental','$10.78M'),
	('Zara','INDUMENTARIA','$999.98M')

with aux as (
select *,
lower (rubro) as rubro_corr,
right(facturacion,1) as Sufijo,
cast (substring(facturacion from 2 for length (facturacion) -2) as numeric),
case
	when (right(facturacion,1)) = 'B' then (cast (substring(facturacion from 2 for length (facturacion) -2) as numeric)) * 1000000000
	when (right(facturacion,1)) = 'M' then (cast (substring(facturacion from 2 for length (facturacion) -2) as numeric)) * 1000000
	end as fac_num
from test.facturacion
),

aux2 as (
select rubro_corr, sum (fac_num), --(cast((sum (fac_num))/1000000000 as numeric(10,2)))
case
	when ((sum (fac_num))/1000000000) > 1 
		then concat ((cast((sum (fac_num))/1000000000 as numeric(10,2))),'B')
	when ((sum (fac_num))/1000000000) < 1 
		then concat ((cast((sum (fac_num))/1000000 as numeric(10,2))),'M')
	end as fac_let
from aux
group by rubro_corr
order by rubro_corr
)

select rubro_corr, fac_let
from aux2
