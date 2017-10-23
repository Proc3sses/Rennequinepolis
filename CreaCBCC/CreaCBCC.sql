-- Attention, le code SQL n'est pas syntaxiquement correct. Les VARCHAR2 n'ont pas de taille.
-- De plus toutes les valeurs numériques ont le type NUMBER ce qui est trop permissif.
-- Le script SQL doit donc être adapté par rapport à ceux deux points en plus de ce qui est demandé dans l'énoncé de laboratoire.

drop table artist cascade constraints;
drop table certification cascade constraints;
drop table status cascade constraints;
drop table genre cascade constraints;
drop table movie cascade constraints;
drop table movie_director cascade constraints;
drop table movie_genre cascade constraints;
drop table movie_actor cascade constraints;
drop table users cascade constraints;
drop table review cascade constraints;
drop table infos cascade constraints;
drop table erreurs cascade constraints;

create table artist (
  id   number(6) constraint artist$id$pos check(id >= 0),
  name varchar2(24 char), -- 95perc de actor (95perc de director = 19)
  constraint artist$pk primary key (id),
  constraint artist$name$nn check (name is not null)
);

create table certification (
  id          number(2) constraint cert$id$pos check(id >= 0),
  name        varchar2(12 char),
  description varchar2(50 char),
  constraint cert$pk primary key (id),
  constraint cert$name$nn check (name is not null),
  constraint cert$name$un unique (name)
);

create table status (
  id          number(2) constraint status$id$pos check(id >= 0),
  name        varchar2(15 char),
  constraint status$pk primary key (id),
  constraint status$name$nn check (name is not null),
  constraint status$name$un unique (name)
);

create table genre (
  id   number(2) constraint genre$id$pos check(id >= 0),
  name varchar2(16 char),
  constraint genre$pk primary key (id),
  constraint genre$name$nn check (name is not null),
  constraint genre$name$un unique (name)
);

create table movie (
  id             number(6) constraint movie$id$pos check(id >= 0),
  title          varchar2(43 char),
  original_title varchar2(43 char),
  status         number(2) constraint movie$status$fk references status(id),
  release_date   date, constraint monde$release_date$mini check( release_date >= date '1886-01-01'),-- check après release 1er film au monde 1886
  vote_average   number(2) constraint movie$vote_average$pos check(vote_average >= 0),
  vote_count     number(4) constraint movie$vote_count$pos check(vote_count >=0),
  certification  number(2) constraint movie$cert$fk references certification(id),
  runtime        number(3) constraint movie$runtime$pos check(runtime >= 0), --95perc
  poster         blob,
  constraint movie$pk primary key (id),
  constraint movie$title$nn check (title is not null)
);

create table movie_director (
  movie    number(6) constraint movie_director$movie$fk references movie(id),
  director number(6) constraint movie_director$director$fk references artist(id),
  constraint m_d$pk primary key (movie, director)
);

create table movie_genre (
  genre number(2) constraint movie_genre$genre$fk references genre(id),
  movie number(6) constraint movie_genre$movie$fk references movie(id),
  constraint m_g$pk primary key (genre, movie)
  ) ;

create table movie_actor
  (
  movie  number(6) constraint movie_actor$movie$fk references movie(id),
  actor number(6) constraint movie_actor$actor$fk references artist(id),
  constraint m_a$pk primary key (movie, actor)
);

create table users
(
	id number(6) constraint users$pk primary key,
	nom varchar2(20) constraint users$nom$nn check (nom is not null),
	prenom varchar2(20) constraint users$prenom$nn check (prenom is not null),
	login varchar2(20) constraint users$login$nn check (login is not null),
	password varchar2(20) constraint users$password$nn check (password is not null),
	constraint users$login$un unique (login)
);

create table review
(
	movie number(6) constraint review$movie$fk references movie(id),
	users number(6) constraint review$users$fk references users(id),
	cote number(2) constraint review$cote$pos check (cote between 0 and 10),
	avis varchar(200),
	review_date date constraint review$review_date$nn check(release_date is not null)
);

create table infos
(
	id number(6) constraint infos$pk primary key,
	message varchar2(200) constraint infos$message$nn check (message is not null),
	info_date date
);

create table erreurs
(
	id number(6) constraint erreurs$pk primary key,
	message varchar2(200) constraint erreur$message$nn check (message is not null),
	erreur_date date
);
