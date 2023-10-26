-- Table: stg.return_movements

-- DROP TABLE IF EXISTS stg.return_movements;

CREATE TABLE IF NOT EXISTS stg.return_movements
(
                                            order_id character varying(255),
                                            return_id character varying(255),
                                            item character varying(255),
                                            quantity integer,
                                            movement_id integer,
                                            from_location character varying(255),
                                            to_location character varying(255),
                                            received_by character varying(255),
                                            date date
);
