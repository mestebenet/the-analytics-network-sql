-- ## Semana 1 - Parte A


-- 1. Mostrar todos los productos dentro de la categoria electro junto con todos los detalles.
select * from stg.product_master where categoria = 'Electro'

-- 2. Cuales son los producto producidos en China?
SELECT *
	FROM stg.product_master
	where origin='China';
  
-- 3. Mostrar todos los productos de Electro ordenados por nombre.
SELECT *
	FROM stg.product_master
	order by name;

-- 4. Cuales son las TV que se encuentran activas para la venta?

SELECT *
	FROM stg.product_master
	where subcategory='TV' and is_active='true';


-- 5. Mostrar todas las tiendas de Argentina ordenadas por fecha de apertura de las mas antigua a la mas nueva.
SELECT store_id, country, province, city, address, name, type, start_date
	FROM stg.store_master
	order by start_date;

-- 6. Cuales fueron las ultimas 5 ordenes de ventas?

SELECT order_number, product, store, date, quantity, sale, promotion, tax, credit, currency, pos, is_walkout
	FROM stg.order_line_sale
	order by date desc
	limit 5;


-- 7. Mostrar los primeros 10 registros de el conteo de trafico por Super store ordenados por fecha.
 SELECT store_id, date, traffic
	FROM stg.super_store_count
	order by date
	limit 10;

-- 8. Cuales son los producto de electro que no son Soporte de TV ni control remoto.
	SELECT product_code, name, category, subcategory, subsubcategory, material, color, origin, ean, is_active, has_bluetooth, size
	FROM stg.product_master
	where subsubcategory <> 'Control remoto' and subsubcategory <> 'Soporte';

-- 9. Mostrar todas las lineas de venta donde el monto sea mayor a $100.000 solo para transacciones en pesos.
SELECT order_number, product, store, date, quantity, sale, promotion, tax, credit, currency, pos, is_walkout
	FROM stg.order_line_sale
	where sale>100000 and currency='ARS';

-- 10. Mostrar todas las lineas de ventas de Octubre 2022.
SELECT order_number, product, store, date, quantity, sale, promotion, tax, credit, currency, pos, is_walkout
	FROM stg.order_line_sale
	where date between '2022-10-01' and '2022-10-31'

-- 11. Mostrar todos los productos que tengan EAN.
SELECT product_code, name, category, subcategory, subsubcategory, material, color, origin, ean, is_active, has_bluetooth, size
	FROM stg.product_master
	where ean is not null;

-- 12. Mostrar todas las lineas de venta que que hayan sido vendidas entre 1 de Octubre de 2022 y 10 de Noviembre de 2022.
SELECT order_number, product, store, date, quantity, sale, promotion, tax, credit, currency, pos, is_walkout
	FROM stg.order_line_sale
	where date between '2022-10-01' and '2022-11-10'


-- ## Semana 1 - Parte B

-- 1. Cuales son los paises donde la empresa tiene tiendas?
	SELECT distinct country	FROM stg.store_master;

-- 2. Cuantos productos por subcategoria tiene disponible para la venta?
SELECT count(distinct subcategory) FROM stg.product_master;

-- 3. Cuales son las ordenes de venta de Argentina de mayor a $100.000?
SELECT *
	FROM stg.order_line_sale ol
	left join stg.store_master sm on ol.store=sm.store_id
	where sale>100000 and country='Argentina'

-- 4. Obtener los decuentos otorgados durante Noviembre de 2022 en cada una de las monedas?
SELECT currency, sum(promotion)
	FROM stg.order_line_sale ol
	group by currency

-- 5. Obtener los impuestos pagados en Europa durante el 2022.
SELECT sum(tax), country
	FROM stg.order_line_sale ol
	left join stg.store_master sm on ol.store=sm.store_id
	where date between '2022-01-01' and '2022-12-31'
	group by country
	having country='Uruguay'

-- 6. En cuantas ordenes se utilizaron creditos?
SELECT count(order_number)
	FROM stg.order_line_sale ol
	where credit is not null

