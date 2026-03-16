# MLOps Final Project: AI-Powered Inference Service with Drift Detection

Цей проєкт реалізує повний життєвий цикл MLOps системи: від розгортання моделі в Kubernetes до моніторингу дрейфу даних та автоматизації перенавчання.

##️ Архітектура системи
- **Backend:** FastAPI (Python 3.9)
- **Deployment:** Helm + ArgoCD (GitOps)
- **Monitoring:** Prometheus + Loki + Grafana
- **Drift Detection:** Custom logic integrated into the Inference Service
- **CI/CD:** GitLab CI (`.gitlab-ci.yml`)

---

## Етапи реалізації та пройдені кроки

### 1. Контейнеризація та локальне оточення
- Створено `Dockerfile` на базі `python:3.9-slim`.
- Налаштовано середовище **Minikube** (драйвер Docker, архітектура arm64).
- Використано локальний Docker-демон Minikube (`eval $(minikube docker-env)`) для збірки образу `aiops-service:latest` безпосередньо в кластері, що дозволило уникнути зайвих push/pull операцій.

### 2. Infrastructure as Code (Helm)
- Створено Helm-чарт для сервісу:
    - **Deployment**: Налаштовано `imagePullPolicy: Never` для використання локальних образів. Описано ресурси та порти.
    - **Service**: Створено ClusterIP сервіс для внутрішньої комунікації.
- Розгорнуто стек моніторингу через **Loki-stack** (Loki + Prometheus + Grafana + Promtail) у namespace `monitoring`.

### 3. GitOps з ArgoCD
- Встановлено ArgoCD в кластер.
- Створено `argocd/application.yaml` для автоматичної синхронізації стану кластера з GitHub репозиторієм.

### 4. Реалізація Drift Detector
- В сервіс інтегровано логіку детекції дрейфу даних (Data Drift).
- Система аналізує вхідні ознаки (`features`) та з ймовірністю 20% імітує виявлення дрейфу, логуючи подію в JSON-форматі (`DRIFT_DETECTED`) для подальшого збору системою Loki.

---

## Демонстрація роботи

### Перевірка Inference API
Запит до розгорнутого сервісу через `port-forward`:
```bash
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"features": [1.5, 2.5, 3.5]}'
```
**Результат:** `{"prediction":0,"latency":0.0726}`

### Виявлення Drift Detection (Логи)
Перевірка спрацювання детектора дрейфу в логах поду:
```bash
kubectl logs -n mlops -l app=aiops-service | grep DRIFT_DETECTED
```
**Приклад логу:** `{"status": "DRIFT_DETECTED", "score": 0.8037018488049178, "timestamp": 1773687517.7982144}`

### Моніторинг у Grafana
- Підключено Loki як Datasource.
- Використано LogQL запит `{app="aiops-service"}` для візуалізації логів інференсу та алертів дрейфу.
- Незважаючи на затримки індексації Promtail у Minikube, логіка логування повністю готова до продакшн-використання.

---

## Pipeline перенавчання (GitLab CI)
Файл `.gitlab-ci.yml` містить стадію `retrain-model`, яка автоматизує:
1. Запуск скрипта `model/train.py`.
2. Збірку нового Docker-образу.
3. Оновлення тега в Helm-чарті (GitOps loop).