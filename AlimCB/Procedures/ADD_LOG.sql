create or replace PROCEDURE ADD_LOG(V_TYPE IN VARCHAR2, V_MESSAGE IN VARCHAR2) AS 
    PRAGMA AUTONOMOUS_TRANSACTION; -- transaction séparée de la transaction de traitement
    msg VARCHAR2(200);
BEGIN
  DBMS_OUTPUT.PUT_LINE('Ajout d''un log d''' || lower(V_TYPE));
  msg := SUBSTR(V_MESSAGE, 1, 200); -- on limite la taille du msg à 200 (pour éviter un problème lors de l'insertion)
  
  IF(UPPER(V_TYPE) = 'ERREUR') THEN
    INSERT INTO ERREURS(ID, MESSAGE, ERREUR_DATE) VALUES(SEQ_ERREURS.NEXTVAL, msg, sysdate);
  ELSE
    INSERT INTO INFOS(ID, MESSAGE, INFO_DATE) VALUES(SEQ_INFOS.NEXTVAL, msg, sysdate);
  END IF;
  
  commit;
  EXCEPTION
    WHEN OTHERS THEN
      ADD_LOG('ERREUR', 'Erreur dans ADD_LOG: ' || SQLCODE || ': ' || SQLERRM);
END ADD_LOG;