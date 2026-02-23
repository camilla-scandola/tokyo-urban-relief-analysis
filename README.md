# 🗾 緑の東京、未来へ 🌱
Exploring the relationship between urban density and environmental relief in Tokyo
Canva presentation

---

## Data Structures

### 1. PLATEAU 3D City Model (Tokyo)

**Objective:** Convert PLATEAU CityGML data into an analysis-ready spatial database.

The PLATEAU dataset is provided in **CityGML format**, which:

- is XML-based and designed for 3D simulation rather than analysis  
- is split into thousands of tiles  
- is not directly usable in Python, SQL, or Tableau  

To make it usable, I:

- used **GDAL (`ogr2ogr`)** to convert CityGML into a **GeoPackage (`.gpkg`)**  
- merged all tiles into a **single database table**  

A GeoPackage is a **SQLite spatial database**, enabling SQL queries and efficient analysis.

For this project, I focused on the **buildings layer (`bldg`)**, resulting in:

→ ~2.7 million building records across Tokyo’s 23 wards  

---

### 2. Tokyo Metropolitan Government (Green Space Dataset)

This dataset provides:

- ward-level park area  
- temporal evolution of green space (2016–2023)  

in my analysis, it represents the primary indicator of environmental relief and urban greening** in Tokyo

---

### 3. CASBEE Certified Buildings Dataset

This dataset includes:

- sustainability-certified buildings across Tokyo  
- certification levels and temporal coverage (2005–2025)  

It is used as a proxy for **sustainable architectural practices** within the city

## SQL Aggregation Logic

All datasets are standardized to a common spatial unit: **`tokyo_ward`**.

### 1. Building Metrics (PLATEAU)

**Views:**
- `ward_building_density` (`built_footprint` = SUM(roof area); `built_volume` = SUM(roof area × height))
- `ward_building_density_norm` (`ground_coverage_percent`; `volume_per_km2`)

---

### 2. Green Space (Parks)

**Views:**
- `ward_parks_year` (park area aggregated by `ward × year`)
- `ward_parks_norm_year` (park area normalized by ward size (%))
- `ward_parks_latest_norm` (most recent park % per ward (snapshot))

---

### 3. Sustainability (CASBEE)

**Views:**
- `ward_casbee_total` (total certified buildings per ward)
- `ward_casbee_year` (certifications per `ward × year`)

---

### 4. Derived Indicators

**Views:**
- `ward_flood_exposure` (% of building footprint in high flood risk areas)
- `ward_intensity_proxy` (urban intensity (footprint, volume, avg height))
- `ward_casbee_normalized` (CASBEE per km², per footprint, per volume)

All indicators are: aggregated at **ward level**, normalized for **comparability**, structured for **cross-domain analysis (urban form, green space, sustainability)**

## Key Insights & Analytical Framework

### Core Indicators
- **Urban density**: building footprint (land use proxy) and volume / height (urban intensity)
- **Green space**: share of park area relative to ward surface
- **Sustainability**: number of CASBEE-certified buildings (normalized)
- **Flood risk**: proportion of built area exposed to high flood zones

---

### Analytical Focus
- Compare **green space distribution across wards**
- Assess relationship between **density and green infrastructure**
- Track **evolution of parks over time**
- Identify **spatial patterns and ward typologies**

---

### Urban Relief Index (Composite Metric)
A synthetic index (0–100) summarizing urban balance per ward:

- Indicators **standardized** for comparability  
- **Direction aligned** (density & flood risk penalized; green factors rewarded)  
- **Balanced weighting** across dimensions  
- Produces a **composite score** reflecting overall urban livability balance  

---

### Dashboard Structure
- **Spatial & temporal analysis**: evolution of green space over time  
- **Urban classification**: comparison of wards by density, coverage, and greenery  

---

### Key-takeaways
- 21 out of 23 wards increased green space over the past decade
  (the highest at a 36% rate compared to initial green space)
- Green growth occurs all across the city, but at different rates  
- Higher density is associated with slower greening, but doesn't necessarily prevent it
- Peripheral wards are generally greener than central ones  
- The Urban Relief Index shows big discrepancies across wards

## Languages, libraries & tools used: 
`python`, `sql`, `pandas`, `numpy`, `sqlalchemy`, `sqlite3`, `geopy`, `deep_translator`, `requests`, `Tableau`
