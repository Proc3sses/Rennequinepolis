create or replace PROCEDURE CHECK_VARCHAR_LENGTH 
(
  V_STR IN OUT VARCHAR2 -- in out: permet de modifier le paramètre en entrée
, V_ID_MOVIE IN VARCHAR2 
, V_TABLE IN VARCHAR2 
, V_COLONNE IN VARCHAR2 
) AS 
    max_nb number;
BEGIN
    DBMS_OUTPUT.PUT_LINE('CHECK_VARCHAR_LENGTH str='|| v_str ||'; id=' || v_id_movie || '.');

    -- récupère la taille max de la colonne
    SELECT CHAR_LENGTH INTO MAX_NB 
    FROM user_tab_columns t 
    WHERE t.table_name = upper(V_TABLE) AND t.column_name = upper(V_COLONNE);
    
    -- si il faut tronquer:
    IF LENGTH(V_STR) > MAX_NB THEN
        ADD_LOG('INFO', 'Valeur à insérer dans ' || v_table || ':' || v_colonne || ' pour id=' || v_id_movie || ' trop grande, tronquée à ' || max_nb || ' caractères (initialement ' || LENGTH(V_STR) || ' caractères).');
        v_str := SUBSTR(v_str, 1, max_nb-3) || '...';
    END IF;
    
    EXCEPTION
     WHEN NO_DATA_FOUND
       THEN ADD_LOG('ERREUR', v_table || ':' || v_colonne || ' non trouvé');
    WHEN OTHERS
      THEN ADD_LOG('ERREUR: ', SQLCODE || ': ' || SQLERRM);
END CHECK_VARCHAR_LENGTH;