select 
    TO_CHAR(min(release_date), 'DD/MM/YYYY') as Min,
    TO_CHAR(max(release_date), 'DD/MM/YYYY') as Max, 
    TO_CHAR(percentile_cont(0.95) within group (order by release_date), 'DD/MM/YYYY') as Quant95,
    sum(case when release_date is NULL then 1 else 0 end) as NbrNull,
    sum(case when (release_date >= to_date('1886-01-01', 'YYYY-MM-DD') and release_date <= sysdate) then 1 else 0 end) as NbrValide
from Movies_ext ;