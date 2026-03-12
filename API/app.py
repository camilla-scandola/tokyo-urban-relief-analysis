from flask import Flask, jsonify, request
from sqlalchemy import create_engine, text

app = Flask(__name__)
engine = create_engine("mysql+pymysql://root:Lucy_Heartfilia!2025@localhost/tokyo_smart_city")

# --- WARDS ---

@app.route("/api/wards", methods=["GET"])
def get_wards():
    limit = request.args.get("limit", 23)
    offset = request.args.get("offset", 0)
    with engine.connect() as conn:
        result = conn.execute(text("""
            SELECT w.tokyo_ward, w.area_km2,
                   p.park_percent_of_ward,
                   d.ground_coverage_percent, d.volume_per_km2
            FROM ward_area w
            LEFT JOIN ward_parks_latest_norm p ON w.tokyo_ward = p.tokyo_ward
            LEFT JOIN ward_building_density_norm d ON w.tokyo_ward = d.tokyo_ward
            LIMIT :limit OFFSET :offset
        """), {"limit": int(limit), "offset": int(offset)})
        return jsonify([dict(row._mapping) for row in result])

@app.route("/api/wards/<ward_name>", methods=["GET"])
def get_ward(ward_name):
    with engine.connect() as conn:
        result = conn.execute(text("""
            SELECT w.tokyo_ward, w.area_km2,
                   p.park_percent_of_ward,
                   d.ground_coverage_percent, d.volume_per_km2,
                   f.pct_roof_area_in_high_flood_risk,
                   c.casbee_per_km2
            FROM ward_area w
            LEFT JOIN ward_parks_latest_norm p ON w.tokyo_ward = p.tokyo_ward
            LEFT JOIN ward_building_density_norm d ON w.tokyo_ward = d.tokyo_ward
            LEFT JOIN ward_flood_exposure f ON w.tokyo_ward = f.tokyo_ward
            LEFT JOIN ward_casbee_normalized c ON w.tokyo_ward = c.tokyo_ward
            WHERE w.tokyo_ward = :ward
        """), {"ward": ward_name})
        row = result.fetchone()
        if not row:
            return jsonify({"error": "Ward not found"}), 404
        return jsonify(dict(row._mapping))

# --- BUILDINGS ---

@app.route("/api/buildings", methods=["GET"])
def get_buildings():
    ward = request.args.get("ward")
    rank = request.args.get("rank")
    year = request.args.get("year")
    
    query = "SELECT * FROM casbee WHERE 1=1"
    params = {}
    if ward:
        query += " AND tokyo_ward = :ward"
        params["ward"] = ward
    if rank:
        query += " AND rank = :rank"
        params["rank"] = rank
    if year:
        query += " AND eval_year = :year"
        params["year"] = int(year)
    query += " LIMIT 50"
    
    with engine.connect() as conn:
        result = conn.execute(text(query), params)
        return jsonify([dict(row._mapping) for row in result])

@app.route("/api/buildings/<int:building_id>", methods=["GET"])
def get_building(building_id):
    with engine.connect() as conn:
        result = conn.execute(text(
            "SELECT * FROM casbee WHERE id = :id"
        ), {"id": building_id})
        row = result.fetchone()
        if not row:
            return jsonify({"error": "Building not found"}), 404
        return jsonify(dict(row._mapping))

if __name__ == "__main__":
    app.run(debug=True)
