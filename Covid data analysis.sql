SELECT *
FROM CovidDeaths
WHERE continent is NOT NULL
ORDER BY 3, 4;

--Select the data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent is NOT NULL
ORDER BY 1, 2;

--Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percent
FROM CovidDeaths
WHERE location LIKE '%states%' AND continent is NOT NULL
ORDER BY 1, 2;

-- Looking at the total cases vs. the population
-- Shows what percentage of population got COVID
SELECT location, date, population, total_cases, (total_cases/population)*100 AS percent_pop_infected
FROM CovidDeaths
WHERE continent is NOT NULL
ORDER BY 1, 2;

-- Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS highest_infection_rate, MAX((total_cases/population)*100) AS percent_pop_infected
FROM CovidDeaths
WHERE continent is NOT NULL
GROUP BY population, location
ORDER BY percent_pop_infected DESC

--Showing the countries with the highest death count per population
SELECT location, MAX(total_deaths) AS total_death_count
FROM CovidDeaths
WHERE continent is NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

-- Let's break things down by continent
-- Showing the continents with the highest death count
SELECT continent, MAX(total_deaths) AS total_death_count
FROM CovidDeaths
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC

-- Global numbers

SELECT SUM(cast(new_cases as numeric)) AS total_cases, SUM(cast(new_deaths as numeric)) AS total_deaths, 
    SUM(cast(new_deaths as numeric))/SUM(cast(new_cases as numeric))*100 AS death_percent
FROM CovidDeaths
WHERE continent is NOT NULL
--GROUP BY date
ORDER BY 1, 2;

-- Joining and looking at total population vs. vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
    SUM(cast(new_vaccinations as numeric)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) 
    AS rolling_people_vaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
ORDER BY 2, 3

-- Use CTE 
WITH PopVsVac(Continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
    SUM(cast(new_vaccinations as numeric)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) 
    AS rolling_people_vaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
WHERE continent is NOT NULL
--ORDER BY 2, 3
) 
SELECT *, (rolling_people_vaccinated/population)*100
FROM PopVsVac

-- Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    Rolling_people_vaccinated numeric,
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
    SUM(cast(new_vaccinations as numeric)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) 
    AS rolling_people_vaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
WHERE continent is NOT NULL
--ORDER BY 2, 3

SELECT *, (rolling_people_vaccinated/population)*100
FROM #PercentPopulationVaccinated

-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
    SUM(cast(new_vaccinations as numeric)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) 
    AS rolling_people_vaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2, 3

SELECT * 
FROM PercentPopulationVaccinated