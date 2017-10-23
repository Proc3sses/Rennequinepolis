WITH data AS
(
    SELECT MOVIES_EXT.*, regexp_count(ACTORS, UNISTR('\2016')) + 1 AS nb_actors FROM MOVIES_EXT WHERE rownum < 10
),
temp(id, actors, actor_id, actor_nom, actor_perso, idx, nb_actors) AS
(
    SELECT
        id,
        actors,
        trim(regexp_substr(ACTORS, UNISTR('[^\2016\2024]+'), 1, 1)), 
        trim(regexp_substr(ACTORS, UNISTR('[^\2016\2024]+'), 1, 2)),
        trim(regexp_substr(ACTORS, UNISTR('[^\2016\2024]+'), 1, 3)),
        1,
        nb_actors
    FROM data
    WHERE nb_actors IS NOT NULL AND nb_actors > 0
    
    UNION ALL    
    
    SELECT
        id,
        actors,
        trim(regexp_substr(ACTORS, UNISTR('[^\2016\2024]+'), 1, idx*3+1)), 
        trim(regexp_substr(ACTORS, UNISTR('[^\2016\2024]+'), 1, idx*3+2)),
        trim(regexp_substr(ACTORS, UNISTR('[^\2016\2024]+'), 1, idx*3+3)),
        idx + 1,
        nb_actors
    FROM temp
    WHERE idx < nb_actors
)
SELECT id, actor_id, actor_nom, actor_perso FROM temp ORDER BY id;
-- WITHOUT DISTINCT: 218,893 sec for ROWNUM <= 1000