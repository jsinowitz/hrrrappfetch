from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import os
import pygrib
import matplotlib.pyplot as plt
import imageio
import geopandas as gpd
from herbie import Herbie
from datetime import datetime, timedelta
from PIL import Image
import time
import shutil

app = Flask(__name__)
CORS(app)  # Enable Cross-Origin Resource Sharing for frontend integration

# Load US state boundaries from shapefile using GeoPandas
shapefile_path = "/app/data/ne_50m_admin_1_states_provinces_lakes.shp"  # Updated path
us_states = None  # Initialize as None in case the shapefile isn't present
if os.path.exists(shapefile_path):
    us_states = gpd.read_file(shapefile_path)

# Predefined regions
predefined_regions = {
    "Central": {"lon_min": -105, "lon_max": -85, "lat_min": 35, "lat_max": 50},
    "Columbia River Basin": {"lon_min": -125, "lon_max": -110, "lat_min": 40, "lat_max": 50},
    "Dakotas - North and South": {"lon_min": -105, "lon_max": -95, "lat_min": 40, "lat_max": 50},
    "Deep South": {"lon_min": -95, "lon_max": -75, "lat_min": 25, "lat_max": 35},
    "East": {"lon_min": -85, "lon_max": -65, "lat_min": 35, "lat_max": 45},
    "Great Lakes": {"lon_min": -95, "lon_max": -75, "lat_min": 35, "lat_max": 49},
}

# Utility functions
def download_data(attempt_time, product, max_retries=3, retry_delay=5):
    attempt = 0
    while attempt < max_retries:
        try:
            H = Herbie(attempt_time, model="hrrr", product=product, source="aws")
            file_path = H.download()
            return file_path, attempt_time
        except Exception as e:
            print(f"Error downloading data for {attempt_time}: {e}")
            attempt += 1
            time.sleep(retry_delay)
    return None, attempt_time

def plot_variable(file_path, time, output_dir, frame_num, variable_name, variable_level, lon_min, lon_max, lat_min, lat_max):
    try:
        grbs = pygrib.open(file_path)
        if variable_level:
            data = grbs.select(name=variable_name, level=variable_level)
        else:
            data = grbs.select(name=variable_name)
        
        if not data:
            print(f"No data found for {variable_name} at {time}")
            return

        data = data[0]
        lats, lons = data.latlons()
        values = data.values

        fig, ax = plt.subplots(figsize=(10, 6), dpi=100)
        contour = ax.contourf(lons, lats, values, cmap='viridis')
        if us_states is not None:
            us_states.boundary.plot(ax=ax, color='black', linewidth=0.5)
        ax.set_xlim([lon_min, lon_max])
        ax.set_ylim([lat_min, lat_max])
        fig.colorbar(contour, label=f'{variable_name}')
        ax.set_title(f"HRRR {variable_name}\nValid Time: {time}")
        ax.set_xlabel('Longitude')
        ax.set_ylabel('Latitude')

        output_path = os.path.join(output_dir, f"frame_{frame_num:03d}.png")
        plt.savefig(output_path, bbox_inches='tight')
        plt.close(fig)

    except Exception as e:
        print(f"Error plotting variable for {time}: {e}")

def create_gif(output_dir, total_frames):
    images = []
    for i in range(total_frames):
        try:
            img_path = os.path.join(output_dir, f"frame_{i:03d}.png")
            with Image.open(img_path) as img:
                images.append(img.copy())
        except Exception as e:
            print(f"Error opening frame {i}: {e}")
    if not images:
        return None
    output_gif_path = os.path.join(output_dir, "HRRR_GIF.gif")
    images[0].save(output_gif_path, save_all=True, append_images=images[1:], loop=0, duration=100)
    return output_gif_path

@app.route('/generate-gif', methods=['POST'])
def generate_gif():
    data = request.json
    region = data.get("region")
    if region == "Custom":
        try:
            lon_min, lon_max = float(data["lon_min"]), float(data["lon_max"])
            lat_min, lat_max = float(data["lat_min"]), float(data["lat_max"])
        except (KeyError, ValueError) as e:
            return jsonify({"error": "Invalid custom coordinates"}), 400
    else:
        if region not in predefined_regions:
            return jsonify({"error": "Invalid region selected"}), 400
        bounds = predefined_regions[region]
        lon_min, lon_max = bounds["lon_min"], bounds["lon_max"]
        lat_min, lat_max = bounds["lat_min"], bounds["lat_max"]

    date_input = data.get("date")
    start_hour = int(data.get("start_hour", 0))
    end_hour = int(data.get("end_hour", 0))
    variable = data.get("variable")

    variable_info = {
        "500mb Heights": {"name": "Geopotential height", "level": 500, "product": "prs"},
        "2m Temperature": {"name": "Temperature", "level": 1013, "product": "sfc"},
    }

    if variable not in variable_info:
        return jsonify({"error": "Invalid variable selected"}), 400

    variable_meta = variable_info[variable]
    variable_name = variable_meta["name"]
    variable_level = variable_meta["level"]
    product = variable_meta["product"]

    output_dir = "/tmp/HRRR_GIF"
    os.makedirs(output_dir, exist_ok=True)

    current_time = datetime.strptime(f"{date_input} {start_hour:02d}", "%Y-%m-%d %H")
    end_time = datetime.strptime(f"{date_input} {end_hour:02d}", "%Y-%m-%d %H")
    frame_num = 0

    while current_time <= end_time:
        file_path, _ = download_data(current_time, product)
        if file_path:
            plot_variable(file_path, current_time, output_dir, frame_num, variable_name, variable_level, lon_min, lon_max, lat_min, lat_max)
            frame_num += 1
        current_time += timedelta(hours=1)

    gif_path = create_gif(output_dir, frame_num)
    if gif_path:
        # Clean up after creating GIF
        shutil.rmtree(output_dir)
        return send_file(gif_path, as_attachment=True, download_name="HRRR_GIF.gif", mimetype="image/gif")
    else:
        shutil.rmtree(output_dir)  # Clean up even if GIF creation fails
        return jsonify({"error": "Failed to generate GIF"}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
