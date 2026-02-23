CREATE DATABASE IF NOT EXISTS tokyo_smart_city;
USE tokyo_smart_city;

-- Create table 1: Plateau dataset (urban planning of Tokyo)

DROP TABLE IF EXISTS plateau_buildings;

CREATE TABLE plateau_buildings (
town_code VARCHAR(20),
chome_code VARCHAR(20),
flood_scale VARCHAR(50),
measured_height DOUBLE,
country_name VARCHAR(100),
locality_name VARCHAR(100),
building_roof_edge_area DOUBLE,
city INT,
survey_year INT,
name VARCHAR(255),
tokyo_ward VARCHAR(100),
max_flood_depth DOUBLE
);

CREATE INDEX idx_buildings_ward ON plateau_buildings (tokyo_ward);
CREATE INDEX idx_buildings_year ON plateau_buildings (survey_year);

-- Create table 2: Government of Tokyo Open Data (green areas)

DROP TABLE IF EXISTS tokyo_parks;

CREATE TABLE tokyo_parks (
id BIGINT AUTO_INCREMENT PRIMARY KEY,
date VARCHAR(20),
date_japanese_era VARCHAR(50),
seq INT,
municipality_class VARCHAR(100),
ward_jp VARCHAR(100),
park_class_jp VARCHAR(100),
park_count DOUBLE,
park_area_m2 VARCHAR(50),
tokyo_ward VARCHAR(100),
municipality_class_en VARCHAR(100),
park_class_en VARCHAR(100),
park_area_m2_num DOUBLE,
year INT
);

CREATE INDEX idx_parks_ward ON tokyo_parks (tokyo_ward);
CREATE INDEX idx_parks_year ON tokyo_parks (year);

SET SQL_SAFE_UPDATES = 0;

UPDATE tokyo_parks
SET
  year = CAST(SUBSTRING(`date`, 1, 4) AS UNSIGNED),
  park_area_m2_num = CAST(REPLACE(park_area_m2, ',', '') AS DECIMAL(15,2));
  
SET SQL_SAFE_UPDATES = 1;

-- Create table 3: CASBEE certified sustainable buildings data

DROP TABLE IF EXISTS casbee;

CREATE TABLE casbee (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    row_no INT,
    certifier VARCHAR(255),
    cert_no VARCHAR(100),
    building_name VARCHAR(255),
    eval_date VARCHAR(50),
    evaluator VARCHAR(255),
    location VARCHAR(255),
    `use` VARCHAR(255),
    tool_version VARCHAR(50),
    `rank` VARCHAR(50),
    other_date VARCHAR(50),
    flag DOUBLE,
    building_name_en VARCHAR(255),
    location_en VARCHAR(255),
    use_en VARCHAR(255),
    tokyo_ward VARCHAR(100),
    full_address VARCHAR(255),
    latitude DOUBLE,
    longitude DOUBLE,
    eval_year INT
);

CREATE INDEX idx_casbee_ward ON casbee (tokyo_ward);
CREATE INDEX idx_casbee_year ON casbee (eval_year);

SET SQL_SAFE_UPDATES = 0;

UPDATE casbee
SET eval_year = CAST(SUBSTRING(eval_date, 1, 4) AS UNSIGNED)
WHERE eval_date IS NOT NULL
  AND eval_date <> '';
  
SET SQL_SAFE_UPDATES = 1;

-- Normalize ward names for each table

SET SQL_SAFE_UPDATES = 0;

UPDATE plateau_buildings SET tokyo_ward = TRIM(tokyo_ward);
UPDATE tokyo_parks       SET tokyo_ward = TRIM(tokyo_ward);
UPDATE casbee            SET tokyo_ward = TRIM(tokyo_ward);

SET SQL_SAFE_UPDATES = 1;

-- Create Table 4: Government of Tokyo Open Data (district surface area)

DROP TABLE IF EXISTS ward_area;

CREATE TABLE ward_area (
    tokyo_ward VARCHAR(100),
    area_km2 DOUBLE
);

-- Query 1 - (building density): Calculate total built footprint and built volume per ward

SELECT
    tokyo_ward,
    SUM(building_roof_edge_area) AS built_footprint,
    SUM(building_roof_edge_area * measured_height) AS built_volume
FROM plateau_buildings
WHERE tokyo_ward IS NOT NULL AND tokyo_ward <> ''
GROUP BY tokyo_ward
ORDER BY built_volume DESC;

-- Create a table to sum total building footprint and total building volume for each

CREATE OR REPLACE VIEW ward_building_density AS
SELECT
    tokyo_ward,
    SUM(building_roof_edge_area) AS built_footprint,
    SUM(building_roof_edge_area * measured_height) AS built_volume
FROM plateau_buildings
WHERE tokyo_ward IS NOT NULL
  AND tokyo_ward <> ''
GROUP BY tokyo_ward;

SELECT *
FROM ward_building_density
ORDER BY built_volume DESC;

