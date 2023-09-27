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
with Valores_en_dolares as (
 select
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

 Select order_number,
(Sale_en_dolares-Promotion_en_dolares-Creditos_en_dolares-Costo_en_dolares)as MargenBruto_en_dolares
 from Valores_en_dolares

-- 4. Generar una query que me sirva para verificar que el nivel de agregacion de la tabla de ventas (y de la vista) no se haya afectado. Recordas que es el nivel de agregacion/detalle? Lo vimos en la teoria de la parte 1! Nota: La orden M202307319089 parece tener un problema verdad? Lo vamos a solucionar mas adelante.
select order_number, product
	,count(1)
	from stg.order_line_sale
	group by order_number, product
	having count(1)>1

-- 5. Calcular el margen bruto a nivel Subcategoria de producto. Usar la vista creada stg.vw_order_line_sale_usd. La columna de margen se llama margin_usd
select subcategory, sum(margin_usd) as margin_usd
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
--Calcular ventas por proveedor
Select
s.name,
sum(sale),
from stg.suppliers s
left join stg.order_line_sale ols on s.product_id=ols.product 
group by s.name;

--Nueva Vista 
CREATE OR REPLACE VIEW stg.vw_order_line_sale_usd
 AS
 WITH valores_en_dolares AS (
         SELECT ol.order_number,
            ol.product,
            ol.sale * fx.fx_rate_usd_peso AS sale_en_dolares,
            COALESCE(ol.promotion, 0::numeric) * fx.fx_rate_usd_peso AS promotion_en_dolares,
            COALESCE(ol.credit, 0::numeric) * fx.fx_rate_usd_peso AS creditos_en_dolares,
            COALESCE(ol.tax, 0::numeric) * fx.fx_rate_usd_peso AS tax_en_dolares,
            c.product_cost_usd * fx.fx_rate_usd_peso AS costo_en_dolares
	 		
           FROM stg.order_line_sale ol
             LEFT JOIN stg.cost c ON c.product_code::text = ol.product::text
             LEFT JOIN stg.monthly_average_fx_rate fx ON date_trunc('month'::text, ol.date::timestamp with time zone) = fx.month
			
 )
 SELECT vd.order_number,
    vd.product,
    vd.sale_en_dolares - vd.promotion_en_dolares - vd.creditos_en_dolares - vd.costo_en_dolares AS margin_usd,
    s.name as proveedor
	from valores_en_dolares vd
	left join stg.suppliers s on s.product_id=vd.product 

  


-- 8. Verificar que el nivel de detalle de la vista stg.vw_order_line_sale_usd no se haya modificado, en caso contrario que se deberia ajustar? Que decision tomarias para que no se genereren duplicados?
    -- - Se pide correr la query de validacion.
    -- - Modificar la query de creacion de stg.vw_order_line_sale_usd  para que no genere duplicacion de las filas. 
    -- - Explicar brevemente (con palabras escrito tipo comentario) que es lo que sucedia.

--Query de Validación. Agregue proveedor. 
select order_number, product, proveedor
,count(1)
from stg.vw_order_line_sale_usd
group by order_number, product,proveedor
having count(1)>1

--Nueva Vista
CREATE OR REPLACE VIEW stg.vw_order_line_sale_usd
 AS 
WITH valores_en_dolares AS (
 SELECT ol.order_number,
            ol.product,
            ol.sale * fx.fx_rate_usd_peso AS sale_en_dolares,
            COALESCE(ol.promotion, 0::numeric) * fx.fx_rate_usd_peso AS promotion_en_dolares,
            COALESCE(ol.credit, 0::numeric) * fx.fx_rate_usd_peso AS creditos_en_dolares,
            COALESCE(ol.tax, 0::numeric) * fx.fx_rate_usd_peso AS tax_en_dolares,
            c.product_cost_usd * fx.fx_rate_usd_peso AS costo_en_dolares
	 		
           FROM stg.order_line_sale ol
             LEFT JOIN stg.cost c ON c.product_code::text = ol.product::text
             LEFT JOIN stg.monthly_average_fx_rate fx ON date_trunc('month'::text, ol.date::timestamp with time zone) = fx.month
			
 )
 SELECT vd.order_number,
    vd.product,
    vd.sale_en_dolares - vd.promotion_en_dolares - vd.creditos_en_dolares - vd.costo_en_dolares AS margin_usd,
    s.name as proveedor
	from valores_en_dolares vd
	left join stg.suppliers s on s.product_id=vd.product 
	where s.is_primary='True'

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

SELECT store,
	sum(case when is_walkout='true' then 1 else 0 end) as cant_walkout,
	sum( case when is_walkout='true' then sale else 0 end) as ventas_Walkout,
	sum(sale) as ventas_totales,
	(sum(case when is_walkout='true' then sale else 0 end))/sum(sale) as porcentaje
		FROM stg.order_line_sale
		group by store
		order by store

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
create VIEW  stg.vw_order_line_sale_usd as
(
 WITH valores_en_dolares AS (
SELECT ol.order_number,
            ol.product,
            ol.sale * fx.fx_rate_usd_peso AS sale_en_dolares,
            COALESCE(ol.promotion, 0::numeric) * fx.fx_rate_usd_peso AS promotion_en_dolares,
            COALESCE(ol.credit, 0::numeric) * fx.fx_rate_usd_peso AS creditos_en_dolares,
            COALESCE(ol.tax, 0::numeric) * fx.fx_rate_usd_peso AS tax_en_dolares,
            c.product_cost_usd * fx.fx_rate_usd_peso AS costo_en_dolares,
			ol.store as store,
			sm.country as country,
			pm.subcategory as subcategoria_producto
			
           FROM stg.order_line_sale ol
             LEFT JOIN stg.cost c ON c.product_code::text = ol.product::text
             LEFT JOIN stg.monthly_average_fx_rate fx ON date_trunc('month'::text, ol.date::timestamp with time zone) = fx.month
			 left join stg.store_master sm on ol.store=sm.store_id
			 left join stg.product_master pm on ol.product=pm.product_code 
	 )
	SELECT vd.order_number,
    vd.product,
	vd.sale_en_dolares,
    vd.sale_en_dolares - vd.promotion_en_dolares - vd.creditos_en_dolares - vd.costo_en_dolares AS margin_usd,
    s.name AS proveedor,
	vd.country,
	vd.subcategoria_producto
	
   FROM valores_en_dolares vd
     LEFT JOIN stg.suppliers s ON s.product_id::text = vd.product::text
	)

--Obtener ventas totales: 

SELECT
sum(sale_en_dolares)
FROM stg.vw_order_line_sale_usd
	where country<>'Argentina' 
	and subcategoria_producto<>'TV'

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

with inventario as(
Select 
i.date,
i.item_id as product_code,
pm.name as product_name,
pm.category,
pm.subcategory,
pm.subsubcategory,
i.store_id as Tienda,
sm.country,
sm.name as store_name,
avg(i.initial+i.final/2) as avg_inventory

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
Select inv.*,
(avg_inventory* product_cost_usd) as inventory_cost
from inventario inv
left join stg.cost c on inv.product_code=c.product_code

        

-- ## Semana 4 - Parte A

-- 1. Calcular la contribucion de las ventas brutas de cada producto al total de la orden utilizando una window function. Mismo objetivo que el ejercicio de la parte A pero con diferente metodologia.

-- 2. La regla de pareto nos dice que aproximadamente un 20% de los productos generan un 80% de las ventas. Armar una vista a nivel sku donde se pueda identificar por orden de contribucion, ese 20% aproximado de SKU mas importantes. Nota: En este ejercicios estamos construyendo una tabla que muestra la regla de Pareto. 
-- El nombre de la vista es `stg.vw_pareto`. Las columnas son, `product_code`, `product_name`, `quantity_sold`, `cumulative_contribution_percentage`

-- 3. Calcular el crecimiento de ventas por tienda mes a mes, con el valor nominal y el valor % de crecimiento.

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

-- ## Semana 4 - Parte B

-- 1. Calcular el crecimiento de ventas por tienda mes a mes, con el valor nominal y el valor % de crecimiento. Utilizar self join.

-- 2. Hacer un update a la tabla de stg.product_master agregando una columna llamada brand, con la marca de cada producto con la primer letra en mayuscula. Sabemos que las marcas que tenemos son: Levi's, Tommy Hilfiger, Samsung, Phillips, Acer, JBL y Motorola. En caso de no encontrarse en la lista usar Unknown.

-- 3. Un jefe de area tiene una tabla que contiene datos sobre las principales empresas de distintas industrias en rubros que pueden ser competencia y nos manda por mail la siguiente informacion: (ver informacion en md file)
