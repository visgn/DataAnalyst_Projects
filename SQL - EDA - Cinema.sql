-- films dont have any screenings

SELECT film.id, film.name
FROM film
WHERE film.id NOT IN
	(SELECT film.id
	FROM film
	JOIN screening ON film.id = film_id);

-- Who books more than 1 seat in a booking

SELECT C.FIRST_NAME, B.ID, COUNT(*) NUMBER_SEAT
FROM reserved_seat R
JOIN BOOKING B ON R.booking_id = B.ID
JOIN CUSTOMER C ON C.ID = B.CUSTOMER_ID
GROUP BY B.ID
HAVING NUMBER_SEAT > 1;

-- rooms have more than 2 films in a day

SELECT DATE(S.START_TIME) AS SHOWDAY, R.NAME ROOMNAME, COUNT(F.NAME)
FROM film F
JOIN screening S ON F.ID = S.FILM_ID
JOIN ROOM R ON R.ID = S.room_id
GROUP BY SHOWDAY , ROOMNAME;

-- room shows the least films 

SELECT R.NAME, COUNT(distinct F.NAME) TOTAL_FILM
FROM room R
JOIN SCREENING S ON R.ID = S.ROOM_ID
JOIN FILM F ON S.FILM_ID = F.ID
GROUP BY R.NAME
HAVING TOTAL_FILM = (SELECT COUNT(distinct F.NAME) TOTAL_FILM
		FROM room R
JOIN SCREENING S ON R.ID = S.ROOM_ID
JOIN FILM F ON S.FILM_ID = F.ID
GROUP BY R.NAME
ORDER BY TOTAL_FILM
LIMIT 1);

-- films don't have any booking

SELECT film.name
FROM film
WHERE film.name NOT IN
(
SELECT DISTINCT film.name
FROM film
JOIN screening ON film.id = screening.film_id
JOIN booking ON booking.screening_id = screening.id
) ;


-- films have longest and shortest length

SELECT *  FROM 
	(SELECT * FROM film 
	ORDER BY length_min asc
	LIMIT 1) X
UNION ALL
SELECT * FROM 
	(SELECT * FROM film 
	ORDER BY length_min desc
	LIMIT 1) Y;


-- films have been showed in the biggest number of room

SELECT filmname, count(*) number_of_room
FROM 
	(SELECT distinct film.name filmname, room.name roomname
	FROM film
	JOIN screening ON screening.film_id = film.id
	JOIN room ON screening.room_id = room.id) X
GROUP BY filmname
ORDER BY number_of_room desc
LIMIT 1 ;


-- number of films by weekday and order descending 

SELECT 
(CASE 
WHEN WEEK_DAY = 0 THEN 'MON'
WHEN WEEK_DAY = 1 THEN 'TUE' 
WHEN WEEK_DAY = 2 THEN 'WED'
WHEN WEEK_DAY = 3 THEN 'THU'
WHEN WEEK_DAY = 4 THEN 'FRI'
WHEN WEEK_DAY = 5 THEN 'SAT'
ELSE 'SUN' END) AS DATE, NUMBER_FILM
FROM
(SELECT WEEKDAY(S.START_TIME) WEEK_DAY, COUNT(*) NUMBER_FILM
FROM SCREENING S
JOIN FILM F ON S.FILM_ID = F.ID
GROUP BY WEEK_DAY) X
ORDER BY NUMBER_FILM DESC; 

-- total length of each film showed in 28/5/2022

SELECT name, length_min*COUNT(*) as total_showtime
FROM 
	(SELECT film.name , film.length_min 
	FROM film
	JOIN screening ON screening.film_id = film.id
	WHERE date(screening.start_time) = '2022-05-28') X
GROUP BY name, length_min; 

-- films have screening time above and below average screening time of all films
SELECT F.ID, F.NAME, SUM(IF(S.ID IS NOT NULL, F.LENGTH_MIN, 0)) SHOW_MIN,
(CASE WHEN SUM(F.LENGTH_MIN) > (SELECT SUM(F.LENGTH_MIN)/COUNT(DISTINCT F.NAME)
								FROM SCREENING S
                                RIGHT JOIN FILM F ON F.ID = S.FILM_ID) THEN 'ABOVE AVG'
                                ELSE 'BELOW AVG'
                                END) STATUS
FROM SCREENING S
RIGHT JOIN FILM F ON S.FILM_ID = F.ID
GROUP BY F.NAME, F.LENGTH_MIN, F.ID;

-- the room has least number of seats

SELECT R.NAME, COUNT(*) TOTAL_SEAT
FROM seat S
JOIN ROOM R ON R.ID = S.room_id
GROUP BY R.NAME
ORDER BY TOTAL_SEAT ASC
LIMIT 1;

-- rooms have number of seat bigger than average number of seats of all rooms

SELECT R.NAME, COUNT(*)
FROM seat S
JOIN ROOM R ON S.ROOM_ID = R.ID
GROUP BY R.NAME
HAVING COUNT(*) > ((SELECT COUNT(*) FROM seat) /(SELECT COUNT(*) FROM ROOM));


-- Show Film with total screening and order by total screening. BUT ONLY SHOW DATA OF FILM WITH TOTAL SCREENING > 10

SELECT F.NAME, COUNT(S.ID)  SCREENING_COUNT, COUNT(B.ID) BOOKING_COUNT
FROM SCREENING S 
RIGHT JOIN FILM F ON S.FILM_ID = F.ID
LEFT JOIN BOOKING B ON S.ID = B.SCREENING_ID
GROUP BY F.NAME
HAVING SCREENING_COUNT > 10; 

-- CALCULATE BOOKING rate over screening of each film ORDER BY RATES.


SELECT F.NAME, IF((COUNT(B.ID)/COUNT(DISTINCT S.ID))*100 IS NULL, 0, (COUNT(B.ID)/COUNT(DISTINCT S.ID))*100) RATING
FROM BOOKING B
RIGHT JOIN SCREENING S ON B.SCREENING_ID = S.ID
RIGHT JOIN FILM F ON F.ID = S.FILM_ID
GROUP BY F.ID
ORDER BY RATING;

-- WHICH film has rate bigger than average
SELECT F.NAME, (COUNT(B.ID)/COUNT(S.ID))*100 RATING
FROM BOOKING B
RIGHT JOIN SCREENING S ON B.SCREENING_ID = S.ID
JOIN FILM F ON F.ID = S.FILM_ID
GROUP BY F.NAME
HAVING RATING > (SELECT AVG(RATING)
				FROM
				(SELECT F.NAME, (COUNT(B.ID)/COUNT(S.ID))*100 RATING
				FROM BOOKING B
				RIGHT JOIN SCREENING S ON B.SCREENING_ID = S.ID
				JOIN FILM F ON F.ID = S.FILM_ID
				GROUP BY F.NAME
				ORDER BY RATING) X);

-- TOP 2 people enjoyed the least TIME (in minutes) in the cinema 
SELECT C.ID, SUM(F.LENGTH_MIN) ENJOY_TIME
FROM CUSTOMER C
JOIN BOOKING B ON B.CUSTOMER_ID = C.ID
JOIN SCREENING S ON B.SCREENING_ID = S.ID
JOIN FILM F ON F.ID = S.FILM_ID
GROUP BY C.ID
ORDER BY ENJOY_TIME 
LIMIT 2;