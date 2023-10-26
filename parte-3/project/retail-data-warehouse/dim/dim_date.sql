-- Table: dim.date

DROP TABLE IF EXISTS dim.date;

CREATE TABLE IF NOT EXISTS dim.date
(
    date                     date
    month                    numeric
    year                     numeric
    weekday                  varchar(10)
    is_weekend               boolean
    month_label              varchar(10)
    fiscal_year_label        varchar(6)
    fiscal_quarter_label     varchar(2)
    date_ly                  date
);
