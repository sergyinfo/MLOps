# MLOps Training Automation with AWS Step Functions

Цей проєкт реалізує автоматизований пайплайн тренування моделі за допомогою AWS Step Functions, Lambda та Terraform з інтеграцією через GitLab CI.

## Структура проєкту
- terraform/main.tf: Опис IAM ролей, Lambda-функцій та Step Function.
- terraform/lambda/: Вихідний код Python-функцій та їх архіви.
- .gitlab-ci.yml: Конфігурація CI/CD для запуску пайплайну.

## Інструкція з розгортання

### 1. Збірка Lambda-архівів
Для того щоб Terraform міг розгорнути функції, необхідно створити .zip архіви:
```bash
cd terraform/lambda
zip validate.zip validate.py
zip log_metrics.zip log_metrics.py
cd ../..
```

### 2. Розгортання інфраструктури
Виконайте ініціалізацію та застосування конфігурації Terraform:
```bash
cd terraform
terraform init
terraform apply
```
Після завершення Terraform виведе `step_function_arn`, який знадобиться для налаштування GitLab CI.

### 3. Налаштування GitLab CI
Для коректної роботи job `train-model` необхідно додати такі змінні (Variables) у налаштуваннях вашого репозиторію GitLab:
- `AWS_ACCESS_KEY_ID`: Ваш ідентифікатор доступу AWS.
- `AWS_SECRET_ACCESS_KEY`: Ваш секретний ключ AWS.
- `AWS_DEFAULT_REGION`: Регіон розгортання (напр. eu-central-1).
- `SFN_ARN`: ARN вашої Step Function (отриманий з output terraform).

## Перевірка та запуск

### Автоматичний запуск
Пайплайн запускається автоматично при кожному `push` у гілку `lesson-10`.

### Ручний запуск через AWS CLI
```bash
aws stepfunctions start-execution \
    --state-machine-arn arn:aws:states:eu-central-1:123456789012:stateMachine:mlops-training-pipeline \
    --input '{"source":"manual_test"}'
```

### Приклад вхідного JSON-об'єкта
```json
{
  "source": "gitlab-ci",
  "commit": "a1b2c3d"
}
```

## Архітектура пайплайну
Пайплайн складається з двох послідовних кроків:
1. ValidateData: Викликає Lambda-функцію для перевірки вхідних даних.
2. LogMetrics: Отримує результат валідації та фіксує завершення процесу в логах.