-- 7. Cual es el % de descuentos otorgados (sobre las ventas) por tienda?
SELECT store,
       SUM(sale) AS total_sales,
       SUM(promotion) AS total_promotion,
       CASE
           WHEN SUM(sale) = 0 THEN 0  -- Evitar la división por cero
           ELSE (SUM(promotion) / SUM(sale))*100
       END AS promotion_to_sales_ratio
FROM stg.order_line_sale ol
GROUP BY store;

-- 8. Cual es el inventario promedio por dia que tiene cada tienda?
SELECT date, store_id,avg(initial+final/2) as promedio
	FROM stg.inventory
	group by date, store_id
	order by date

-- 9. Obtener las ventas netas y el porcentaje de descuento otorgado por producto en Argentina.
SELECT product, sum(sale-promotion) as ventas_netas, 
CASE
           WHEN SUM(sale) = 0 THEN 0  -- Evitar la división por cero
           ELSE (SUM(promotion) / SUM(sale))*100
       END AS promotion_to_sales_ratio,
	   country
FROM stg.order_line_sale ol
left join stg.store_master sm on ol.store=sm.store_id
where country='Argentina'
GROUP BY product, country

-- 10. Las tablas "market_count" y "super_store_count" representan dos sistemas distintos que usa la empresa para contar la cantidad de gente que ingresa a tienda, uno para las tiendas de Latinoamerica y otro para Europa. Obtener en una unica tabla, las entradas a tienda de ambos sistemas.
SELECT store_id, TO_DATE(CAST(date AS VARCHAR), 'YYYYMMDD'),  traffic
	FROM stg.market_count
	Union
SELECT store_id, TO_DATE(date, 'YYYY-MM-DD'), traffic
	FROM stg.super_store_count;
-- 11. Cuales son los productos disponibles para la venta (activos) de la marca Phillips?
SELECT product_code, name, category, subcategory, subsubcategory, material, color, origin, ean, is_active, has_bluetooth, size
	FROM stg.product_master
	where name like '%PHILIPS%'AND is_active='true'

-- 12. Obtener el monto vendido por tienda y moneda y ordenarlo de mayor a menor por valor nominal de las ventas (sin importar la moneda).
SELECT store, sum(sale) total_ventas, currency
	FROM stg.order_line_sale
	group by store, currency
	order by total_ventas desc
-- 13. Cual es el precio promedio de venta de cada producto en las distintas monedas? Recorda que los valores de venta, impuesto, descuentos y creditos es por el total de la linea.
with ventas as (
    select 
        product,
        quantity,
        currency,
        sale as ventas,
        CASE WHEN promotion is null THEN 0  
             ELSE promotion END AS promotion,
        CASE WHEN tax is null THEN 0  
             ELSE tax END AS tax,
        CASE WHEN credit is null THEN 0  
             ELSE credit END AS credit
    FROM stg.order_line_sale
)
   
select product, currency,
    ((sum(ventas) - sum(promotion) + sum(tax) - sum(credit)) / sum(quantity)) as preciopromedio
from ventas
group by product, currency
order by product;

SELECT  product,
currency,
sum(sale-coalesce(promotion,0)+Coalesce(tax,0)-Colaesce(credit,0))as  precioneto
FROM stg.order_line_sale
group by product, currency
order by product;

-- 14. Cual es la tasa de impuestos que se pago por cada orden de venta?

SELECT order_number, 
case
	WHEN tax is null THEN 0  
        ELSE (tax / (sale)) end as TasaImpuestos
	FROM stg.order_line_sale


-- ## Semana 2 - Parte A
-- 1. Mostrar nombre y codigo de producto, categoria y color para todos los productos de la marca Philips y Samsung, mostrando la leyenda "Unknown" cuando no hay un color disponible
SELECT product_code, name, category, 
   CASE WHEN color is null then 'Unknown' else color end as Color
FROM stg.product_master
where name like '%Samsung%'or name like '%PHILIPS%'

