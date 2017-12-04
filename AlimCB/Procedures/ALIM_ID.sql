create or replace PROCEDURE ALIM_ID(list_id TAB_MOVIE_ID) AS 
BEGIN
    DBMS_OUTPUT.PUT_LINE('ALIM_ID');
    FOR i IN 1..list_id.count LOOP
        ADD_MOVIE(list_id(i));
    END LOOP;
    
    EXCEPTION
        WHEN TOO_MANY_ROWS THEN 
            ADD_LOG('ERREUR', 'Erreur dans ALIM_ID: Trop de tuples');
        WHEN NO_DATA_FOUND THEN 
            ADD_LOG('ERREUR', 'Erreur dans ALIM_ID: Pas de données');
        WHEN OTHERS THEN
            ADD_LOG('ERREUR', 'Erreur dans ALIM_ID: ' || SQLCODE || ': ' || SQLERRM);
END ALIM_ID;