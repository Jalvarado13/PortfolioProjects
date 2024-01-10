/*
Covid 19 Data Exploration in BigQuery

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/
-- Select the Data that We are Going to Start With

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM `project-portfolio-410223.SQL_Exploration.CovidDeaths` 
ORDER BY 1, 2;

-- Looking for Total Cases vs Total Deaths
-- Shows the Rough Likelihood of Dying if Covid is Contracted in the US

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM `project-portfolio-410223.SQL_Exploration.CovidDeaths` 
WHERE location like '%States%'
ORDER BY 1, 2;

-- Looking at Total Cases vs Population
-- Shows what Percentage of Population in US got Covid

SELECT location, date, total_cases, population, (total_cases/population)*100 as PercentInfectedPopulation
FROM `project-portfolio-410223.SQL_Exploration.CovidDeaths` 
WHERE location like '%States%'
ORDER BY 1, 2;

-- Looking at Countries with Highest Infection Rate compared to population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)*100) as PercentInfectedPopulation
FROM `project-portfolio-410223.SQL_Exploration.CovidDeaths` 
GROUP BY location, population
ORDER BY PercentInfectedPopulation DESC;

-- Looking at Countries with Highest Infection Rate compared to population with Date

SELECT location, population, date, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)*100) as PercentInfectedPopulation
FROM `project-portfolio-410223.SQL_Exploration.CovidDeaths` 
GROUP BY location, population, date
ORDER BY PercentInfectedPopulation DESC;

-- Showing Countries with Highest Death Count per Population
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM `project-portfolio-410223.SQL_Exploration.CovidDeaths` 
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Let's Sort Things by Continent
-- Showing the Continents with the Highest Death Counts

SELECT location, MAX(total_deaths) as TotalDeathCount
FROM `project-portfolio-410223.SQL_Exploration.CovidDeaths` 
WHERE continent is null
 and location <> "World"
  and location <> "European Union"
   and location <> "International"
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Global Numbers

SELECT date, SUM(new_cases) as total_cases,SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
FROM `project-portfolio-410223.SQL_Exploration.CovidDeaths` 
WHERE continent is not null
GROUP BY date
ORDER BY 1, 2;

SELECT SUM(new_cases) as total_cases,SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
FROM `project-portfolio-410223.SQL_Exploration.CovidDeaths` 
WHERE continent is not null
--GROUP BY date
ORDER BY 1, 2;


--Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location,dea.date) as RollingPeopleVaccinated
FROM `project-portfolio-410223.SQL_Exploration.CovidDeaths` as dea
JOIN `project-portfolio-410223.SQL_Exploration.Covid Vaccinations` as vac
  On dea.location = vac.location
  and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3;

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM `project-portfolio-410223.SQL_Exploration.CovidDeaths` as dea
JOIN `project-portfolio-410223.SQL_Exploration.Covid Vaccinations` as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 
--order by 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM `project-portfolio-410223.SQL_Exploration.CovidDeaths` as dea
JOIN `project-portfolio-410223.SQL_Exploration.Covid Vaccinations` as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- Creating View to store Data for Visualizations

CREATE VIEW project-portfolio-410223.SQL_Exploration.PercentPopulationVaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location,dea.date) as RollingPeopleVaccinated
FROM `project-portfolio-410223.SQL_Exploration.CovidDeaths` as dea
JOIN `project-portfolio-410223.SQL_Exploration.Covid Vaccinations` as vac
  On dea.location = vac.location
  and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3;

SELECT *
FROM project-portfolio-410223.SQL_Exploration.PercentPopulationVaccinated;

