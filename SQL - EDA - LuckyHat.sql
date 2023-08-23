-- Show games and their values 

SELECT G.ID, G.NAME, P.VALUE, G.START_TIME, G.END_TIME, P.REMAINING_QUOTA
FROM game G 
JOIN POINT P ON P.GAME_ID = G.ID;

-- What values in what games has ran out the quota 

SELECT G.ID, G.NAME, P.VALUE, P.REMAINING_QUOTA
FROM game G
JOIN POINT P ON G.ID = P.GAME_ID
WHERE P.REMAINING_QUOTA = 0; 

-- Show current games and its details ?

SELECT G.ID, G.NAME, G.START_TIME, G.END_TIME, P.VALUE, G.STATUS
FROM GAME G
JOIN POINT P ON P.GAME_ID = G.ID
WHERE STATUS = 'PROCESSING';

-- Show ALL PRIZES and their winners

SELECT U.NAME, P.NAME, G.NAME
FROM winner W
JOIN USER U ON W.USER_ID = U.ID
JOIN PRIZE P ON P.ID = W.PRIZE_ID
JOIN GAME G ON G.ID  = P.GAME_ID;

-- Show total playing times and total point of each month 
SELECT YEAR(PLAY_TIME) YEAR, MONTH(PLAY_TIME) MONTH, COUNT(*) PLAY_TIMES, SUM(POINT) TOTAL_POINT
FROM user_play_game
GROUP BY YEAR, MONTH;


-- Who play MORE THAN 2 different games 

SELECT U.ID, COUNT(DISTINCT X.GAME_ID) NUMBER_GAME
FROM user_play_game X
JOIN USER U ON U.ID = X.USER_ID
GROUP BY U.ID
HAVING NUMBER_GAME > 2;

-- Who never win any prize?

SELECT *
FROM USER
WHERE ID NOT IN (SELECT USER_ID FROM WINNER);

-- What game have the BIGGEST AND SMALLEST number of prizes?

WITH TABLE_X AS
(SELECT G.ID, G.NAME, COUNT(P.ID) NUMBER_PRIZE
FROM winner W 
JOIN PRIZE P ON P.ID = W.PRIZE_ID
JOIN GAME G ON G.ID = P.GAME_ID
GROUP BY G.ID)

SELECT ID, NAME, NUMBER_PRIZE
FROM TABLE_X
WHERE NUMBER_PRIZE = (SELECT MIN(NUMBER_PRIZE) FROM TABLE_X)

UNION ALL

SELECT ID, NAME, NUMBER_PRIZE
FROM TABLE_X
WHERE NUMBER_PRIZE = (SELECT MAX(NUMBER_PRIZE) FROM TABLE_X);

-- which games have total play times more than average total play times (of all games)  

WITH TABLE_TEMP AS
(SELECT GAME_ID, COUNT(ID) TOTAL_PLAY
FROM user_play_game X
GROUP BY GAME_ID)

SELECT GAME_ID, TOTAL_PLAY
FROM TABLE_TEMP
WHERE TOTAL_PLAY > ((SELECT COUNT(*) FROM user_play_game)/(SELECT COUNT(DISTINCT ID) FROM GAME));

--  top 3 total points of all users at all times ?

WITH TABLE_X AS
(SELECT U.ID, U.NAME, SUM(X.POINT) TOTAL_POINT,
RANK() OVER(ORDER BY SUM(X.POINT) DESC) RANKING
FROM user_play_game X 
JOIN USER U ON U.ID = X.USER_ID
GROUP BY U.ID)

SELECT *
FROM TABLE_X
WHERE RANKING < 4;

-- Show top 2 game have the least players take part in?

WITH TABLE_X AS
(SELECT G.ID, G.NAME, COUNT(DISTINCT USER_ID) TOTAL_CUSTOMER,
RANK() OVER(ORDER BY COUNT(DISTINCT USER_ID)) AS RANKING
FROM user_play_game X 
JOIN GAME G ON G.ID = X.GAME_ID
GROUP BY G.ID)

SELECT ID, NAME, TOTAL_CUSTOMER
FROM TABLE_X
WHERE RANKING < 3;

-- How many players of nearest month ? 

SELECT YEAR(PLAY_TIME) YEAR, MONTH(PLAY_TIME) MONTH, COUNT(DISTINCT USER_ID)
FROM USER_PLAY_GAME
GROUP BY YEAR, MONTH 
ORDER BY YEAR DESC, MONTH DESC
LIMIT 1;

-- Who are the winners and the prizes of the latest games ? 

WITH TABLE_X AS
(SELECT * 
FROM game G
WHERE G.STATUS = 'END'
ORDER BY G.END_TIME DESC
LIMIT 1)

SELECT G.ID, G.NAME, U.NAME, P.NAME
FROM WINNER W
JOIN USER U ON U.ID = W.USER_ID
JOIN PRIZE P ON P.ID = W.PRIZE_ID
JOIN GAME G ON G.ID = P.GAME_ID
WHERE G.ID = (SELECT ID FROM TABLE_X);

--  Top 2 months in the year attracts most people play game 

WITH TABLE_X AS
(SELECT MONTH(PLAY_TIME) MONTH, COUNT(DISTINCT USER_ID) TOTAL_USER,
RANK() OVER(ORDER BY COUNT(DISTINCT USER_ID) DESC) RANKING
FROM user_play_game
GROUP BY MONTH)

SELECT *
FROM TABLE_X
WHERE RANKING < 3;

-- What games have biggest and smallest AVERAGE POINT of all play times? 

WITH TABLE_X AS
(SELECT G.ID, G.NAME, IF(AVG(POINT) IS NULL, 0, AVG(POINT)) AVG_POINT
FROM user_play_game U 
RIGHT JOIN GAME G ON G.ID = U.GAME_ID
GROUP BY G.ID)

SELECT *
FROM TABLE_X
WHERE AVG_POINT = (SELECT MAX(AVG_POINT) FROM TABLE_X)

UNION ALL 

SELECT *
FROM TABLE_X
WHERE AVG_POINT = (SELECT MIN(AVG_POINT) FROM TABLE_X);

-- SHOW THE APPEARANCE percentage of all POINTS EACH MONTH from HIGH TO LOW? 

WITH TABLE_X AS
(SELECT YEAR(G.START_TIME) YEAR, MONTH(START_TIME) MONTH, SUM(P.APPEAR_TIME) TOTAL
FROM point p 
JOIN GAME G ON G.ID = P.GAME_ID
GROUP BY YEAR, MONTH)

SELECT YEAR, MONTH, P.VALUE, SUM(P.APPEAR_TIME)/TX.TOTAL*100 PERCENT 
FROM GAME G
JOIN TABLE_X TX ON YEAR(G.START_TIME) = TX.YEAR AND MONTH(G.START_TIME) = TX.MONTH
JOIN POINT P ON P.GAME_ID = G.ID
GROUP BY P.VALUE, YEAR, MONTH 
ORDER BY PERCENT DESC;