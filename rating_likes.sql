DROP TABLE IF EXISTS ErrorValue_rating;
DROP VIEW IF EXISTS Pvalue;
DROP VIEW IF EXISTS Sigma_hat;
DROP VIEW IF EXISTS size;
DROP VIEW IF EXISTS Sigma;
DROP TABLE IF EXISTS Error;
DROP TABLE IF EXISTS Yhat;
DROP VIEW IF EXISTS Coefficients;
DROP VIEW IF EXISTS Parameter;
DROP TABLE IF EXISTS Information;

CREATE TABLE IF NOT EXISTS Information
(
  movieid integer,
  movietitle varchar,
  director varchar,
  actor1 varchar,
  actor2 varchar,
  actor3 varchar,
  facebooklikes numeric(10,3),
  rating numeric
);
INSERT INTO Information
SELECT i.id, i.movie_title, d.name, a1.name, a2.name, a3.name,
       (d.facebook_likes + a1.facebook_likes + a2.facebook_likes + a3.facebook_likes)*1.0/1000,
       i.imdb_score
FROM imdb AS i, actor AS a1, actor AS a2, actor AS a3, director AS d
WHERE i.director_name = d.name AND i.actor_2_name = a2.name AND
      i.actor_1_name = a1.name AND i.actor_3_name = a3.name;

--calculate the parameters

CREATE VIEW Parameter AS
SELECT SUM((i.facebooklikes-avg.likes_avg)*i.rating) AS Sxy,
       SUM(POWER(i.facebooklikes-avg.likes_avg,2)) AS Sxx
FROM Information AS i, (
                        SELECT AVG(facebooklikes) AS likes_avg
                        FROM Information) AS avg;

--calculate the Coefficients a, b in the regression model

CREATE VIEW Coefficients AS
SELECT p.Sxy/p.Sxx AS a, avg.rating_avg - avg.likes_avg*p.Sxy/p.Sxx AS b
FROM Parameter AS p, (
                      SELECT AVG(facebooklikes) AS likes_avg, AVG(rating) AS rating_avg
                      FROM Information) AS avg;

--Test the significance of the model
--calculate estimated rating and estimated errors

CREATE TABLE Yhat AS
SELECT c.a*i.facebooklikes+c.b AS y_hat, i.movieid AS movieid
FROM Information AS i, Coefficients AS c;

CREATE TABLE Error AS
SELECT i.rating-y.y_hat AS error, y.movieid AS movieid
FROM Information AS i, Yhat AS y
WHERE i.movieid = y.movieid;

CREATE VIEW Sigma AS
SELECT SUM(POWER(error,2)) AS sigma
FROM Error;

CREATE VIEW size AS
SELECT COUNT(*) AS n
FROM Error;

CREATE VIEW Sigma_hat AS
SELECT s2.sigma/(s1.n-2) AS sigmahat
FROM size AS s1, Sigma AS s2;

--calculate the statistic;

CREATE VIEW Pvalue AS
SELECT c.a/POWER(s.sigmahat/p.Sxx,0.5) AS p
FROM Parameter AS p, Sigma_hat AS s, Coefficients AS c;

CREATE TABLE ErrorValue_rating AS
SELECT e.error AS error, y.y_hat AS yhat
FROM Error AS e, Yhat AS y
WHERE y.movieid = e.movieid;

SELECT CAST(a AS numeric(10,8)), CAST(b AS numeric(10,8))
FROM Coefficients;
