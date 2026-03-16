import logging
import time
import random
import json
from fastapi import FastAPI, BackgroundTasks
from pydantic import BaseModel

app = FastAPI(title="AIOps Inference Service")

# Налаштування логування для Loki (stdout)
logging.basicConfig(level=logging.INFO, format='%(message)s')
logger = logging.getLogger("inference")


class DataInput(BaseModel):
    features: list


def run_drift_detection(data):
    """Імітація аналізу дрейфу даних (Great Expectations / Alibi Detect)"""
    drift_score = random.random()
    if drift_score > 0.8:
        # Лог, який ми побачимо в Loki та на основі якого тригериться сповіщення
        logger.info(json.dumps({
            "status": "DRIFT_DETECTED",
            "score": drift_score,
            "timestamp": time.time()
        }))
        print("ALERT: Data drift detected!")


@app.post("/predict")
async def predict(input_data: DataInput, background_tasks: BackgroundTasks):
    start_time = time.time()

    # Імітація передбачення моделі
    prediction = random.choice([0, 1])
    time.sleep(random.uniform(0.05, 0.2))  # Імітація latency

    # Запуск детектора дрейфу у фоні
    background_tasks.add_task(run_drift_detection, input_data.features)

    duration = time.time() - start_time

    # Метрики для Prometheus та логи для Loki
    logger.info(json.dumps({
        "event": "inference_request",
        "prediction": prediction,
        "latency": duration,
        "status": "success"
    }))

    return {"prediction": prediction, "latency": duration}


@app.get("/metrics")
async def metrics():
    # Ендпоінт для збору метрик Prometheus (мінімальна реалізація)
    return "inference_requests_total 1"