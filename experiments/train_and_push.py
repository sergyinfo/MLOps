import joblib
import os
import mlflow
import mlflow.sklearn
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, log_loss
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway
import shutil

# Налаштування підключення до сервісів (через port-forward)
os.environ["MLFLOW_TRACKING_URI"] = "http://localhost:5000"
# Налаштування для MinIO (щоб MLflow міг зберігати артефакти)
os.environ["MLFLOW_S3_ENDPOINT_URL"] = "http://localhost:9000"
os.environ["AWS_ACCESS_KEY_ID"] = "admin"
os.environ["AWS_SECRET_ACCESS_KEY"] = "password123"

PUSHGATEWAY_URL = 'localhost:9091'


def train_and_push():
    # Завантаження датасету
    iris = load_iris()
    X_train, X_test, y_train, y_test = train_test_split(iris.data, iris.target, test_size=0.2, random_state=42)

    # Параметри для експериментів
    experiments = [
        {"n_estimators": 10, "max_depth": 3},
        {"n_estimators": 50, "max_depth": 5},
        {"n_estimators": 100, "max_depth": 10}
    ]

    best_accuracy = 0
    best_run_id = None

    mlflow.set_experiment("Iris_Classification")

    # Ініціалізація метрик для Prometheus
    registry = CollectorRegistry()
    acc_gauge = Gauge('mlflow_accuracy', 'Accuracy of the ML model', ['run_id'], registry=registry)
    loss_gauge = Gauge('mlflow_loss', 'Log loss of the ML model', ['run_id'], registry=registry)

    print("🚀 Починаємо тренування моделей...")

    for params in experiments:
        with mlflow.start_run() as run:
            run_id = run.info.run_id

            # Тренування моделі
            clf = RandomForestClassifier(**params, random_state=42)
            clf.fit(X_train, y_train)

            # Прогнозування та метрики
            y_pred = clf.predict(X_test)
            y_proba = clf.predict_proba(X_test)

            acc = accuracy_score(y_test, y_pred)
            loss = log_loss(y_test, y_proba)

            # Логування в MLflow
            mlflow.log_params(params)
            mlflow.log_metrics({"accuracy": acc, "loss": loss})
            print("📦 Зберігаємо модель як артефакт...")
            model_filename = "iris_model.pkl"
            joblib.dump(clf, model_filename)

            # Завантажуємо файл у MLflow (це 100% не викликає 404)
            mlflow.log_artifact(model_filename, artifact_path="model")

            # Видаляємо локальний тимчасовий файл
            if os.path.exists(model_filename):
                os.remove(model_filename)

            print(
                f"✅ Run ID: {run_id} | Trees: {params['n_estimators']} | Depth: {params['max_depth']} | Accuracy: {acc:.4f}")

            # Відправка метрик у PushGateway
            acc_gauge.labels(run_id=run_id).set(acc)
            loss_gauge.labels(run_id=run_id).set(loss)
            push_to_gateway(PUSHGATEWAY_URL, job='mlflow_experiments', registry=registry)

            # Перевірка на найкращу модель
            if acc > best_accuracy:
                best_accuracy = acc
                best_run_id = run_id

    print(f"\n🏆 Найкраща модель знайдена! Run ID: {best_run_id} (Accuracy: {best_accuracy:.4f})")

    # Завантаження найкращої моделі локально
    print("💾 Завантажуємо найкращу модель у папку best_model/ ...")
    client = mlflow.tracking.MlflowClient()
    local_dir = "../best_model"

    # Очищаємо папку, якщо вона вже існує
    if os.path.exists(local_dir):
        shutil.rmtree(local_dir)

    mlflow.artifacts.download_artifacts(run_id=best_run_id, artifact_path="model", dst_path=local_dir)
    print("🎉 Готово! Модель збережена.")


if __name__ == "__main__":
    train_and_push()