-- Table: dim.employee

DROP TABLE IF EXISTS dim.employee;

CREATE TABLE IF NOT EXISTS dim.employee
(
                            id serial primary key,
                          	name varchar(255),
                          	surname varchar(255),
                          	start_date date,
                          	end_date date,
                            duration smallint,
                          	phone varchar(30), 
                          	country varchar(30), 
                          	province varchar(30), 
                          	store_id smallint, 
                          	position varchar(30),
                            active boolean,
                            constraint fk_store_id
                            		foreign key (store_id)
                            		references dim.store_master(store_id)
);

