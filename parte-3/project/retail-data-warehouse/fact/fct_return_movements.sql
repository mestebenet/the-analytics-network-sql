-- Table: fct.return_movements

DROP TABLE IF EXISTS fct.return_movements;

CREATE TABLE IF NOT EXISTS fct.return_movements
(
                                            order_id character varying(255),
                                            return_id character varying(255),
                                            product_id character varying(255),
                                            quantity integer,
                                            movement_id integer,
                                            from_location character varying(255),
                                            to_location character varying(255),
                                            received_by character varying(255),
                                            date date,
                                            constraint fk_product_id
                                                  foreign key (product_id)
                                              		references dim.product_master(product_id)
                                            constraint fk_order_id
                                                  foreign key (order_id)
                                              		references dim.order_line_sale(order_id)  
);

