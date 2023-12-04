/*
Covid Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


SELECT *
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 3,4


-- Select Data that we are going to be starting with


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country


SELECT location, date, total_cases, total_deaths, (CAST(total_deaths as float)/CAST(total_cases as float)) * 100 as DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
AND location like '%state%'
ORDER BY 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid


SELECT location, date, population, total_cases, (total_cases/population) * 100 as PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
AND location like '%state%'
ORDER BY 1,2


-- Countries with Highest Infection Rate compared to Population


SELECT location, population, MAX(CAST(total_cases as int)) as HighestInfectionCount, MAX((CAST(total_cases as int)/population)) * 100 as PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected desc



-- Countries with Highest Death Count per Population


SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount desc


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population


SELECT continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc



-- GLOBAL NUMBERS


SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths,  SUM(CAST(new_deaths as int)) / SUM(new_cases) * 100 as DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine


SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations
, SUM(CONVERT(float, vaccine.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as RollingPeopleVaccinated
, (SUM(CONVERT(float, vaccine.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) / population) * 100
FROM PortfolioProject.dbo.CovidDeaths as death
JOIN PortfolioProject.dbo.CovidVaccinations as vaccine
	ON death.location = vaccine.location
	AND death.date = vaccine.date
WHERE death.continent IS NOT NULL
ORDER BY 2, 3


-- Using CTE to perform Calculation on Partition By in previous query


WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations
, SUM(CONVERT(float, vaccine.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as RollingPeopleVaccinated
--, (SUM(CONVERT(float, vaccine.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) / population) * 100
FROM PortfolioProject.dbo.CovidDeaths as death
JOIN PortfolioProject.dbo.CovidVaccinations as vaccine
	ON death.location = vaccine.location
	AND death.date = vaccine.date
WHERE death.continent IS NOT NULL
--ORDER BY 2, 3
)
Select *, (RollingPeopleVaccinated/population) * 100
FROM PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query


DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric ,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations
, SUM(CONVERT(float, vaccine.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as RollingPeopleVaccinated
--, (SUM(CONVERT(float, vaccine.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) / population) * 100
FROM PortfolioProject.dbo.CovidDeaths as death
JOIN PortfolioProject.dbo.CovidVaccinations as vaccine
	ON death.location = vaccine.location
	AND death.date = vaccine.date
--WHERE death.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *, (RollingPeopleVaccinated/Population) * 100
FROM #PercentPopulationVaccinated
ORDER BY 2, 3



-- Creating View to store data for later visualizations


CREATE VIEW PercentPopulationVaccination as
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations
, SUM(CONVERT(float, vaccine.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) as RollingPeopleVaccinated
--, (SUM(CONVERT(float, vaccine.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) / population) * 100
FROM PortfolioProject.dbo.CovidDeaths as death
JOIN PortfolioProject.dbo.CovidVaccinations as vaccine
	ON death.location = vaccine.location
	AND death.date = vaccine.date
WHERE death.continent IS NOT NULL
--ORDER BY 2, 3
