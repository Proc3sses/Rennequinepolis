DECLARE
    -- id realisateur
  max_id number;
  nb_val_id integer;
  nb_valNull_id integer;
  nb_valUnique_id integer;

    -- nom realisateur
  max_nom number;
  min_nom number;
  moy_nom number;
  mediane_nom number;
  ecart_type_nom number;
  nb_val_nom integer;
  nb_valZero_nom integer;
  nb_valUnique_nom integer;
  quant95_nom integer;

BEGIN
    
    WITH temp (id, chaine, start_pos, end_pos) AS 
        (
            select 
                id, directors, 1, instr(directors, UNISTR('\2016'), 1) -- on r�cup�re la position du premier caract�re de s�paration
            from movies_ext 
            where directors is not null -- uniquement pour les films qui contiennent des r�alisateurs
            
            union all
            
            select 
                id, chaine, end_pos + 1, instr(chaine, UNISTR('\2016'), end_pos + 1) -- on r�cup�re la position du caract�re de s�paration suivant
            from temp 
            where end_pos != 0 -- ssi le caract�re de s�paration a �t� trouv� dans la pr�c�dente recherche
        ),
    str_reals AS -- contient une ligne par realisateur, avec colonne id du film et str_real = id+nom (s�par�s part s�parateur type 2)
        (
            select 
                id,
                substr(chaine, start_pos, 
                    (case when end_pos = 0 
                    then length(chaine) + 1 -- si le s�parateur type 1 n'a pas �t� trouv�, c'est le dernier real => on va jusqu'� la fin de la cha�ne
                    else end_pos end) - start_pos) -- substr: troisi�me argument, longueur de la chaine � extraire => on retire la position de d�part
                AS str_real
            from temp
        ),
    str_reals_pos_id AS -- on r�cup�re en plus de id et str_real, la position du premier s�parateur type 2 dans str_real
        (
            select
                id,
                str_real,
                instr(str_real, UNISTR('\2024'), 1) as pos_id
            from str_reals
        ),
    realisateurs AS -- on r�cup�re l'id et le nom du r�alisateur en utilisant les positions calcul�es auparavant
        (
            select
                id,
                substr(str_real, 1, pos_id - 1) AS id_real,
                substr(str_real, pos_id + 1, length(str_real) - pos_id) AS nom_real -- nom realisateur: entre les deux s�parateurs type 2 (/!\ troisi�me argument: longueur de chaine)
            from str_reals_pos_id
        )
    select 
        max(id_real) as max_id,
        count(id_real) nb_Val_id,
        sum(case when id_real is null then 1 else 0 end) nb_ValNull_id,
        count(distinct id_real) nb_ValUnique_id,
    
        min(length(nom_real)) as minimum_nom, 
        max(length(nom_real)) as maximum_nom, 
        round(avg(length(nom_real)), 3) as moyenne_nom, 
        median(length(nom_real)) as mediane_nom, 
        round(stddev(length(nom_real)), 3) as ecart_type_nom, 
        count(nom_real) as nb_Val_nom, 
        sum(decode(length(nom_real) , 0, 1, 0)) as nb_ValZero_nom, 
        count(distinct (nom_real)) as nb_valUnique_nom,
        percentile_cont(0.95) within group (order by length(nom_real)) as quant95_nom
        
    into
        
        max_id, nb_val_id, nb_valNull_id, nb_valUnique_id,
        min_nom, max_nom, moy_nom, mediane_nom, ecart_type_nom, nb_val_nom, nb_valZero_nom, nb_valUnique_nom, quant95_nom
        
    from realisateurs;
    
    DBMS_OUTPUT.put_line('Colonne: id realisateur');
    DBMS_OUTPUT.put_line('maximum: ' || max_id || ' | nombre de valeurs: ' || nb_val_id || 
        ' | nombre de valeurs nulles: ' || nb_valNull_id || ' | nombre de valeurs uniques: ' || nb_valUnique_id);
    DBMS_OUTPUT.NEW_LINE;

    DBMS_OUTPUT.put_line('Colonne: nom realisateur');
    DBMS_OUTPUT.put_line('minimum: ' || min_nom || ' | maximum: ' || max_nom || ' | moyenne: ' || moy_nom || 
        ' | mediane: ' || mediane_nom || ' | ecart type: ' || ecart_type_nom);
    DBMS_OUTPUT.put_line('nombre de valeurs: ' || nb_val_nom || ' | nombre de valeurs �gales � 0: ' || nb_valZero_nom 
        || ' | nombre de valeurs uniques: ' || nb_valUnique_nom || ' | 95eme quantile: ' || quant95_nom);
    DBMS_OUTPUT.NEW_LINE;
end;