-- 2. Calcular las ventas brutas y los impuestos pagados por pais y provincia en la moneda correspondiente.
SELECT Sum(sale),sum(tax), currency, country
	FROM stg.order_line_sale ol
	left join stg.store_master sm on ol.store=sm.store_id
	GROUP BY country, currency

-- 3. Calcular las ventas totales por subcategoria de producto para cada moneda ordenados por subcategoria y moneda.
SELECT sum(sale), subcategory, currency
	FROM stg.order_line_sale ol
	left join stg.product_master pm on ol.product=pm.product_code 
	group by subcategory, currency
  
-- 4. Calcular las unidades vendidas por subcategoria de producto y la concatenacion de pais, provincia; usar guion como separador y usarla para ordernar el resultado.
  SELECT sum(sale), subcategory, concat(country, '-', province) PaisProvincia
	FROM stg.order_line_sale ol
	left join stg.product_master pm on ol.product=pm.product_code 
	left join stg.store_master sm on ol.store=sm.store_id
	group by subcategory,country, province
	order by paisProvincia
-- 5. Mostrar una vista donde sea vea el nombre de tienda y la cantidad de entradas de personas que hubo desde la fecha de apertura para el sistema "super_store".
Create view entrada_personas as
SELECT ssc.store_id, sum(traffic)
	FROM stg.super_store_count ssc
	left join stg.store_master sm on sm.store_id=ssc.store_id
	group by ssc.store_id
  
-- 7. Calcular la cantidad de unidades vendidas por material. Para los productos que no tengan material usar 'Unknown', homogeneizar los textos si es necesario.
  SELECT SUM(sale),
    CASE
        WHEN material IS NULL THEN 'Unknown'
        ELSE replace (material, 'plastico','PLASTICO')
    END AS materialnuevo
FROM stg.order_line_sale ol
LEFT JOIN stg.product_master pm ON pm.product_code = ol.product
GROUP BY materialnuevo;
-- 8. Mostrar la tabla order_line_sales agregando una columna que represente el valor de venta bruta en cada linea convertido a dolares usando la tabla de tipo de cambio.
  SELECT (sale / fx_rate_usd_peso) as venta_Dolares,
order_number, product, store, date, quantity, sale, promotion, tax, credit, currency, pos, is_walkout
FROM stg.order_line_sale ol
left join stg.monthly_average_fx_rate fx 
on date_trunc('month',date)=fx.month

-- 9. Calcular cantidad de ventas totales de la empresa en dolares.
   SELECT 
  sum (case when currency='ARS' then sale/fx_rate_usd_peso 
		when currency='URU' then sale/fx_rate_usd_uru
		when currency='EUR' then sale/fx_rate_usd_eur
			end) as Sale_en_dolares
 FROM stg.order_line_sale ol
 left join stg.monthly_average_fx_rate fx 
 on date_trunc('month',date)=fx.month

-- 10. Mostrar en la tabla de ventas el margen de venta por cada linea. Siendo margen = (venta - descuento) - costo expresado en dolares.
 With margen as (
  SELECT 
  order_number,
  product,
  case when currency='ARS' then (sale-coalesce(promotion,0))/fx_rate_usd_peso 
		when currency='URU' then (sale-coalesce(promotion,0))/fx_rate_usd_uru
		when currency='EUR' then (sale-coalesce(promotion,0))/fx_rate_usd_eur
			end as Sale_USD,
 quantity*product_cost_usd as Costo_USD
 FROM stg.order_line_sale ol
 left join stg.cost c on c.product_code=ol.product
 left join stg.monthly_average_fx_rate fx on date_trunc('month',date)=fx.month
	  )
	  select 
	    order_number,
  		product,
		Sale_USD,
		Costo_USD,
	  	Sale_USD-Costo_USD as Margen_USD
		from margen

-- 11. Calcular la cantidad de items distintos de cada subsubcategoria que se llevan por numero de orden.
  
SELECT order_number, count(distinct(subcategory))
FROM stg.order_line_sale ol
	LEFT JOIN stg.product_master pm ON pm.product_code = ol.product
	group by order_number

-- ## Semana 2 - Parte B

