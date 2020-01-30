DROP TABLE IF EXISTS ErrorValue_revenue;
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
  budget numeric,
  revenue numeric
);
INSERT INTO Information
SELECT m.id, m.title, m.budget*1.0/1000000, m.revenue*1.0/1000000
FROM movielens AS m
WHERE m.budget != 0 AND m.revenue != 0;

--calculate the parameters

CREATE VIEW Parameter AS
SELECT SUM((i.budget-avg.budget_avg)*i.revenue) AS Sxy,
       SUM(POWER(i.budget-avg.budget_avg,2)) AS Sxx
FROM Information AS i, (
                        SELECT AVG(budget) AS budget_avg
                        FROM Information) AS avg;

--calculate the Coefficients a, b in the regression model

CREATE VIEW Coefficients AS
SELECT p.Sxy/p.Sxx AS a, avg.revenue_avg - avg.budget_avg*p.Sxy/p.Sxx AS b
FROM Parameter AS p, (
                      SELECT AVG(budget) AS budget_avg, AVG(revenue) AS revenue_avg
                      FROM Information) AS avg;

--Test the significance of the model
--calculate estimated rating and estimated errors

CREATE TABLE Yhat AS
SELECT c.a*i.budget+c.b AS y_hat, i.movieid AS movieid
FROM Information AS i, Coefficients AS c;

CREATE TABLE Error AS
SELECT i.revenue-y.y_hat AS error,  i.movieid AS movieid
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

CREATE TABLE ErrorValue_revenue AS
SELECT e.error AS error, y.y_hat AS yhat
FROM Error AS e, Yhat AS y
WHERE y.movieid = e.movieid;

SELECT CAST(a AS numeric(10,4)), CAST(b AS numeric(10,4))
FROM Coefficients;
