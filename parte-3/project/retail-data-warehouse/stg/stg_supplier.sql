CREATE TABLE IF NOT EXISTS stg.suppliers
(
    product_id character varying(255) COLLATE pg_catalog."default" NOT NULL,
    name character varying(255) COLLATE pg_catalog."default",
    is_primary boolean
)
