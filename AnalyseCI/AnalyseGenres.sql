DECLARE
    -- id genre
  max_id number;
  nb_val_id integer;
  nb_valNull_id integer;
  nb_valUnique_id integer;

    -- nom genre
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
                id, genres, 1, instr(genres, UNISTR('\2016'), 1) -- on r�cup�re la position du premier caract�re de s�paration
            from movies_ext 
            where genres is not null -- uniquement pour les films qui contiennent des r�alisateurs
            
            union all
            
            select 
                id, chaine, end_pos + 1, instr(chaine, UNISTR('\2016'), end_pos + 1) -- on r�cup�re la position du caract�re de s�paration suivant
            from temp 
            where end_pos != 0 -- ssi le caract�re de s�paration a �t� trouv� dans la pr�c�dente recherche
        ),
    str_genres AS -- contient une ligne par genre, avec colonne id du film et str_genre = id+nom (s�par�s part s�parateur type 2)
        (
            select 
                id,
                substr(chaine, start_pos, 
                    (case when end_pos = 0 
                    then length(chaine) + 1 -- si le s�parateur type 1 n'a pas �t� trouv�, c'est le dernier genre => on va jusqu'� la fin de la cha�ne
                    else end_pos end) - start_pos) -- substr: troisi�me argument, longueur de la chaine � extraire => on retire la position de d�part
                AS str_genre
            from temp
        ),
    str_genres_pos_id AS -- on r�cup�re en plus de id et str_genre, la position du premier s�parateur type 2 dans str_genre
        (
            select
                id,
                str_genre,
                instr(str_genre, UNISTR('\2024'), 1) as pos_id
            from str_genres
        ),
    genres AS -- on r�cup�re l'id et le nom du r�alisateur en utilisant les positions calcul�es auparavant
        (
            select
                id,
                substr(str_genre, 1, pos_id - 1) AS id_genre,
                substr(str_genre, pos_id + 1, length(str_genre) - pos_id) AS nom_genre -- nom genre: entre les deux s�parateurs type 2 (/!\ troisi�me argument: longueur de chaine)
            from str_genres_pos_id
        )
    select 
        max(id_genre) as max_id,
        count(id_genre) nb_Val_id,
        sum(case when id_genre is null then 1 else 0 end) nb_ValNull_id,
        count(distinct id_genre) nb_ValUnique_id,
    
        min(length(nom_genre)) as minimum_nom, 
        max(length(nom_genre)) as maximum_nom, 
        round(avg(length(nom_genre)), 3) as moyenne_nom, 
        median(length(nom_genre)) as mediane_nom, 
        round(stddev(length(nom_genre)), 3) as ecart_type_nom, 
        count(nom_genre) as nb_Val_nom, 
        sum(decode(length(nom_genre) , 0, 1, 0)) as nb_ValZero_nom, 
        count(distinct (nom_genre)) as nb_valUnique_nom,
        percentile_cont(0.95) within group (order by length(nom_genre)) as quant95_nom
        
    into
        
        max_id, nb_val_id, nb_valNull_id, nb_valUnique_id,
        min_nom, max_nom, moy_nom, mediane_nom, ecart_type_nom, nb_val_nom, nb_valZero_nom, nb_valUnique_nom, quant95_nom
        
    from genres;
    
    DBMS_OUTPUT.put_line('Colonne: id genre');
    DBMS_OUTPUT.put_line('maximum: ' || max_id || ' | nombre de valeurs: ' || nb_val_id || 
        ' | nombre de valeurs nulles: ' || nb_valNull_id || ' | nombre de valeurs uniques: ' || nb_valUnique_id);
    DBMS_OUTPUT.NEW_LINE;

    DBMS_OUTPUT.put_line('Colonne: nom genre');
    DBMS_OUTPUT.put_line('minimum: ' || min_nom || ' | maximum: ' || max_nom || ' | moyenne: ' || moy_nom || 
        ' | mediane: ' || mediane_nom || ' | ecart type: ' || ecart_type_nom);
    DBMS_OUTPUT.put_line('nombre de valeurs: ' || nb_val_nom || ' | nombre de valeurs �gales � 0: ' || nb_valZero_nom 
        || ' | nombre de valeurs uniques: ' || nb_valUnique_nom || ' | 95eme quantile: ' || quant95_nom);
    DBMS_OUTPUT.NEW_LINE;
    
end;

