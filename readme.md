# MLOps Infrastructure: MLflow, MinIO, and Prometheus Stack

Цей проєкт демонструє повний життєвий цикл MLOps: від декларативного розгортання інфраструктури в Kubernetes через ArgoCD до автоматизованого тренування моделей з логуванням метрик та артефактів.

## Архітектура системи
Система побудована на базі Kubernetes (EKS) і включає:
- Compute: AWS EKS Cluster (eks-vpc-cluster).
- Network: VPC з публічними та приватними підмережами.
- Tracking: MLflow (Backend Store: PostgreSQL, Artifact Store: MinIO).
- Monitoring: Prometheus Pushgateway + Grafana (в складі Kube-Prometheus-Stack).
- CD: ArgoCD для управління інфраструктурою за принципом GitOps.]

## Як запустити інфраструктуру

### 1. Підготовка кластера (EKS)
Перш ніж розгортати сервіси, необхідно переконатися, що кластер eks-vpc-cluster запущений та доступний:

```bash
# Оновлення конфігурації kubectl для підключення до кластера
aws eks update-kubeconfig --region eu-central-1 --name eks-vpc-cluster

# Перевірка доступності вузлів
kubectl get nodes
```

### 2. Розгортання сервісів через ArgoCD
Всі маніфести застосунків знаходяться в папці argocd/applications/. Для старту синхронізації виконайте:

```bash
kubectl apply -f argocd/applications/
```

### 3. Port-Forwarding для локального доступу
Оскільки сервіси працюють всередині кластера, для роботи Python-скрипта потрібно прокинути порти:

```bash
# MLflow UI (Порт 5000)
kubectl port-forward svc/mlflow -n mlops 5000:5000

# MinIO API (Порт 9000)
kubectl port-forward svc/minio -n mlops 9000:9000

# Prometheus PushGateway (Порт 9091)
kubectl port-forward svc/pushgateway-prometheus-pushgateway -n monitoring 9091:9091

# Grafana (Порт 3000)
kubectl port-forward svc/monitoring-stack-grafana -n monitoring 3000:80
```

## Тренування моделі та логування

Скрипт experiments/train_and_push.py проводить навчання моделі RandomForestClassifier, логує метрики та зберігає артефакт моделі (.pkl) у MinIO.

Запуск скрипта:
```bash
export MLFLOW_S3_ENDPOINT_URL=http://localhost:9000
export AWS_ACCESS_KEY_ID=admin
export AWS_SECRET_ACCESS_KEY=password123
python experiments/train_and_push.py
```

## Візуалізація результатів
- MLflow UI (http://localhost:5000): Перегляд порівняльної таблиці запусків.
- Grafana (http://localhost:3000): Візуалізація метрик accuracy.
- MinIO Console (http://localhost:9001): Перевірка фізичної наявності артефакт