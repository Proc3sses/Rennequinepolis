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
distinct nom_genre, id_genre
from genres;
    
-- montrer les diff�rentes valeurs de certifications    
SELECT DISTINCT(CERTIFICATION) FROM MOVIES_EXT;
    

-- montrer les diff�rentes valeurs de status	
SELECT DISTINCT(STATUS) FROM MOVIES_EXT;