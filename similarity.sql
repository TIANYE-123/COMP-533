DROP TABLE IF EXISTS recommend_movie;
DROP VIEW IF EXISTS recommend_movie_1;
DROP VIEW IF EXISTS jaccard_rating;
DROP VIEW IF EXISTS jaccard_actor;
DROP VIEW IF EXISTS intersection_actor;
DROP VIEW IF EXISTS union_actor;
DROP VIEW IF EXISTS MovieActor;
DROP VIEW IF EXISTS jaccard_country;
DROP VIEW IF EXISTS jaccard_director;
DROP VIEW IF EXISTS jaccard_genre;
DROP VIEW IF EXISTS intersection_genre;
DROP VIEW IF EXISTS union_genre;
DROP VIEW IF EXISTS MovieGenre;
DROP VIEW IF EXISTS sample;
--SAMPLE
CREATE VIEW sample AS
SELECT *
FROM imdb
LIMIT 2000;

---genre similarity

CREATE VIEW MovieGenre AS
SELECT i.id AS movieid, g.genre AS genre
FROM sample AS i LEFT JOIN genre AS g ON i.id = g.imdbid
GROUP BY i.id, g.genre
ORDER BY i.id;

CREATE VIEW union_genre AS
SELECT t.id_1, t.id_2, COUNT(*) AS union
FROM (
      (
        SELECT m1.movieid AS id_1, m2.movieid AS id_2, m1.genre AS genre_1
        FROM MovieGenre AS m1 LEFT JOIN MovieGenre AS m2 ON m1.movieid != m2.movieid
      )
      UNION
      (
        SELECT m3.movieid AS id_1, m4.movieid AS id_2, m4.genre AS genre_2
        FROM MovieGenre AS m3 LEFT JOIN MovieGenre AS m4 ON m3.movieid != m4.movieid
      )
    ) AS t
GROUP BY t.id_1, t.id_2;

CREATE VIEW intersection_genre AS
SELECT m1.movieid AS id_1, m2.movieid AS id_2, COUNT(*) AS intersection
FROM MovieGenre AS m1 LEFT JOIN MovieGenre AS m2 ON m1.movieid != m2.movieid
WHERE m1.genre = m2.genre
GROUP BY m1.movieid, m2.movieid;

CREATE VIEW jaccard_genre AS
SELECT u.id_1, u.id_2, CASE WHEN u.union  = 0 THEN 1
                            WHEN i.intersection is null THEN 0
                       ELSE CAST(CAST(i.intersection AS numeric)/CAST(u.union AS numeric) AS numeric(10,4))
                       END AS similarity
FROM union_genre AS u LEFT JOIN intersection_genre  AS i ON u.id_1 = i.id_1 AND u.id_2 = i.id_2;

--director similarity

CREATE VIEW jaccard_director AS
SELECT i1.id AS id_1, i2.id AS id_2, CASE WHEN i1.director_name  = i2.director_name THEN 1
                                     ELSE 0
                                     END AS similarity
FROM sample AS i1 LEFT JOIN imdb AS i2 ON i1.id != i2.id;

--country similarity

CREATE VIEW jaccard_country AS
SELECT i1.id AS id_1, i2.id AS id_2, CASE WHEN i1.country  = i2.country THEN 1
                                     ELSE 0
                                     END AS similarity
FROM sample AS i1 LEFT JOIN imdb AS i2 ON i1.id != i2.id;

--actor similarity

CREATE VIEW MovieActor AS
SELECT t.id AS movieid, t.actor AS actor
FROM (
  (
    SELECT i.id AS id, i.actor_1_name AS actor
    FROM sample AS i
  )
  UNION
  (
    SELECT i.id AS id, i.actor_2_name AS actor
    FROM sample AS i
  )
  UNION
  (
    SELECT i.id AS id, i.actor_3_name AS actor
    FROM sample AS i
  )
) AS t
ORDER BY t.id;

CREATE VIEW union_actor AS
SELECT t.id_1, t.id_2, COUNT(*) AS union
FROM (
      (
        SELECT m1.movieid AS id_1, m2.movieid AS id_2, m1.actor AS actor_1
        FROM MovieActor AS m1 LEFT JOIN MovieActor AS m2 ON m1.movieid != m2.movieid
      )
      UNION
      (
        SELECT m3.movieid AS id_1, m4.movieid AS id_2, m4.actor AS actor_2
        FROM MovieActor AS m3 LEFT JOIN MovieActor AS m4 ON m3.movieid != m4.movieid
      )
    ) AS t
GROUP BY t.id_1, t.id_2;

CREATE VIEW intersection_actor AS
SELECT m1.movieid AS id_1, m2.movieid AS id_2, COUNT(*) AS intersection
FROM MovieActor AS m1 LEFT JOIN MovieActor AS m2 ON m1.movieid != m2.movieid
WHERE m1.actor = m2.actor
GROUP BY m1.movieid, m2.movieid;

CREATE VIEW jaccard_actor AS
SELECT u.id_1 AS id_1, u.id_2 AS id_2, CASE WHEN u.union  = 0 THEN 1
                                       WHEN i.intersection is null THEN 0
                                       ELSE CAST(CAST(i.intersection AS numeric)/CAST(u.union AS numeric) AS numeric(10,4))
                                       END AS similarity
FROM union_actor AS u LEFT JOIN intersection_actor  AS i ON u.id_1 = i.id_1 AND u.id_2 = i.id_2;


--rating similarity

CREATE VIEW jaccard_rating AS
SELECT i1.id AS id_1, i2.id AS id_2, i2.imdb_score AS similarity
FROM sample AS i1 LEFT JOIN imdb AS i2 ON i1.id != i2.id;

--recommed value

CREATE VIEW recommend_movie_1 AS
SELECT jg.id_1 AS movieid, jg.id_2 AS recommend_movie_id, i.movie_title AS recommend_movie_title,
       CAST((jg.similarity * 0.5 + jd.similarity * 0.15 + ja.similarity * 0.25 + jc.similarity * 0.1) *0.65 +jr.similarity *0.35  AS numeric(10,4)) AS recommend_value
FROM jaccard_genre AS jg, jaccard_director AS jd, jaccard_actor AS ja, jaccard_country AS jc, jaccard_rating AS jr, sample AS i
WHERE jg.id_1 = jd.id_1 AND jd.id_1 = ja.id_1 AND ja.id_1 = jc.id_1 AND jc.id_1 = jr.id_1 AND
      jg.id_2 = jd.id_2 AND jd.id_2 = ja.id_2 AND ja.id_2 = jc.id_2 AND jc.id_2 = jr.id_2 AND jr.id_2 = i.id;


CREATE TABLE recommend_movie AS
SELECT movieid, recommend_movie_id, recommend_movie_title, recommend_value
FROM recommend_movie_1
ORDER BY movieid DESC, recommend_value DESC;
