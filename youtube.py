import requests

API_KEY = ""

url = "https://www.googleapis.com/youtube/v3/search"
params = {
    "part": "snippet",
    "q": "",
    "maxResults": 5,
    "key": API_KEY
}

response = requests.get(url, params=params)
data = response.json()

for item in data["items"]:
    print(item["snippet"]["title"])
