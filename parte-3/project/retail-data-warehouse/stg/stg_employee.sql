CREATE TABLE IF NOT EXISTS stg.employees
(
    id_employees integer NOT NULL DEFAULT nextval('stg.employees_id_employees_seq'::regclass),
    name character varying(255) COLLATE pg_catalog."default",
    surname character varying(255) COLLATE pg_catalog."default",
    start_date date,
    end_date date,
    phone character varying(255) COLLATE pg_catalog."default",
    country character varying(255) COLLATE pg_catalog."default",
    province character varying(255) COLLATE pg_catalog."default",
    store_id character varying(255) COLLATE pg_catalog."default",
    "position" character varying(255) COLLATE pg_catalog."default",
    CONSTRAINT employees_pkey PRIMARY KEY (id_employees)
