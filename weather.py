import requests
from flask import Flask, request, jsonify

app = Flask(__name__)
BASE_URL = "https://api.openweathermap.org/data/2.5/weather"

@app.route('/weather', methods=['GET'])
def get_weather():
    city = request.args.get('city', 'London')
    response = requests.get(f"{BASE_URL}?q={city}&appid={API_KEY}&units=metric")
    return jsonify(response.json())

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
