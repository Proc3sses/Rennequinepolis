create or replace PROCEDURE TRIM_CHAINE (v_string IN OUT VARCHAR2) AS 
    v_trim VARCHAR2(10) := chr(9) || chr(10) || chr(13) || ' ';
    -- chr(9): \t
    -- chr(10): \n
    -- chr(13): \r
BEGIN
    DBMS_OUTPUT.PUT_LINE('TRIM_CHAINE');
    v_string:= LTRIM(RTRIM(v_string, v_trim), v_trim);
    
    EXCEPTION
        WHEN OTHERS THEN
            ADD_LOG('ERREUR', 'Erreur dans TRIM_CHAINE: ' || SQLCODE || ': ' || SQLERRM);
END TRIM_CHAINE;