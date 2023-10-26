-- Table: dim.store_traffic

DROP TABLE IF EXISTS dim.store_traffic;

CREATE TABLE IF NOT EXISTS dim.store_traffic
(
                              store_id SMALLINT
                            , date  VARCHAR(10)
                            , traffic SMALLINT
                            , PRIMARY KEY (store_id, date)
                            , constraint fk_store_id
                              		foreign key (store_id)
                              		references dim.store_master(store_id)
);
