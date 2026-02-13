import torch
import torchvision.models as models

def save_model():
    print("Завантаження моделі MobileNetV2...")
    # Використовуємо ваги за замовчуванням
    model = models.mobilenet_v2(weights=models.MobileNet_V2_Weights.DEFAULT)
    model.eval()

    # Створюємо приклад вхідних даних (batch_size, channels, height, width)
    example_input = torch.rand(1, 3, 224, 224)

    print("Трасування моделі (Tracing)...")
    traced_script_module = torch.jit.trace(model, example_input)

    output_file = "mobilenet_v2.pt"
    traced_script_module.save(output_file)
    print(f"Модель успішно збережена у {output_file}")

if __name__ == "__main__":
    save_model()