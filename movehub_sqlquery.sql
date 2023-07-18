/* 
Movehub Data Exploration
Skills Used: Window functions, aggregate functions, Joins, CTE's, subqueries, temp tables
*/

-- How many cities included per country in the cities table?

SELECT cities.Country, count(Country) AS city_cnt
FROM movehub.cities
GROUP BY Country
ORDER BY count(Country) DESC

-- Are there any NULL values within the cities dataset?

SELECT *
FROM movehub.cities
WHERE Country = "" OR Country IS NULL -- 3 missing values returned 

SELECT *
FROM movehub.cities
WHERE City = "" OR City IS NULL -- no values returned

-- Which cities are considered the worst as far as crime rating? (LIMIT 25)

SELECT City, Crime_Rating
FROM movehub.movehubqol
ORDER BY Crime_Rating DESC -- Low crime rating is good, high is bad
LIMIT 25

-- Which countries have the best crime rating based on the average crime rating per country?

SELECT Country, AVG(Crime_Rating) AS AvgCR
FROM movehub.movehubqol
LEFT JOIN movehub.cities -- Joined tables to be able to group city by country
ON movehubqol.City = cities.City
WHERE Country IS NOT NULL
GROUP BY Country
ORDER BY AvgCR 

-- What is the % of cities with a crime rating of less than 25.0?

SELECT (COUNT(*) / (SELECT COUNT(*) FROM movehub.movehubqol) *100) AS Percentage -- Used subquery to use total count of values, allowing conversion into percentage.
FROM movehub.movehubqol
WHERE Crime_Rating <= 25

-- 16.6667%

-- Which cities have the highest/lowest Movehub rating?

SELECT City, Movehub_Rating
FROM movehub.movehubqol
ORDER by Movehub_Rating DESC -- Highest

SELECT City, Movehub_Rating
FROM movehub.movehubqol
ORDER by Movehub_Rating -- Lowest

-- Which cities have the highest average rent? Lowest? 

SELECT City, Avg_Rent
FROM movehub.movehubcol
ORDER BY Avg_Rent DESC -- Highest
LIMIT 10


SELECT City, Avg_Rent
FROM movehub.movehubcol
ORDER BY Avg_Rent -- Lowest
LIMIT 10

-- Average Rent: Convert currency to USD from GBP

SELECT City, ROUND((Avg_Rent * 1.31),2) AS Avg_Rent_USD -- 1 British pound = 1.31 US Dollar
FROM movehub.movehubcol

-- City's Average Rent vs. Country's Average Rent

SELECT movehubcol.City AS City, Avg_Rent AS City_Avg_Rent, cities.Country AS Country, ROUND(AVG(Avg_Rent) OVER (PARTITION BY cities.Country),2) AS Country_Avg_Rent
FROM movehub.movehubcol
LEFT JOIN movehub.cities
ON movehubcol.City = cities.City
WHERE Country IS NOT NULL
ORDER BY Country

-- USA city AVG Rent Vs. Country AVG

SELECT movehubcol.City AS City, Avg_Rent AS City_Avg_Rent, cities.Country AS Country, ROUND(AVG(Avg_Rent) OVER (PARTITION BY cities.Country), 2) AS Country_Avg_Rent
FROM movehub.movehubcol
LEFT JOIN movehub.cities
ON movehubcol.City = cities.City
WHERE Country LIKE '%United States%'
ORDER BY City

-- Movehub Rating vs. Average Rent

SELECT movehubqol.city, movehubqol.Movehub_Rating, movehubcol. Avg_Rent
FROM movehub.movehubqol
LEFT JOIN movehub.movehubcol
ON movehubqol.city = movehubcol.city
ORDER BY Movehub_Rating DESC

-- What is the average disposable income per city in the United States, based on the available data?

SELECT movehubcol.City, movehubcol.Avg_Disposable_Income
FROM movehub.movehubcol
LEFT JOIN movehub.cities
ON movehubcol.City = cities.City
WHERE Country LIKE '%United States%' -- LIKE operator to find cities within the United States
ORDER BY Avg_Disposable_Income DESC

-- Which cities in the United States have the highest quality of life rating, based on the available data?

SELECT movehubqol.City, movehubqol.Quality_of_Life
FROM movehub.movehubqol
LEFT JOIN movehub.cities
ON movehubqol.City = cities.City
WHERE Country LIKE '%United States%'
ORDER BY Quality_of_Life DESC

-- Relationship between the average disposable income and quality of life within a city?

SELECT movehubqol.city, movehubqol.Quality_of_Life, movehubcol.Avg_Disposable_Income
FROM movehub.movehubqol
LEFT JOIN movehub.movehubcol 
ON movehubqol.city=movehubcol.city
ORDER BY Quality_of_Life DESC

-- Country Vs average purchase power, and rank by tier.

WITH CountriesVsPP AS (
    SELECT cities.Country, AVG(movehubqol.Purchase_Power) AS avg_PP
    FROM movehub.cities
    LEFT JOIN movehub.movehubqol ON cities.city = movehubqol.city
    WHERE Purchase_Power IS NOT NULL
    GROUP BY Country
) -- Used CTE's to find the average purchase power per country (avg-PP)
SELECT Country, avg_PP,
    CASE
        WHEN avg_PP >= 75 AND avg_PP < 100 THEN 'Tier I'
        WHEN avg_PP >= 50 AND avg_PP < 75 THEN 'Tier II'
        WHEN avg_PP >= 25 AND avg_PP < 50 THEN 'Tier III'
        WHEN avg_PP >= 0 AND avg_PP < 25 THEN 'Tier IV'
        ELSE 'Other Range'
    END AS Purchase_Power_Tier -- Each country ranked according to range of avg_PP using a CASE statement
FROM CountriesVsPP
ORDER BY avg_PP DESC

-- Use Temp Table to investigate relationships between Average Movehub Rating and Quality of Life Based on Country

DROP TABLE IF EXISTS CountryVsAvg
CREATE TEMPORARY TABLE movehub.CountryVsAvg (
    Country VARCHAR(255),
    AvgMHR DOUBLE(5,2),
    AvgQOL DOUBLE(5,2)
);

INSERT INTO movehub.CountryVsAvg (Country, AvgMHR, AvgQOL)
SELECT cities.Country AS Country, AVG(movehubqol.Movehub_Rating) AS AvgMHR, AVG(movehubqol.Quality_of_Life) AS AvgQOL
FROM movehub.cities
LEFT JOIN movehub.movehubqol ON cities.city = movehubqol.city
GROUP BY cities.Country

SELECT *
FROM CountryVsAvg
WHERE AvgMHR IS NOT NULL OR AvgQOL IS NOT NULL 
ORDER BY AvgMHR DESC  -- omits null values and organizes temp table by highest-lowest movehub rating

-- Create a View of previous query

Create View CountryVsAvg AS
SELECT cities.Country AS Country, AVG(movehubqol.Movehub_Rating) AS AvgMHR, AVG(movehubqol.Quality_of_Life) AS AvgQOL
FROM movehub.cities
LEFT JOIN movehub.movehubqol ON cities.city = movehubqol.city
GROUP BY cities.Country






   