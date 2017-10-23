WITH temp (id, chaine, start_pos, end_pos) AS 
	(
		select 
			id, genres, 1, instr(genres, UNISTR('\2016'), 1) -- on récupère la position du premier caractère de séparation
		from movies_ext 
		where genres is not null -- uniquement pour les films qui contiennent des réalisateurs
		
		union all
		
		select 
			id, chaine, end_pos + 1, instr(chaine, UNISTR('\2016'), end_pos + 1) -- on récupère la position du caractère de séparation suivant
		from temp 
		where end_pos != 0 -- ssi le caractère de séparation a été trouvé dans la précédente recherche
	),
str_genres AS -- contient une ligne par genre, avec colonne id du film et str_genre = id+nom (séparés part séparateur type 2)
	(
		select 
			id,
			substr(chaine, start_pos, 
				(case when end_pos = 0 
				then length(chaine) + 1 -- si le séparateur type 1 n'a pas été trouvé, c'est le dernier genre => on va jusqu'à la fin de la chaîne
				else end_pos end) - start_pos) -- substr: troisième argument, longueur de la chaine à extraire => on retire la position de départ
			AS str_genre
		from temp
	),
str_genres_pos_id AS -- on récupère en plus de id et str_genre, la position du premier séparateur type 2 dans str_genre
	(
		select
			id,
			str_genre,
			instr(str_genre, UNISTR('\2024'), 1) as pos_id
		from str_genres
	),
genres AS -- on récupère l'id et le nom du réalisateur en utilisant les positions calculées auparavant
	(
		select
			id,
			substr(str_genre, 1, pos_id - 1) AS id_genre,
			substr(str_genre, pos_id + 1, length(str_genre) - pos_id) AS nom_genre -- nom genre: entre les deux séparateurs type 2 (/!\ troisième argument: longueur de chaine)
		from str_genres_pos_id
	)
select 
distinct nom_genre, id_genre
from genres;
    
-- montrer les différentes valeurs de certifications    
SELECT DISTINCT(CERTIFICATION) FROM MOVIES_EXT;
    

-- montrer les différentes valeurs de status	
SELECT DISTINCT(STATUS) FROM MOVIES_EXT;