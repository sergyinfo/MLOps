import os
import pickle


def train():
    print("Starting model retraining...")
    # Тут зазвичай завантаження даних з S3 та тренування
    mock_model = {"model_name": "RandomForest", "version": "2.0"}

    os.makedirs('model', exist_ok=True)
    with open('model/model.pkl', 'wb') as f:
        pickle.dump(mock_model, f)
    print("New model saved to model/model.pkl")


if __name__ == "__main__":
    train()