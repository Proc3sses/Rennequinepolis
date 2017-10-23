-- Analyse sur les NUMBER et VARCHAR2
DECLARE
  reqChar varchar2(1000);
  reqNbr varchar2(1000);
  maxi number;
  mini number;
  moy number;
  mediane number;
  ecart_type number;
  nb_val integer;
  nb_valNull integer;
  nb_valNotNull integer;
  nb_valZero integer;
  nb_valUnique integer;
  quant95 integer;

BEGIN
  FOR col IN (
    select column_name, data_type 
    from ALL_TAB_COLUMNS 
    where TABLE_NAME = 'MOVIES_EXT' AND COLUMN_NAME != 'ACTORS' AND COLUMN_NAME != 'GENRES' AND COLUMN_NAME != 'DIRECTORS'
    )
  LOOP
  
    IF col.data_type = 'VARCHAR2' -- traitement sur les varchar
    THEN
      reqChar := 'select min(length(' || col.column_name || ')) as minimum, ' ||
       'max(length(' || col.column_name || ')) as maximum, ' ||
       'round(avg(length(' || col.column_name || ')), 3) as moyenne, ' ||
       'median(length(' || col.column_name || ')) as medianne, ' ||
       'round(stddev(length(' || col.column_name || ')), 3) as ecart_type, ' ||
       'count(*) as nb_Val, ' ||
       'count(' || col.column_name || ') as nb_ValNotNull, ' ||
       'sum(case when ' || col.column_name || ' is null then 1 else 0 end) as nb_ValNull, ' ||
       'sum(decode(length(' || col.column_name ||') , 0, 1, 0)) as nb_ValZero, ' ||
       'count(distinct (' || col.column_name || ')) as nb_valUnique, ' ||
       'percentile_cont(0.95) within group (order by length(' || col.column_name || ')) as quant95 ' ||
       'from MOVIES_EXT';

       EXECUTE IMMEDIATE reqChar INTO mini, maxi, moy, mediane, ecart_type, nb_val, nb_valNotNull, nb_valNull, nb_valZero, nb_valUnique, quant95;


                         
    ELSIF col.data_type = 'NUMBER' -- traitement sur les number
    THEN
      reqNbr :=  'select min(' || col.column_name || ') as minimum, ' ||
       'max(' || col.column_name || ') as maximum, ' ||
       'round(avg(' || col.column_name || '), 3) as moyenne, ' ||
       'median(' || col.column_name || ') as medianne, ' ||
       'round(stddev(' || col.column_name || '), 3) as ecart_type, ' ||
       'count(*) as nb_Val, ' ||
       'count(' || col.column_name || ') as nb_ValNotNull, ' ||
       'sum(case when ' || col.column_name || ' is null then 1 else 0 end) as nb_ValNull, ' ||
       'sum(decode(' || col.column_name ||' , 0, 1, 0)) as nb_ValZero, ' ||
       'count(distinct (' || col.column_name || ')) as nb_valUnique, ' ||
       'percentile_cont(0.95) within group (order by ' || col.column_name || ') as quant95 ' ||
       'from MOVIES_EXT';
       
       EXECUTE IMMEDIATE reqNbr INTO mini, maxi, moy, mediane, ecart_type, nb_Val, nb_ValNotNull, nb_ValNull, nb_ValZero, nb_valUnique, quant95;
    
    ELSE
      null;
    END IF;
        DBMS_OUTPUT.put_line('Colonne: ' || col.column_name);
        DBMS_OUTPUT.put_line('minimum: ' || mini || ' | maximum: ' || maxi || ' | moyenne: ' || moy || ' | mediane: ' || mediane || ' | ecart type: ' || ecart_type);
        DBMS_OUTPUT.put_line('nombre de valeurs: ' || nb_val || ' | nombre de valeurs non nulles: ' || nb_ValNotNull 
                         || ' | nombre de valeurs nulles: ' || nb_valNull);
        DBMS_OUTPUT.put_line('nombre de valeurs égales à 0: ' || nb_valZero || ' | nombre de valeurs uniques: ' || nb_valUnique || ' | 95eme quantile: ' || quant95);
        DBMS_OUTPUT.NEW_LINE;
        
  END LOOP;
END;