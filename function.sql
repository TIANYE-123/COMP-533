CREATE OR REPLACE FUNCTION MovieRecommend (TitleOfMovie varchar, IdOfMovie integer)
RETURNS TABLE (recommend_id integer, recommend_movie varchar, recommend_value numeric) AS
$$
DECLARE
    queryString text;
    NumTitle integer;
    NumId integer;
    title varchar;
    id integer;
BEGIN
--     IF TitleOfMovie = " " AND IdOfMovie = " " THEN
-- --print "Please enter movieid or movietitle"
--     END IF;

    IF TitleOfMovie IS NOT NULL THEN
       SELECT i.id
       FROM imdb AS i
       WHERE i.movie_title = TitleOfMovie
       INTO id;
    END IF;

    IF IdOfMovie IS NOT NULL THEN
       SELECT i.movie_title
       FROM imdb AS i
       WHERE i.id = IdOfMovie
       INTO title;
    END IF;

--     IF TitleOfMovie != " " AND title != TitleOfMovie  THEN
-- --print "Please enter the correct moviename and movieid"
--     END IF;
--
--     IF IdOfMovie != " " AND id != IdOfMovie  THEN
-- --print "Please enter the correct moviename and movieid"
--     END IF;

    SELECT COUNT(*)
    FROM recommend_movie AS r
    WHERE r.movieid = IdOfMovie
    INTO NumId;

    SELECT COUNT(*)
    FROM recommend_movie AS r
    WHERE r.movieid = id
    INTO NumTitle;

    IF NumId>0 THEN
        queryString = 'SELECT r.recommend_movie_id, r.recommend_movie_title, r.recommend_value FROM recommend_movie AS r '
            || COALESCE('WHERE r.movieid = ' || IdOfMovie || 'ORDER BY recommend_value DESC LIMIT 5');
    END IF;

    IF NumTitle>0 THEN
        queryString = 'SELECT r.recommend_movie_id, r.recommend_movie_title, r.recommend_value FROM recommend_movie AS r '
            || COALESCE('WHERE r.movieid = ' || quote_literal(id)|| 'ORDER BY recommend_value DESC LIMIT 5');
    END IF;

    IF NumId = 0 AND NumTitle = 0 THEN
    --print "The movie is not in the record"
    END IF;

    RETURN QUERY EXECUTE queryString;

END;
$$
LANGUAGE plpgsql;

--test
SELECT * FROM MovieRecommend('','1');
SELECT * FROM MovieRecommend('Spectre',NULL)
