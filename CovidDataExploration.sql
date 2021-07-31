-- COVID DEATH DATABASE
SELECT *
FROM CovidDatabase..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4 

-- Select the data we are going to use
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDatabase..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract COVID-19 in a country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDatabase..CovidDeaths
WHERE Location LIKE '%India%'
ORDER BY 1, 2

-- Looking at Total Cases vs Population
SELECT Location, date, population, total_cases, (total_cases/population)*100 as CasePercentage
FROM CovidDatabase..CovidDeaths
--WHERE Location LIKE '%India%'
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Looking at countries with highest infection rate in comparison to their populations
SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)*100) as CasePercentage
FROM CovidDatabase..CovidDeaths
--WHERE Location LIKE '%India%'
WHERE continent IS NOT NULL
GROUP BY Location, population
ORDER BY CasePercentage DESC

-- Countries with highest Death rate
SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDatabase..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- BREAKING DOWN DATA BY CONTINENTS
-- Looking at Continents with highest death count 
SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDatabase..CovidDeaths
WHERE continent IS NULL AND Location != 'World'
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- GLOBAL DATA
-- Global Death Percentage
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM CovidDatabase..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1

-- COVID VACCINATION DATABASE
SELECT *
FROM CovidDatabase..CovidVaccinations
ORDER BY 3, 4 

-- JOINING COVID VACCINATION AND DEATH TABLES
SELECT * 
FROM CovidDatabase..CovidDeaths death
JOIN CovidDatabase..CovidVaccinations vac
	ON death.location = vac.location 
	AND death.date= vac.date
WHERE death.continent IS NOT NULL

-- Looking at vaccination rate around the world using Common Table Expression (CTE)
WITH vaccinated_population (continent, location, date, population, new_vaccinations, rolling_vaccination) AS (
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as rolling_vaccination
FROM CovidDatabase..CovidDeaths death
JOIN CovidDatabase..CovidVaccinations vac
	ON death.location = vac.location 
	AND death.date= vac.date
WHERE death.continent IS NOT NULL
)
SELECT *, (rolling_vaccination/population*100) as vaccination_rate
FROM vaccinated_population

-- SELECT location, MAX(rolling_vaccination/population*100) as vaccination_rate
-- FROM vaccinated_population
-- GROUP BY location

-- TEMP TABLE
DROP TABLE IF EXISTS VaccinationRate
CREATE TABLE VaccinationRate
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
rolling_vaccination numeric
)

INSERT INTO VaccinationRate
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as rolling_vaccination
FROM CovidDatabase..CovidDeaths death
JOIN CovidDatabase..CovidVaccinations vac
	ON death.location = vac.location 
	AND death.date= vac.date
WHERE death.continent IS NOT NULL
ORDER BY 2,3

SELECT *, (rolling_vaccination/population*100) as vaccination_rate
FROM VaccinationRate

-- Creating View to store data for later
CREATE VIEW rateOfVaccination AS
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as rolling_vaccination
FROM CovidDatabase..CovidDeaths death
JOIN CovidDatabase..CovidVaccinations vac
	ON death.location = vac.location 
	AND death.date= vac.date
WHERE death.continent IS NOT NULL

SELECT *
FROM rateOfVaccination