import torch
import sys
from PIL import Image
from torchvision import transforms
import urllib.request
import json
import os

MODEL_PATH = "mobilenet_v2.pt"
LABELS_URL = "https://raw.githubusercontent.com/anishathalye/imagenet-simple-labels/master/imagenet-simple-labels.json"
LABELS_FILE = "imagenet_labels.json"


def get_labels():
    # Завантаження міток класів ImageNet, якщо їх немає
    if not os.path.exists(LABELS_FILE):
        print("Завантаження міток класів...")
        try:
            with urllib.request.urlopen(LABELS_URL) as url:
                data = json.loads(url.read().decode())
                with open(LABELS_FILE, 'w') as f:
                    json.dump(data, f)
        except Exception as e:
            print(f"Не вдалося завантажити мітки: {e}. Виводитимемо лише ID.")
            return None

    with open(LABELS_FILE, 'r') as f:
        return json.load(f)


def preprocess_image(image_path):
    input_image = Image.open(image_path).convert('RGB')
    preprocess = transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(224),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])
    input_tensor = preprocess(input_image)
    return input_tensor.unsqueeze(0)  # Додаємо batch dimension


def predict(image_path):
    if not os.path.exists(MODEL_PATH):
        print(f"Помилка: Модель {MODEL_PATH} не знайдена.")
        sys.exit(1)

    # Завантаження моделі
    model = torch.jit.load(MODEL_PATH)
    model.eval()

    # Обробка зображення
    input_batch = preprocess_image(image_path)

    # Передбачення
    with torch.no_grad():
        output = model(input_batch)

    # Softmax для отримання ймовірностей
    probabilities = torch.nn.functional.softmax(output[0], dim=0)

    # Отримання Top-3
    top3_prob, top3_id = torch.topk(probabilities, 3)

    labels = get_labels()

    print(f"\n--- Результати для {image_path} ---")
    for i in range(3):
        class_id = top3_id[i].item()
        score = top3_prob[i].item()
        class_name = labels[class_id] if labels else f"Class ID {class_id}"
        print(f"{i + 1}. {class_name}: {score * 100:.2f}%")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Використання: python inference.py <path_to_image>")
        sys.exit(1)

    image_path = sys.argv[1]
    if not os.path.exists(image_path):
        print(f"Файл {image_path} не знайдено.")
        sys.exit(1)

    predict(image_path)