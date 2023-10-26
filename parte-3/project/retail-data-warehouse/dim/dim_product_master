-- Table: dim.product_master

DROP TABLE IF EXISTS dim.product_master;

CREATE TABLE IF NOT EXISTS dim.product_master
(
    product_id varchar(10) PRIMARY KEY,
    cost_usd numeric,
	constraint fk_product_id_cost
		foreign key (product_id)
		references dim.product_master(product_code)
);
