# 🗾 緑の東京、未来へ 🌱
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