-- 1. Crear un backup de la tabla product_master. Utilizar un esquema llamada "bkp" y agregar un prefijo al nombre de la tabla con la fecha del backup en forma de numero entero.
  DO $$
BEGIN
  EXECUTE 'CREATE SCHEMA IF NOT EXISTS bkp';
  EXECUTE 'CREATE TABLE IF NOT EXISTS bkp.productmaster'  TO_CHAR(current_date, 'YYYYMMDD')  ' AS TABLE stg.product_master';
END $$;
-- 2. Hacer un update a la nueva tabla (creada en el punto anterior) de product_master agregando la leyendo "N/A" para los valores null de material y color. Pueden utilizarse dos sentencias.
  update bkp.product_master_20230918
set color= 'N/A'
where color is null

update bkp.product_master_20230918
set material= 'N/A'
where material is null

-- 3. Hacer un update a la tabla del punto anterior, actualizando la columa "is_active", desactivando todos los productos en la subsubcategoria "Control Remoto".
update bkp.product_master_20230918
set is_active='false'
where subsubcategory= 'Control remoto'
  
-- 4. Agregar una nueva columna a la tabla anterior llamada "is_local" indicando los productos producidos en Argentina y fuera de Argentina.
alter table bkp.product_master_20230918
add is_local varchar(255)

UPDATE bkp.product_master_20230918
SET is_local = CASE WHEN origin = 'Argentina' THEN 'True' ELSE 'False' END;

  
-- 5. Agregar una nueva columna a la tabla de ventas llamada "line_key" que resulte ser la concatenacion de el numero de orden y el codigo de producto.
ALTER TABLE stg.order_line_sale 
ADD column line_key varchar(255)

UPDATE stg.order_line_sale 
SET line_key = order_number||'-'||product

	
-- 6. Crear una tabla llamada "employees" (por el momento vacia) que tenga un id (creado de forma incremental), name, surname, start_date, end_name, phone, country, province, store_id, position. Decidir cual es el tipo de dato mas acorde.
  CREATE TABLE IF NOT EXISTS stg.employees
(  
	id_employees SERIAL not null PRIMARY KEY,
    name character varying(255),
    surname character varying(255),
    start_date date,
    end_date date,
    phone character varying(255),
    country character varying(255),
    province character varying(255),
    store_id character varying(255),
    position character varying(255)
   
)
-- 7. Insertar nuevos valores a la tabla "employees" para los siguientes 4 empleados:
	  
insert into stg.employees values (1,'Juan', 'Perez', '2022-01-01', null , 541113869867, 'Argentina', 'Santa Fe', 'tienda 2', 'Vendedor')
insert into stg.employees values (default, 'Catalina', 'Garcia', '2022-03-01', current_date, null,  'Argentina', 'Buenos Aires', 'tienda 2', 'Representante Comercial')
insert into stg.employees values (default, 'Ana', 'Valdez', '2020-02-21', '2022-03-01', null, 'España', 'Madrid', 'tienda 8', 'Jefe Logistica');
insert into stg.employees values (default,'Fernando', 'Moralez', '2022-04-04', current_date,null ,'España', 'Valencia', 'tienda 9', 'Vendedor')

   
  
-- 8. Crear un backup de la tabla "cost" agregandole una columna que se llame "last_updated_ts" que sea el momento exacto en el cual estemos realizando el backup en formato datetime.
select * into bkp.cost
   from stg.cost;
    
ALTER TABLE bkp.cost
ADD COLUMN last_updated_ts DATE DEFAULT current_date;
  
-- 9. En caso de hacer un cambio que deba revertirse en la tabla "order_line_sale" y debemos volver la tabla a su estado original, como lo harias?
"BEGIN" se usa para iniciar una transacción en una base de datos, y "ROLLBACK" se usa para deshacer una transacción en caso de error
o cuando se necesita cancelar una serie de operaciones realizadas dentro de la transacción. 
Ambas sentencias son esenciales para garantizar la integridad y consistencia de los datos en una base de datos 
en entornos donde se requiere control transaccional.