-- Query 2 (building density): Calculate percentage of built land over ward total surface area

SELECT
    d.tokyo_ward,
    ROUND(a.area_km2, 2) AS area_km2,
	ROUND((d.built_footprint / (a.area_km2 * 1000000)) * 100, 2) AS ground_coverage_percent,
	ROUND(d.built_volume / a.area_km2, 2) AS volume_per_km2
FROM ward_building_density d
JOIN ward_area a
    ON d.tokyo_ward = a.tokyo_ward
ORDER BY ground_coverage_percent DESC;

-- Create a table view to convert building totals into built density indicators: percentage of ward covered by buildings and built volume per km²

CREATE OR REPLACE VIEW ward_building_density_norm AS
SELECT
    d.tokyo_ward,
    ROUND(a.area_km2, 2) AS area_km2,
    ROUND((d.built_footprint / (a.area_km2 * 1000000)) * 100, 2) AS ground_coverage_percent,
    ROUND(d.built_volume / a.area_km2, 2) AS volume_per_km2
FROM ward_building_density d
JOIN ward_area a
    ON d.tokyo_ward = a.tokyo_ward;

SELECT *
FROM ward_building_density_norm
ORDER BY ground_coverage_percent DESC;

-- Query 3 (parks): Calculate total public park area per ward per year (to analyze green space over time)

SELECT
    tokyo_ward,
    year,
    ROUND(SUM(park_area_m2_num), 2) AS park_area_m2
FROM tokyo_parks
WHERE tokyo_ward IS NOT NULL
  AND tokyo_ward <> ''
GROUP BY tokyo_ward, year
ORDER BY tokyo_ward, year;

-- Create a table view to aggregate total public park area per ward for each year

CREATE OR REPLACE VIEW ward_parks_year AS
SELECT
    tokyo_ward,
    year,
    ROUND(SUM(park_area_m2_num), 2) AS park_area_m2
FROM tokyo_parks
WHERE tokyo_ward IS NOT NULL
  AND tokyo_ward <> ''
GROUP BY tokyo_ward, year;

SELECT *
FROM ward_parks_year
ORDER BY tokyo_ward DESC;

-- Query 4 (parks): Normalize park area by ward size to compute the percentage of each ward covered by parks per year

SELECT
    p.tokyo_ward,
    p.year,
    ROUND(p.park_area_m2, 2) AS park_area_m2,
    ROUND(a.area_km2, 2) AS area_km2,
	ROUND((p.park_area_m2 / (a.area_km2 * 1000000)) * 100, 2) AS park_percent_of_ward

FROM ward_parks_year p
JOIN ward_area a
    ON p.tokyo_ward = a.tokyo_ward

ORDER BY p.tokyo_ward, p.year;

-- Create a table to view yearly park area as a percentage of each ward’s total surface, to compare green space evolution across wards

CREATE OR REPLACE VIEW ward_parks_norm_year AS
SELECT
    p.tokyo_ward,
    p.year,
    ROUND(p.park_area_m2, 2) AS park_area_m2,
    ROUND(a.area_km2, 2) AS area_km2,
    ROUND(
        (p.park_area_m2 / (a.area_km2 * 1000000)) * 100,
        2
    ) AS park_percent_of_ward
FROM ward_parks_year p
JOIN ward_area a
    ON p.tokyo_ward = a.tokyo_ward;

SELECT *
FROM ward_parks_norm_year
ORDER BY tokyo_ward DESC;

-- Query 5 (CASBEE): Count total number of CASBEE-certified buildings per ward (snapshot of sustainability adoption by location)

SELECT
    tokyo_ward,
    COUNT(*) AS casbee_count
FROM casbee
WHERE tokyo_ward IS NOT NULL
  AND tokyo_ward <> ''
GROUP BY tokyo_ward
ORDER BY tokyo_ward;

-- Create a table to view the total number of certified buildings per ward

CREATE OR REPLACE VIEW ward_casbee_total AS
SELECT
    tokyo_ward,
    COUNT(*) AS casbee_total
FROM casbee
WHERE tokyo_ward IS NOT NULL
  AND tokyo_ward <> ''
GROUP BY tokyo_ward;


-- Query 6 (CASBEE): Count number of CASBEE-certified buildings per ward per year (trend analysis by ward)

SELECT
    tokyo_ward,
    eval_year,
    COUNT(*) AS casbee_count
FROM casbee
WHERE tokyo_ward IS NOT NULL
  AND tokyo_ward <> ''
  AND eval_year IS NOT NULL
GROUP BY tokyo_ward, eval_year
ORDER BY tokyo_ward, eval_year;

-- Create a table to view the number of green certified buildings per ward over the years, to track sustainability trends over time

CREATE OR REPLACE VIEW ward_casbee_year AS
SELECT
    tokyo_ward,
    eval_year,
    COUNT(*) AS casbee_count
