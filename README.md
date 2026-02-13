# Homework: Containerization of ML Models

## 1. Налаштування середовища
Запустіть скрипт інсталяції (потрібен sudo):
```bash
chmod +x install_dev_tools.sh
sudo ./install_dev_tools.sh
```

## 2. Підготовка моделі
Згенеруйте TorchScript модель:
```bash
python3 prepare_model.py
```
Завантажте тестове зображення:
```bash
wget -O input.jpg [https://upload.wikimedia.org/wikipedia/commons/9/99/Brooks_Chase_Ranger_of_Jolly_Dogs_Jack_Russell.jpg](https://upload.wikimedia.org/wikipedia/commons/9/99/Brooks_Chase_Ranger_of_Jolly_Dogs_Jack_Russell.jpg)
```

## 3. Запуск Docker контейнерів
Збірка:
```bash
docker build -t ml-fat -f Dockerfile.fat .
docker build -t ml-slim -f Dockerfile.slim .
```

Запуск (Fat):
```bash
docker run --rm -v $(pwd)/input.jpg:/app/input.jpg ml-fat input.jpg
```

Запуск (Slim):
```bash
docker run --rm -v $(pwd)/input.jpg:/app/input.jpg ml-slim input.jpg
```