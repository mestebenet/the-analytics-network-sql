-- Table: fct.order_line_sale

DROP TABLE IF EXISTS fct.order_line_sale;

CREATE TABLE IF NOT EXISTS fct.order_line_sale
(
                              order_id          VARCHAR(255) primary key
                            , product_id        VARCHAR(10)
                            , store_id          SMALLINT
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
                              		foreign key (product_id)
                              		references dim.product_master(product_id)
                            , constraint fk_store
                              		foreign key (store_id)
                              		references dim.store_master(store_id)
);
