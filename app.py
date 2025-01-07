from flask import Flask, request, jsonify
import json
import requests
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

primary_endpoint = "http://localhost:9200"
secondary_endpoint = "http://localhost:9201"
username = "admin"
password = "admin"

# Global variable to store the current active endpoint
current_endpoint = primary_endpoint

def search_prefix(keywords):
    global current_endpoint

    if not keywords:
        return None

    keywords = keywords.split(' ')
    if len(keywords) > 1:
        prefix = keywords[-1]
        phrase = ' '.join(keywords[:-1])
        query = {
            'query': {
                'bool': {
                    'must': [
                        {
                            'prefix': {
                                'title': prefix
                            }
                        },
                        {
                            'match': {
                                'title': {
                                    'query': phrase,
                                    'minimum_should_match': '100%'
                                }
                            }
                        }
                    ]
                }
            }
        }
    else:
        keywords = ' '.join(keywords)
        query = {
            'query': {
                'prefix': {
                    'title': keywords
                }
            }
        }

    query = json.dumps(query)
    headers = {'Content-type': 'application/json'}

    # Try the current endpoint
    try:
        url = f"{current_endpoint}/nutch/_search"
        r = requests.post(url, auth=(username, password), data=query, headers=headers, timeout=5)
        if r.status_code == 200:
            return r.json()
    except requests.RequestException as e:
        print(f"Failed to connect to {current_endpoint}: {e}")

    # Switch to the secondary endpoint if the current fails
    if current_endpoint == primary_endpoint:
        print("Switching to secondary endpoint")
        current_endpoint = secondary_endpoint
    else:
        print("Secondary endpoint also failed")

    # Retry with the new endpoint
    try:
        url = f"{current_endpoint}/nutch/_search"
        r = requests.post(url, auth=(username, password), data=query, headers=headers, timeout=5)
        if r.status_code == 200:
            return r.json()
    except requests.RequestException as e:
        print(f"Failed to connect to {current_endpoint}: {e}")

    # If all attempts fail, return an error
    return {'error': 'Both endpoints are unavailable'}

@app.route('/search', methods=['POST'])
def search():
    data = request.get_json()
    keywords = data.get('query', '')
    results = search_prefix(keywords)
    return jsonify(results)

if __name__ == '__main__':
    app.run(debug=True)
