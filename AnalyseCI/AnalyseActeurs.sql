DECLARE
    -- id acteur
  max_id number;
  nb_val_id integer;
  nb_valNull_id integer;
  nb_valUnique_id integer;

    -- nom d'acteur
  max_nom number;
  min_nom number;
  moy_nom number;
  mediane_nom number;
  ecart_type_nom number;
  nb_val_nom integer;
  nb_valZero_nom integer;
  nb_valUnique_nom integer;
  quant95_nom integer;
  
    -- role acteur
  max_role number;
  min_role number;
  moy_role number;
  mediane_role number;
  ecart_type_role number;
  nb_val_role integer;
  nb_valZero_role integer;
  nb_valUnique_role integer;
  quant95_role integer;

BEGIN
    
    WITH temp (id, chaine, start_pos, end_pos) AS 
        (
            select 
                id, actors, 1,  instr(actors, UNISTR('\2016'), 1) -- on récupère la position du premier caractère de séparation
            from movies_ext 
            where actors is not null -- uniquement pour les films qui contiennent des acteurs
            
            union all
            
            select 
                id, chaine, end_pos + 1, instr(chaine, UNISTR('\2016'), end_pos + 1) -- on récupère la position du caractère de séparation suivant
            from temp 
            where end_pos != 0 -- ssi le caractère de séparation a été trouvé dans la précédente recherche
        ),
    str_acteurs AS -- contient une ligne par acteur, avec colonne id du film et str_acteur = id+nom+role (séparés part séparateur type 2)
        (
            select 
                id,
                substr(chaine, start_pos, 
                    (case when end_pos = 0 
                    then length(chaine) + 1 -- si le séparateur type 1 n'a pas été trouvé, c'est le dernier acteur => on va jusqu'à la fin de la chaîne
                    else end_pos end) - start_pos) -- substr: troisième argument, longueur de la chaine à extraire => on retire la position de départ
                AS str_acteur
            from temp
        ),
    str_acteurs_pos_id AS -- on récupère en plus de id et str_acteur, la position du premier séparateur type 2 dans str_acteur
        (
            select
                id,
                str_acteur,
                instr(str_acteur, UNISTR('\2024'), 1) as pos_id
            from str_acteurs
        ),
    str_acteurs_pos_nom AS -- on récupère l'id de l'acteur et la position du deuxième séparateur type 2 dans str_acteur
        (
            select
                id,
                str_acteur,
                pos_id,
                substr(str_acteur, 1, pos_id - 1) AS id_acteur, -- id acteur: entre caractère 1 et premier séparateur type 2
                instr(str_acteur, UNISTR('\2024'), pos_id + 1) AS pos_nom -- on commence la recherche juste après le premier séparateur type 2
            from str_acteurs_pos_id
        ),
    acteurs AS -- on récupère finalement le nom et role de l'acteur en utilisant les positions calculées auparavant
        (
            select
                id,
                id_acteur,
                substr(str_acteur, pos_id + 1, pos_nom - 1 - pos_id) AS nom_acteur, -- nom acteur: entre les deux séparateurs type 2 (/!\ troisième argument: longueur de chaine)
                substr(str_acteur, pos_nom + 1, length(str_acteur) - pos_nom) AS role_acteur -- role_acteur: entre deuxième séparateur type 2 et fin de la chaine
            from str_acteurs_pos_nom
        )
    select 
        max(id_acteur) as max_id,
        count(id_acteur) nb_Val_id,
        sum(case when id_acteur is null then 1 else 0 end) nb_ValNull_id,
        count(distinct id_acteur) nb_ValUnique_id,
    
        min(length(nom_acteur)) as minimum_nom, 
        max(length(nom_acteur)) as maximum_nom, 
        round(avg(length(nom_acteur)), 3) as moyenne_nom, 
        median(length(nom_acteur)) as mediane_nom, 
        round(stddev(length(nom_acteur)), 3) as ecart_type_nom, 
        count(nom_acteur) as nb_Val_nom, 
        sum(decode(length(nom_acteur) , 0, 1, 0)) as nb_ValZero_nom, 
        count(distinct (nom_acteur)) as nb_valUnique_nom,
        percentile_cont(0.95) within group (order by length(nom_acteur)) as quant95_nom,
        
        min(length(role_acteur)) as minimum_role, 
        max(length(role_acteur)) as maximum_role, 
        round(avg(length(role_acteur)), 3) as moyenne_role, 
        median(length(role_acteur)) as mediane_role, 
        round(stddev(length(role_acteur)), 3) as ecart_type_role, 
        count(role_acteur) as nb_Val_role, 
        sum(decode(length(role_acteur) , 0, 1, 0)) as nb_ValZero_role, 
        count(distinct (role_acteur)) as nb_valUnique_role,
        percentile_cont(0.95) within group (order by length(role_acteur)) as quant95_role
        
    into
        
        max_id, nb_val_id, nb_valNull_id, nb_valUnique_id,
        min_nom, max_nom, moy_nom, mediane_nom, ecart_type_nom, nb_val_nom, nb_valZero_nom, nb_valUnique_nom, quant95_nom,
        min_role, max_role, moy_role, mediane_role, ecart_type_role, nb_val_role, nb_valZero_role, nb_valUnique_role, quant95_role
        
    from acteurs;
    
    DBMS_OUTPUT.put_line('Colonne: id acteur');
    DBMS_OUTPUT.put_line('maximum: ' || max_id || ' | nombre de valeurs: ' || nb_val_id || 
        ' | nombre de valeurs nulles: ' || nb_valNull_id || ' | nombre de valeurs uniques: ' || nb_valUnique_id);
    DBMS_OUTPUT.NEW_LINE;

    DBMS_OUTPUT.put_line('Colonne: nom acteur');
    DBMS_OUTPUT.put_line('minimum: ' || min_nom || ' | maximum: ' || max_nom || ' | moyenne: ' || moy_nom || 
        ' | mediane: ' || mediane_nom || ' | ecart type: ' || ecart_type_nom);
    DBMS_OUTPUT.put_line('nombre de valeurs: ' || nb_val_nom || ' | nombre de valeurs égales à 0: ' || nb_valZero_nom 
        || ' | nombre de valeurs uniques: ' || nb_valUnique_nom || ' | 95eme quantile: ' || quant95_nom);
    DBMS_OUTPUT.NEW_LINE;
    
    DBMS_OUTPUT.put_line('Colonne: role acteur');
    DBMS_OUTPUT.put_line('minimum: ' || min_role || ' | maximum: ' || max_role || ' | moyenne: ' || moy_role || 
        ' | mediane: ' || mediane_role || ' | ecart type: ' || ecart_type_role);
    DBMS_OUTPUT.put_line('nombre de valeurs: ' || nb_val_role || ' | nombre de valeurs égales à 0: ' || nb_valZero_role 
        || ' | nombre de valeurs uniques: ' || nb_valUnique_role || ' | 95eme quantile: ' || quant95_role);
    DBMS_OUTPUT.NEW_LINE;
end;