FROM casbee
WHERE tokyo_ward IS NOT NULL
  AND tokyo_ward <> ''
  AND eval_year IS NOT NULL
GROUP BY tokyo_ward, eval_year;

SELECT *
FROM ward_casbee_year
ORDER BY eval_year DESC;

-- Query 7 (CASBEE): Count total number of CASBEE-certified buildings per year across all wards (overall citywide trend)

SELECT
    eval_year,
    COUNT(*) AS casbee_count
FROM casbee
WHERE tokyo_ward IS NOT NULL
  AND tokyo_ward <> ''
  AND eval_year IS NOT NULL
GROUP BY eval_year
ORDER BY eval_year;

-- Create a table to selects the most recent park percentage value for each ward to enable snapshot comparison with building density

CREATE OR REPLACE VIEW ward_parks_latest_norm AS
SELECT
    p.tokyo_ward,
    p.year,
    p.park_percent_of_ward,
    p.park_area_m2
FROM ward_parks_norm_year p
JOIN (
    SELECT tokyo_ward, MAX(year) AS max_year
    FROM ward_parks_norm_year
    GROUP BY tokyo_ward
) latest
  ON p.tokyo_ward = latest.tokyo_ward
 AND p.year = latest.max_year;
 
SELECT *
FROM ward_parks_latest_norm
ORDER BY tokyo_ward DESC;

-- Create a table view to estimate flood exposure per ward using roof area as a proxy:
-- total roof area proxy, roof area proxy in high flood risk (e.g., >= 2m), and the percentage share in high risk

CREATE OR REPLACE VIEW ward_flood_exposure AS
SELECT
  tokyo_ward,
  SUM(building_roof_edge_area) AS total_roof_area_proxy,

  SUM(
    CASE
      WHEN max_flood_depth IS NOT NULL AND max_flood_depth >= 2 THEN building_roof_edge_area
      ELSE 0
    END
  ) AS roof_area_proxy_high_flood_risk,

  ROUND(
    100 * SUM(
      CASE
        WHEN max_flood_depth IS NOT NULL AND max_flood_depth >= 2 THEN building_roof_edge_area
        ELSE 0
      END
    ) / NULLIF(SUM(building_roof_edge_area), 0),
    2
  ) AS pct_roof_area_proxy_in_high_flood_risk

FROM plateau_buildings
WHERE tokyo_ward IS NOT NULL
  AND tokyo_ward <> ''
  AND building_roof_edge_area IS NOT NULL
  AND building_roof_edge_area > 0
GROUP BY tokyo_ward;

SELECT *
FROM ward_flood_exposure
ORDER BY tokyo_ward DESC;

-- Create a table view to estimate urban intensity per ward using area/volume proxies:
-- total roof area proxy, total volume proxy, and average height proxy (volume / roof area)

CREATE OR REPLACE VIEW ward_intensity_proxy AS
SELECT
  tokyo_ward,
  SUM(building_roof_edge_area) AS roof_area_proxy,
  SUM(building_roof_edge_area * measured_height) AS volume_proxy,
  ROUND(
    SUM(building_roof_edge_area * measured_height) /
    NULLIF(SUM(building_roof_edge_area), 0),
    2
  ) AS avg_height_proxy
FROM plateau_buildings
WHERE tokyo_ward IS NOT NULL
  AND tokyo_ward <> ''
  AND measured_height IS NOT NULL
  AND measured_height > 0
  AND building_roof_edge_area IS NOT NULL
  AND building_roof_edge_area > 0
GROUP BY tokyo_ward;

SELECT *
FROM ward_intensity_proxy
ORDER BY tokyo_ward DESC;

-- Create a table view to normalize CASBEE adoption by ward size and by built environment proxies:
-- CASBEE per km², CASBEE per roof area proxy, and CASBEE per volume proxy

CREATE OR REPLACE VIEW ward_casbee_normalized AS
SELECT
  i.tokyo_ward,
  COALESCE(c.casbee_total, 0) AS casbee_total,
  a.area_km2,
  ROUND(COALESCE(c.casbee_total, 0) / NULLIF(a.area_km2, 0), 4) AS casbee_per_km2,
  ROUND(COALESCE(c.casbee_total, 0) / NULLIF(i.roof_area_proxy, 0), 8) AS casbee_per_roof_area_proxy,
  ROUND(COALESCE(c.casbee_total, 0) / NULLIF(i.volume_proxy, 0), 10) AS casbee_per_volume_proxy
FROM ward_intensity_proxy i
JOIN ward_area a
  ON i.tokyo_ward = a.tokyo_ward
LEFT JOIN ward_casbee_total c
  ON i.tokyo_ward = c.tokyo_ward;
  
SELECT *
FROM ward_casbee_normalized
ORDER BY tokyo_ward DESC;
  
SELECT tokyo_ward, date, park_area_m2, year, park_area_m2_num
FROM tokyo_parks
LIMIT 8;
