# filename: api_server.py
from fastapi import FastAPI
from pydantic import BaseModel
from joblib import load

app = FastAPI()
model = load("knn_model.joblib")

class SensorData(BaseModel):
    soil_moisture: float
    temperature: float
    soil_humidity: float
    ph: float
    rainfall: float
    air_humidity: float

@app.post("/predict")
def predict(data: SensorData):
    features = [[
        data.soil_moisture,
        data.temperature,
        data.soil_humidity,
        data.ph,
        data.rainfall,
        data.air_humidity
    ]]
    prediction = model.predict(features)[0]
    return {"needs_watering": prediction}
