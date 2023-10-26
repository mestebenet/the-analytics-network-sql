/* Crea tabla suppliers
DROP TABLE IF EXISTS stg.suppliers;
    
CREATE TABLE stg.suppliers
                 (
                            product_id varchar(255),
                            name varchar(255),
                            is_primary boolean
  
                 );
