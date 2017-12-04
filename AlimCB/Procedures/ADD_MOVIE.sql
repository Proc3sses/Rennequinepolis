create or replace PROCEDURE ADD_MOVIE (id_param IN NUMBER) AS 
    v_movie_exists NUMBER; -- vaut 1 si le film est déjà présent
    v_movie_ajoute NUMBER := 0; -- vaut 1 si le film a été ajouté (pas d'erreur)

    v_title VARCHAR2(393);
    v_original_title VARCHAR2(393);
    v_status VARCHAR2(15);
    v_release_date DATE;
    v_vote_average NUMBER;
    v_vote_count NUMBER;
    v_certification VARCHAR2(12);
    v_runtime NUMBER;
    v_str_actors VARCHAR2(9562); -- max(length(actors))
    v_str_directors VARCHAR2(731); -- max(length(directors))
    v_str_genres VARCHAR2(159); -- max(length(genres))
    v_poster_path VARCHAR2(32);
    
    v_id_certif NUMBER;
    v_id_status NUMBER;
    
    v_end_pos NUMBER;
    v_last_entry NUMBER;
    v_pos_id NUMBER;
    v_pos_name NUMBER;
    
    v_id_artist NUMBER;
    v_name_artist VARCHAR2(283);
    v_artist_exists NUMBER;
    
    v_id_genre NUMBER;
    v_name_genre VARCHAR2(16);
    v_genre_exists NUMBER;
    
    v_poster BLOB;
    
    -- Exceptions lancées si violation de contrainte
    EX_NOT_NULL EXCEPTION;
    PRAGMA EXCEPTION_INIT(EX_NOT_NULL, -1400);
    EX_UNIQUE EXCEPTION;
    PRAGMA EXCEPTION_INIT(EX_UNIQUE, -00001);
    EX_FKEY EXCEPTION;
    PRAGMA EXCEPTION_INIT(EX_FKEY, -2291);
    EX_CHECK EXCEPTION;
    PRAGMA EXCEPTION_INIT(EX_CHECK, -2290);
BEGIN
    DBMS_OUTPUT.PUT_LINE('ADD_MOVIE id=' || id_param || '.');
  
    SELECT COUNT(*) INTO v_movie_exists FROM movie WHERE id = id_param;
    
    IF(v_movie_exists = 0) THEN -- film n'est pas déjà dans la base
        
      SELECT title, original_title, status, release_date,
      vote_average, vote_count, certification, runtime,
      poster_path, actors, directors, genres
          INTO v_title, v_original_title, v_status, v_release_date,
          v_vote_average, v_vote_count, v_certification, v_runtime,
          v_poster_path, v_str_actors, v_str_directors, v_str_genres
      FROM MOVIES_EXT WHERE ID = id_param;
      
      --suppression des espaces blancs:
      TRIM_CHAINE(v_title);
      TRIM_CHAINE(v_original_title);
      TRIM_CHAINE(v_status);
      TRIM_CHAINE(v_certification);
      TRIM_CHAINE(v_poster_path);
      
      -- vérification des longueurs max:
      CHECK_VARCHAR_LENGTH(v_title, id_param, 'MOVIE', 'TITLE');
      CHECK_VARCHAR_LENGTH(v_original_title, id_param, 'MOVIE', 'ORIGINAL_TITLE');
      
      -- vérification de la certification
      BEGIN
        SELECT id INTO v_id_certif 
        FROM certification 
        WHERE upper(name) = upper(v_certification);
        
        EXCEPTION
        WHEN NO_DATA_FOUND THEN 
            ADD_LOG('INFO', 'La certification pour le film id ' || id_param ||' (valeur: ' || v_certification || ') n''est pas valide. Elle est remplacée par NULL.');
            v_id_certif := NULL;
      END;
      
      -- vérification du status
      BEGIN
        SELECT id INTO v_id_status 
        FROM status 
        WHERE upper(name) = upper(v_status);
        
        EXCEPTION
        WHEN NO_DATA_FOUND THEN 
            ADD_LOG('INFO', 'Le status pour le film id ' || id_param ||' (valeur: ' || v_status || ') n''est pas valide. Il est remplacé par NULL.');
            v_id_status := NULL;
      END;
      
      -- vérifiaction de la date de sortie
      IF(v_release_date < date '1886-01-01') THEN
        ADD_LOG('INFO', 'La date pour le film id ' || id_param ||' (valeur: ' || v_release_date || ') n''est pas valide. Elle est remplacée par NULL.');
        v_release_date := NULL;
      END IF;
      
      -- vérification de la moyenne des votes
      IF(v_vote_average < 0) THEN
        ADD_LOG('INFO', 'La moyenne des votes pour le film id ' || id_param ||' (valeur: ' || v_vote_average || ') n''est pas valide. Elle est remplacée par NULL.');
        v_vote_average := NULL;
      END IF;
      
      -- vérification du total de votes
      IF(v_vote_count < 0) THEN
        ADD_LOG('INFO', 'Le total des votes pour le film id ' || id_param ||' (valeur: ' || v_vote_count || ') n''est pas valide. Il est remplacé par NULL.');
        v_vote_count := NULL;
      END IF;
      
      -- vérification du runtime
      IF(v_runtime < 0 OR v_runtime > 999) THEN
        ADD_LOG('INFO', 'Le runtime pour le film id ' || id_param ||' (valeur: ' || v_runtime || ') n''est pas valide. Il est remplacé par NULL.');
        v_runtime := NULL;
      END IF;
      
      BEGIN
      -- on insère le film dans la table
        v_movie_ajoute := 0;
        INSERT INTO MOVIE(ID, TITLE, ORIGINAL_TITLE, STATUS, RELEASE_DATE, VOTE_AVERAGE, VOTE_COUNT, CERTIFICATION, RUNTIME)
          VALUES(id_param, v_title, v_original_title, v_id_status, v_release_date, v_vote_average, v_vote_count, v_id_certif, v_runtime);
        v_movie_ajoute := 1; -- si pas d'erreur, on peut ajouter acteurs, genres...
        
        EXCEPTION
            WHEN EX_NOT_NULL THEN
                IF(INSTR(SQLERRM, 'MOVIE$TITLE$NN') <> 0) THEN
                    ADD_LOG('ERREUR', 'Le titre du film ne peut être null: ' || SQLCODE || ': ' || SQLERRM);
                END IF;
            WHEN EX_UNIQUE THEN
                IF(INSTR(SQLERRM, 'MOVIE$PK') <> 0) THEN
                    ADD_LOG('ERREUR', 'Le film existe déjà: ' || SQLCODE || ': ' || SQLERRM);
                END IF;
            WHEN EX_FKEY  THEN
                IF(INSTR(SQLERRM, 'MOVIE$STATUS$FK') <> 0) THEN
                    ADD_LOG('ERREUR', 'Le statut n''existe pas: ' || SQLCODE || ': ' || SQLERRM);
                ELSIF(INSTR(SQLERRM, 'MOVIE$CERT$FK') <> 0) THEN
                    ADD_LOG('ERREUR', 'La certification n''existe pas: ' || SQLCODE || ': ' || SQLERRM);
                END IF;
            WHEN EX_CHECK  THEN
                IF(INSTR(SQLERRM, 'MOVIE$ID$POS') <> 0) THEN
                    ADD_LOG('ERREUR', 'L''id du film doit être >= 0: ' || SQLCODE || ': ' || SQLERRM);
                ELSIF(INSTR(SQLERRM, 'MONDE$RELEASE_DATE$MINI') <> 0) THEN
                    ADD_LOG('ERREUR', 'La date de sortie doit être plus récente que 1886: ' || SQLCODE || ': ' || SQLERRM);
                ELSIF(INSTR(SQLERRM, 'MOVIE$VOTE_AVERAGE$POS') <> 0) THEN
                    ADD_LOG('ERREUR', 'La moyenne des votes doit être >= 0: ' || SQLCODE || ': ' || SQLERRM);
                ELSIF(INSTR(SQLERRM, 'MOVIE$VOTE_COUNT$POS') <> 0) THEN
                    ADD_LOG('ERREUR', 'Le total de votes doit être >= 0: ' || SQLCODE || ': ' || SQLERRM);
                ELSIF(INSTR(SQLERRM, 'MOVIE$RUNTIME$POS') <> 0) THEN
                    ADD_LOG('ERREUR', 'Le runtime doit être >= 0: ' || SQLCODE || ': ' || SQLERRM);
                END IF;
            WHEN OTHERS THEN
                ADD_LOG('ERREUR', 'Erreur: ' || SQLCODE || ': ' || SQLERRM);
      END;
      
      IF(v_movie_ajoute > 0) THEN-- le film a été ajouté, on peut continuer
          -- ACTEURS 
          IF(v_str_actors IS NOT NULL) THEN  
              v_last_entry := 0;
              LOOP
                BEGIN
                v_end_pos := instr(v_str_actors, UNISTR('\2016'), 1); 
              
                IF(v_end_pos = 0) THEN
                    v_end_pos := LENGTH(v_str_actors) + 1;
                    v_last_entry := 1;
                END IF;
                
                DBMS_OUTPUT.PUT_LINE('Acteur: ' || SUBSTR(v_str_actors, 1, v_end_pos-1));
                v_pos_id := instr(v_str_actors, UNISTR('\2024'), 1);
                v_id_artist := to_number(substr(v_str_actors, 1, v_pos_id - 1));
                
                SELECT COUNT(*) INTO v_artist_exists FROM artist WHERE id = v_id_artist;
                IF (v_artist_exists = 0) THEN
                    v_pos_name := instr(v_str_actors, UNISTR('\2024'), v_pos_id + 1);
                    v_name_artist := substr(v_str_actors, v_pos_id + 1, v_pos_name - 1 - v_pos_id);
                    
                    TRIM_CHAINE(v_name_artist);
                    CHECK_VARCHAR_LENGTH(v_name_artist, v_id_artist, 'ARTIST', 'NAME');
                    
                    INSERT INTO ARTIST(ID, NAME) VALUES(v_id_artist, v_name_artist);
                    ADD_LOG('INFO', 'L''artiste avec id ' || v_id_artist ||' a été importé avec succès.');
                END IF;
                
                INSERT INTO MOVIE_ACTOR(MOVIE, ACTOR) VALUES(id_param, v_id_artist);
                ADD_LOG('INFO', 'Le film avec id ' || id_param ||' a été associé avec l''acteur id ' || v_id_artist || '.');
              
                v_str_actors := substr(v_str_actors, v_end_pos + 1);
                
                EXIT WHEN v_last_entry = 1;
                
                EXCEPTION
                WHEN EX_NOT_NULL THEN
                  IF(INSTR(SQLERRM, 'ARTIST$NAME$NN') <> 0) THEN
                    ADD_LOG('ERREUR', 'Le nom de l''artiste ne peut être null: ' || SQLCODE || ': ' || SQLERRM);
                  END IF;
                WHEN EX_UNIQUE THEN
                  IF(INSTR(SQLERRM, 'ARTIST$PK') <> 0) THEN
                    ADD_LOG('ERREUR', 'L''artiste existe déjà: ' || SQLCODE || ': ' || SQLERRM);
                  ELSIF(INSTR(SQLERRM, 'M_A$PK') <> 0) THEN
                    ADD_LOG('ERREUR', 'L''association artiste-film existe déjà: ' || SQLCODE || ': ' || SQLERRM);
                  END IF;
                WHEN EX_FKEY  THEN
                  IF(INSTR(SQLERRM, 'MOVIE_ACTOR$MOVIE$FK') <> 0) THEN
                    ADD_LOG('ERREUR', 'Le film n''existe pas: ' || SQLCODE || ': ' || SQLERRM);
                  ELSIF(INSTR(SQLERRM, 'MOVIE_ACTOR$ACTOR$FK') <> 0) THEN
                    ADD_LOG('ERREUR', 'L''artiste n''existe pas: ' || SQLCODE || ': ' || SQLERRM);
                  END IF;
                WHEN EX_CHECK  THEN
                  IF(INSTR(SQLERRM, 'ARTIST$ID$POS') <> 0) THEN
                    ADD_LOG('ERREUR', 'L''id de l''artiste doit être >= 0: ' || SQLCODE || ': ' || SQLERRM);
                  END IF;
                WHEN OTHERS THEN
                    ADD_LOG('ERREUR', 'Erreur: ' || SQLCODE || ': ' || SQLERRM);
                 END;
              END LOOP;
          END IF;
          DBMS_OUTPUT.PUT_LINE('Partie acteurs terminée');
          
          -- REALISATEURS
          IF(v_str_directors IS NOT NULL) THEN
              v_last_entry := 0;
              LOOP
                BEGIN
                v_end_pos := instr(v_str_directors, UNISTR('\2016'), 1);   
              
                IF(v_end_pos = 0) THEN
                    v_end_pos := LENGTH(v_str_directors) + 1;
                    v_last_entry := 1;
                END IF;
                
                DBMS_OUTPUT.PUT_LINE('Réalisateur: ' || SUBSTR(v_str_actors, 1, v_end_pos-1));
                v_pos_id := instr(v_str_directors, UNISTR('\2024'), 1);
                v_id_artist := to_number(substr(v_str_directors, 1, v_pos_id - 1));
                
                SELECT COUNT(*) INTO v_artist_exists FROM artist WHERE id = v_id_artist;
                IF (v_artist_exists = 0) THEN
                    v_name_artist := substr(v_str_directors, v_pos_id + 1, v_end_pos - 1 - v_pos_id);
                    
                    TRIM_CHAINE(v_name_artist);
                    CHECK_VARCHAR_LENGTH(v_name_artist, v_id_artist, 'ARTIST', 'NAME');
                    
                    INSERT INTO ARTIST(ID, NAME) VALUES(v_id_artist, v_name_artist);
                    ADD_LOG('INFO', 'L''artiste avec id ' || v_id_artist ||' a été importé avec succès.');
                END IF;
                
                INSERT INTO MOVIE_DIRECTOR(MOVIE, DIRECTOR) VALUES(id_param, v_id_artist);
                ADD_LOG('INFO', 'Le film avec id ' || id_param ||' a été associé avec le réalisateur id ' || v_id_artist || '.');
              
                v_str_directors := substr(v_str_directors, v_end_pos + 1);
                
                EXIT WHEN v_last_entry = 1;
                
                EXCEPTION
                WHEN EX_NOT_NULL THEN
                  IF(INSTR(SQLERRM, 'ARTIST$NAME$NN') <> 0) THEN
                    ADD_LOG('ERREUR', 'Le nom de l''artiste ne peut être null: ' || SQLCODE || ': ' || SQLERRM);
                  END IF;
                WHEN EX_UNIQUE THEN
                  IF(INSTR(SQLERRM, 'ARTIST$PK') <> 0) THEN
                    ADD_LOG('ERREUR', 'L''artiste existe déjà: ' || SQLCODE || ': ' || SQLERRM);
                  ELSIF(INSTR(SQLERRM, 'M_D$PK') <> 0) THEN
                    ADD_LOG('ERREUR', 'L''association réalisateur-film existe déjà: ' || SQLCODE || ': ' || SQLERRM);
                  END IF;
                WHEN EX_FKEY  THEN
                  IF(INSTR(SQLERRM, 'MOVIE_DIRECTOR$MOVIE$FK') <> 0) THEN
                    ADD_LOG('ERREUR', 'Le film n''existe pas: ' || SQLCODE || ': ' || SQLERRM);
                  ELSIF(INSTR(SQLERRM, 'MOVIE_DIRECTOR$DIRECTOR$FK') <> 0) THEN
                    ADD_LOG('ERREUR', 'Le réalisateur n''existe pas: ' || SQLCODE || ': ' || SQLERRM);
                  END IF;
                WHEN EX_CHECK  THEN
                  IF(INSTR(SQLERRM, 'ARTIST$ID$POS') <> 0) THEN
                    ADD_LOG('ERREUR', 'L''id de l''artiste doit être >= 0: ' || SQLCODE || ': ' || SQLERRM);
                  END IF;
                WHEN OTHERS THEN
                    ADD_LOG('ERREUR', 'Erreur: ' || SQLCODE || ': ' || SQLERRM);
                 END;
              END LOOP;
          END IF;
          DBMS_OUTPUT.PUT_LINE('Partie réalisateurs terminée');
          
          -- GENRES
          IF(v_str_genres IS NOT NULL) THEN
              v_last_entry := 0;
              LOOP
                BEGIN
                v_end_pos := instr(v_str_genres, UNISTR('\2016'), 1);   
              
                IF(v_end_pos = 0) THEN
                    v_end_pos := LENGTH(v_str_genres) + 1;
                    v_last_entry := 1;
                END IF;
                
                v_pos_id := instr(v_str_genres, UNISTR('\2024'), 1);
                v_id_genre := to_number(substr(v_str_genres, 1, v_pos_id - 1));
                
                SELECT COUNT(*) INTO v_genre_exists FROM genre WHERE id = v_id_genre;
                IF(v_genre_exists = 0) THEN
                    v_name_genre := substr(v_str_genres, v_pos_id + 1, v_end_pos - 1 - v_pos_id);
                    
                    TRIM_CHAINE(v_name_genre);
                    CHECK_VARCHAR_LENGTH(v_name_genre, v_id_genre, 'GENRE', 'NAME');
                    
                    INSERT INTO GENRE(ID, NAME) VALUES(v_id_genre, v_name_genre);
                    ADD_LOG('INFO', 'Le genre avec id ' || v_id_genre ||' a été importé avec succès.');
                END IF;
                
                INSERT INTO MOVIE_GENRE(MOVIE, GENRE) VALUES(id_param, v_id_genre);
                ADD_LOG('INFO', 'Le film avec id ' || id_param ||' a été associé avec le genre id ' || v_id_genre || '.');
              
                v_str_genres := substr(v_str_genres, v_end_pos + 1);
                
                EXIT WHEN v_last_entry = 1;
                
                EXCEPTION
                WHEN EX_NOT_NULL THEN
                  IF(INSTR(SQLERRM, 'GENRE$NAME$NN') <> 0) THEN
                    ADD_LOG('ERREUR', 'Le nom du genre ne peut être null: ' || SQLCODE || ': ' || SQLERRM);
                  END IF;
                WHEN EX_UNIQUE THEN
                  IF(INSTR(SQLERRM, 'GENRE$PK ') <> 0) THEN
                    ADD_LOG('ERREUR', 'Le genre existe déjà: ' || SQLCODE || ': ' || SQLERRM);
                  ELSIF(INSTR(SQLERRM, 'M_G$PK') <> 0) THEN
                    ADD_LOG('ERREUR', 'L''association genre-film existe déjà: ' || SQLCODE || ': ' || SQLERRM);
                  END IF;
                WHEN EX_FKEY  THEN
                  IF(INSTR(SQLERRM, 'MOVE_GENRE$GENRE$FK') <> 0) THEN
                    ADD_LOG('ERREUR', 'Le genre n''existe pas: ' || SQLCODE || ': ' || SQLERRM);
                  ELSIF(INSTR(SQLERRM, 'MOVIE_GENRE$MOVIE$FK') <> 0) THEN
                    ADD_LOG('ERREUR', 'Le film n''existe pas: ' || SQLCODE || ': ' || SQLERRM);
                  END IF;
                WHEN EX_CHECK  THEN
                  IF(INSTR(SQLERRM, 'GENRE$ID$POS') <> 0) THEN
                    ADD_LOG('ERREUR', 'L''id du genre doit être >= 0: ' || SQLCODE || ': ' || SQLERRM);
                  END IF;
                WHEN OTHERS THEN
                    ADD_LOG('ERREUR', 'Erreur: ' || SQLCODE || ': ' || SQLERRM);
                 END;
              END LOOP;
          END IF;
          DBMS_OUTPUT.PUT_LINE('Partie genres terminée');
          
          -- IMAGE (BLOB)
          BEGIN
          IF(v_poster_path IS NOT NULL) THEN
             v_poster := httpuritype.createuri(CONCAT('http://image.tmdb.org/t/p/w185', v_poster_path)).getblob();
             INSERT INTO poster (id, file_content, movie) VALUES(SEQ_POSTER.nextval, v_poster, id_param);
          END IF;
          
          EXCEPTION
            WHEN OTHERS THEN
                ADD_LOG('ERREUR', 'Erreur d''ajout du poster: ' || SQLCODE || ': ' || SQLERRM);
          END;
          DBMS_OUTPUT.PUT_LINE('Partie image terminée');
          
          
          -- Si tout s'est bien passé
          COMMIT;
          ADD_LOG('INFO', 'Le film avec id ' || id_param ||' a été importé avec succès.');
          
      ELSE -- erreur lors de l'ajout du film -> rollback
        ADD_LOG('INFO', 'Le film avec id ' || id_param ||' n''a pas été importé');
        ROLLBACK;
      END IF;
      
  ELSE
      ADD_LOG('INFO', 'Le film avec id ' || id_param ||' est déjà dans CB.');
  END IF;
  
  EXCEPTION -- pour genres, réalisateurs et acteurs -> pas de rollback
     WHEN NO_DATA_FOUND
       THEN ADD_LOG('ERREUR', 'Le film avec id ' || id_param ||' n''a pas été trouvé dans la base de données');
    WHEN OTHERS
      THEN ADD_LOG('ERREUR', 'Erreur lors de l''ajout du film avec id ' || id_param ||': Erreur: ' || SQLCODE || ': ' || SQLERRM);
  
END ADD_MOVIE;