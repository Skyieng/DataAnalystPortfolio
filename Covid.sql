-- 1. Display all
SELECT 
	* 
FROM 
	Covid_19.dbo.CovidDeaths;

-- 2. Total Death Count By Continent
SELECT location, continent, SUM(new_deaths) AS TotalDeaths
FROM Covid_19.dbo.CovidDeaths
GROUP BY location, continent
ORDER BY 2 DESC

-- 3. Death Rate by countries
SELECT 
	location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathRate 
FROM 
	Covid_19.dbo.CovidDeaths;

-- 4. Total Death rate
SELECT 
	SUM(CONVERT(BIGINT, new_cases)) AS TotalCases, SUM(CONVERT(BIGINT, new_deaths)) AS TotalDeaths, 
	(SUM(CONVERT(FLOAT, new_deaths))/SUM(CONVERT(FLOAT,new_cases)))*100 AS DeathRate
FROM 
	Covid_19.dbo.CovidDeaths

-- 5. Infection Count By Country
SELECT location, continent, population, MAX(total_cases) InfectionCount, MAX((total_cases/population))*100 AS InfectionRate
FROM Covid_19.dbo.CovidDeaths
GROUP BY location, population, continent
ORDER BY InfectionRate DESC 

-- 6.
SELECT 
	location, continent, date, total_cases, new_cases AS InfectionCount, (total_cases/ CONVERT(FLOAT,population))*100 AS InfectionRate
FROM Covid_19.dbo.CovidDeaths
GROUP BY location, date, population, new_cases, total_cases, continent
ORDER BY 1,2

-- 3. Total Cases vs Population
SELECT 
	location, date, total_cases, population, (total_deaths/population)*100 AS DeathRate
FROM 
	Covid_19.dbo.CovidDeaths
WHERE 
	location like '%malaysia%'
ORDER BY
	DeathRate DESC;

-- 4. Country with highest infection rate vs population
SELECT 
	location, MAX(population) AS Population, MAX(total_cases/population)*100 AS InfectionRate
FROM 
	Covid_19.dbo.CovidDeaths
GROUP BY 
	location
ORDER BY 
	InfectionRate desc;

-- 5. Highest death count per population WITHOUT continent
SELECT 
	location, MAX(population) AS DeathCount, MAX(total_deaths/population)*100 AS DeathPerPopulation
FROM 
	Covid_19.dbo.CovidDeaths
WHERE 
continent IS NOT NULL
GROUP BY 
	location
ORDER BY 
	DeathCount DESC;

-- 6. Highest death count per population WITH continent
SELECT 
	location, MAX(population) AS DeathCount
FROM 
	Covid_19.dbo.CovidDeaths
WHERE 
	continent IS NULL
GROUP BY 
	location
ORDER BY 
	DeathCount DESC;
--OR
SELECT continent, SUM(DeathCount) AS DeathCount
FROM
(
	SELECT 
		continent, location, MAX(population) AS DeathCount
	FROM 
		Covid_19.dbo.CovidDeaths 
	GROUP BY continent, location
	HAVING continent IS NOT NULL
) AS aggre
GROUP BY 
	continent
ORDER BY 
	DeathCount DESC

-- 
SELECT 
	date, SUM(new_cases) AS NewCases, SUM(new_deaths) AS NewDeaths
FROM 
	Covid_19.dbo.CovidDeaths
GROUP BY 
	date
ORDER BY 2 DESC;

-- 7. WITH Temp Table
WITH CountryRollingVaccinations (continent,location, date, new_vaccinations, population, RollingVaccination) AS 
(
	SELECT 
		death.continent, death.location, death.date, vaccine.new_vaccinations, population,
		SUM(CAST(vaccine.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY death.date, death.location) AS RollingVaccination
	FROM Covid_19.dbo.CovidDeaths death
	JOIN Covid_19.dbo.CovidVaccinations vaccine
	ON death.date = vaccine.date AND death.location = vaccine.location
	WHERE death.continent IS NOT NULL
)
SELECT *, (RollingVaccination/CAST(population AS float))*100 AS VaccinationRate FROM CountryRollingVaccinations ORDER BY VaccinationRate DESC

-- Local SQL Server Temp Table (Include # infront of table name)
DROP TABLE IF EXISTS
CREATE TABLE #VaccinationRate
(
	continent varchar(255),
	location varchar(255),
	date datetime,
	new_vaccinations numeric,
	population numeric,
	RollingVaccination numeric
)
INSERT INTO #VaccinationRate
	SELECT 
		death.continent, death.location, death.date, vaccine.new_vaccinations, population,
		SUM(CAST(vaccine.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY death.date, death.location) AS RollingVaccination
	FROM Covid_19.dbo.CovidDeaths death
	JOIN Covid_19.dbo.CovidVaccinations vaccine
	ON death.date = vaccine.date AND death.location = vaccine.location
	WHERE death.continent IS NOT NULL

SELECT * FROM #VaccinationRate

-- View Table
CREATE VIEW dbo.Covid_19.VaccinationRateView AS
	SELECT 
		death.continent, death.location, death.date, vaccine.new_vaccinations, population,
		SUM(CAST(vaccine.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY death.date, death.location) AS RollingVaccination
	FROM Covid_19.dbo.CovidDeaths death
	JOIN Covid_19.dbo.CovidVaccinations vaccine
	ON death.date = vaccine.date AND death.location = vaccine.location
	WHERE death.continent IS NOT NULL
