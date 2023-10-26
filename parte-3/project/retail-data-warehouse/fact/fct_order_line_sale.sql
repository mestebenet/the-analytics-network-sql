-- Table: dim.order_line_sale

DROP TABLE IF EXISTS dim.order_line_sale;

CREATE TABLE IF NOT EXISTS dim.order_line_sale
(
                              order_number      VARCHAR(255)
                            , product           VARCHAR(10)
                            , store             SMALLINT
                            , date              date
                            , quantity          int
                            , sale              decimal(18,5)
                            , promotion         decimal(18,5)
                            , tax               decimal(18,5)
                            , credit            decimal(18,5)
                            , currency          varchar(3)
                            , pos               SMALLINT
                            , is_walkout        BOOLEAN
                            , constraint fk_product
                              		foreign key (product)
                              		references dim.product_master(product_code)
                            , constraint fk_store
                              		foreign key (store)
                              		references dim.store_master(store_id)
);
