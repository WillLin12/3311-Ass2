-- COMP3311 19T3 Assignment 2
-- Written by <<insert your name here>>

-- Q1 Which movies are more than 6 hours long? 

create or replace view Q1(title)
as
SELECT T.main_title
From Titles T
Where T.runtime > 360 and T.format = 'movie'
;

-- Q2 What different formats are there in Titles, and how many of each?

create or replace view Q2(format, ntitles)
as
SELECT T.format,count(T.format)
FROM Titles T
group by T.format 
;

-- Q3 What are the top 10 movies that received more than 1000 votes?

create or replace view Q3(title, rating, nvotes)
as

SELECT T.main_title, T.rating, T.nvotes
FROM Titles T
Where T.nvotes >= 1000 and T.format = 'movie'
Order by T.rating DESC, T.main_title
limit 10
;

-- Q4 What are the top-rating TV series and how many episodes did each have
create or replace view Q4(title, nepisodes)
as

SELECT T.main_title as title, count(E.parent_id) as nepisodes 
FROM Titles T , episodes E 
WHERE T.id = E.parent_id and T.rating = (SELECT MAX(rating) FROM Titles) 
and (T.format = 'tvSeries' or T.format = 'tvMiniSeries')
Group by T.main_title
Order by T.main_title
;


-- Q5 Which movie was released in the most languages?

create or replace view No_Lang(title,number,title_id) 
as   
SELECT T.main_title, count(DISTINCT(A.language)), T.id                        
FROM Titles T, Aliases A                                                         
WHERE T.format = 'movie' and A.title_id = T.id                        
GROUP BY T.main_title, T.id;
	
create or replace view Q5(title,nlanguages)
as
SELECT main_title, count(distinct(language))         
FROM Titles T, Aliases A                                                        
WHERE T.format = 'movie' AND A.title_id = T.id AND T.id = (SELECT title_id from No_Lang N
									WHERE N.number =  (select MAX(number) from No_Lang))
group by T.main_title
;


-- Q6 Which actor has the highest average rating in movies that they're known for?
CREATE OR REPLACE VIEW Ratings(actor_id, Avg_Rating)
AS
	SELECT K.name_id, AVG(T.rating)
	FROM Known_for K
	LEFT JOIN Titles T ON T.id = K.title_id
	WHERE T.rating IS NOT NULL 
	AND T.format = 'movie' AND K.name_id IN (SELECT W.name_id FROM Worked_as W WHERE W.work_role = 'actor')
	GROUP BY K.name_id
	HAVING count(K.name_id) > 1
;

CREATE OR REPLACE VIEW q6(name)
AS
	SELECT N.name
	FROM Ratings R, Names N
	WHERE R.actor_id = N.id AND R.Avg_Rating = (SELECT MAX(Avg_Rating) FROM Ratings)
;

-- Q7 For each movie with more than 3 genres, show the movie title and a comma-separated list of the genres


create or replace view Q7(title,genres)
as
SELECT T.main_title, STRING_AGG (TG.genre, ',' ORDER BY TG.genre) 
FROM Titles T, Title_genres TG
WHERE T.id = TG.title_id AND T.format = 'movie'
GROUP BY T.id
HAVING count(TG.genre) > 3
;


-- Q8 Get the names of all people who had both actor and crew roles on the same movie

create or replace view CrossOvers(movie_id, actor_id) 
as
SELECT A.title_id as movie_id, A.name_id as actor_id     
FROM actor_roles A, crew_roles C                                                 
WHERE A.name_id  = C.name_id AND A.title_id = C.title_id
;

create or replace view Q8(name)
as
SELECT DISTINCT(N.name) 
FROM Titles T, Names N, CrossOvers C 
WHERE T.format = 'movie' AND T.id = C.movie_id AND C.actor_id = N.id
;


-- Q9 Who was the youngest person to have an acting role in a movie, and how old were they when the movie started?

create or replace view AgeTable (Name,Actor_Age) 
as 
SELECT A.name_id, T.start_year - N.birth_year
FROM Titles T, Names N, Actor_roles A
WHERE T.format = 'movie' AND T.id = A.title_id AND N.id = A.name_id;

create or replace view Q9(name,age)
as
SELECT N.name, AA.Actor_Age
FROM Names N, AgeTable AA 
WHERE N.id = AA.Name AND AA.Actor_Age = (SELECT Min(Actor_Age) FROM AgeTable)
;


-- Q10 Write a PLpgSQL function that, given part of a title, shows the full title and the total size of the cast and crew
create or replace function Q10(partial_title text) returns setof text
as $$
DECLARE
	title text := '';
	no_titles integer;
BEGIN 
	IF EXISTS (SELECT Q.Name || ' has ' || cast(Q.TitleCount as text) || ' cast and crew'
				FROM Q10CrewCount Q
				WHERE Q.Name ILIKE '%' || partial_title || '%') 
		THEN RETURN QUERY 
			SELECT Q.Name || ' has ' || cast(Q.TitleCount as text) || ' cast and crew'
			FROM Q10CrewCount Q
			WHERE Q.Name ILIKE '%' || partial_title || '%';
	ELSE 
		RETURN NEXT 'No matching titles';
	END IF;
END;
$$ language plpgsql;


CREATE OR REPLACE VIEW Q10Table1 (ID_Title, Contributor)
AS
	SELECT DISTINCT T.ID, P.name_id
	FROM Titles T
	RIGHT JOIN Principals P ON T.id = P.title_id

	UNION
	
	SELECT DISTINCT T.ID, C.name_id
	FROM Titles T
	RIGHT JOIN Crew_roles C ON T.id = C.title_id

	UNION 

	SELECT DISTINCT T.ID, A.name_ID
	FROM Titles T
	RIGHT JOIN Actor_roles A ON T.id = A.title_ID
;


CREATE OR REPLACE VIEW Q10CrewCount (Name, TitleCount)
AS
	SELECT DISTINCT T.main_title, count (Q.ID_Title)
	FROM Q10Table1 Q, Titles T
	WHERE Q.ID_Title = T.id
	GROUP BY T.ID
;




