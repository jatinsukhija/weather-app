from flask import Flask, request, jsonify
import requests
from dotenv import load_dotenv
import os

# Load environment variables from .env file (if it exists)
load_dotenv()

app = Flask(__name__)

# Fetch API_KEY from environment variables
API_KEY = os.getenv('API_KEY')
BASE_URL = "https://api.openweathermap.org/data/2.5/weather"

@app.route('/weather', methods=['GET'])
def get_weather():
    city = request.args.get('city', 'London')
    response = requests.get(f"{BASE_URL}?q={city}&appid={API_KEY}&units=metric")

    if response.status_code != 200:
        return jsonify({"error": f"Failed to fetch weather data: {response.text}"}), response.status_code

    return jsonify(response.json())

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
