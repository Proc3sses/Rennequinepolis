create or replace PROCEDURE ALIM_NBR (nbr IN NUMBER) AS 
    EX_NBR EXCEPTION;
BEGIN
    DBMS_OUTPUT.PUT_LINE('ALIM_NBR, n=' || nbr);
    IF (nbr <= 0) THEN
        RAISE EX_NBR;
    END IF;
    
    FOR movie IN (SELECT ID FROM (SELECT ID FROM movies_ext ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM <= nbr) LOOP
        ADD_MOVIE(movie.id);
    END LOOP;
    
    EXCEPTION
        WHEN EX_NBR THEN
            ADD_LOG('ERREUR', 'Erreur dans ALIM_NBR: nbr <= 0');
        WHEN TOO_MANY_ROWS THEN 
            ADD_LOG('ERREUR', 'Erreur dans ALIM_NBR: Trop de tuples');
        WHEN NO_DATA_FOUND THEN 
            ADD_LOG('ERREUR', 'Erreur dans ALIM_NBR: Pas de données');
        WHEN OTHERS THEN
            ADD_LOG('ERREUR', 'Erreur dans ALIM_NBR: ' || SQLCODE || ': ' || SQLERRM);
END ALIM_NBR;