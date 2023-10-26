-- Table: dim.product_master

DROP TABLE IF EXISTS dim.product_master;

CREATE TABLE IF NOT EXISTS dim.product_master
(
                              product_id      varchar(10) PRIMARY KEY
                            , name            varchar(255)
                            , category        varchar(255)
                            , subcategory     varchar(255)
                            , subsubcategory  varchar(255)
                            , material        varchar(255)
                            , color           varchar(255)
                            , origin          varchar(255)
                            , ean             bigint
                            , is_active       boolean
                            , has_bluetooth   boolean
                            , size            varchar(255)
);


                 

                 );
