SELECT 
    to_char(date_c, 'yyyymmdd')::int as Date_ID,
    cast(date_c as date) as date,
    extract(month from date_c) as month,
    extract(year from date_c) as year,
    to_char(date_c, 'day') as weekday,
	
    CASE WHEN to_char(date_c, 'day') like '%saturday%' THEN 'True' 
		WHEN (to_char(date_c, 'day'))like '%sunday%' THEN 'True' 
		ELSE 'False' END as is_weekend,
	
	to_char(date_c, 'month') as month_label,
	case when date_c BETWEEN '20220201' AND '20230131' then '2022' 	else '2023' end as fiscal_year,
	case when date_c BETWEEN '20220201' AND '20230131' then 'FY2022' 	else 'FY2023' end as fiscal_year_label,
	
	case when extract(month from date_c) in (2,3,4) then 'Q1'
		when extract(month from date_c) in (5,6,7) then 'Q2'
		when extract(month from date_c) in (8,9,10) then 'Q3'
		when extract(month from date_c) in (11,12,1) then 'Q4' end as fiscal_quarter_label,
		
	CAST( date_c - interval '1 year' AS date) AS date_ly
	
FROM (
    SELECT cast('2022-02-01' as date) + (n || ' day')::interval as date_c
    FROM generate_series(0, 730) n
) dd;
