FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install fastapi uvicorn pydantic
COPY app/ ./app
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]