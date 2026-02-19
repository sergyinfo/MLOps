# AWS Infrastructure: VPC & EKS Cluster for ML Services

Цей проєкт містить конфігурацію Terraform для автоматизованого розгортання базової інфраструктури під майбутні ML-сервіси в AWS.

Проєкт побудований за модульною архітектурою з використанням офіційних модулів від AWS:
* `terraform-aws-modules/vpc/aws` — для створення ізольованої мережі.
* `terraform-aws-modules/eks/aws` — для розгортання керованого Kubernetes-кластера з двома групами вузлів (Node Groups).

## Структура проєкту

Інфраструктура розділена на логічні модулі:

```text
eks-vpc-cluster/
├── main.tf             # Головний файл, який викликає модулі VPC та EKS
├── variables.tf        # Глобальні змінні (регіон, назва кластера тощо)
├── outputs.tf          # Глобальні виходи (ID мережі, endpoint кластера)
├── terraform.tf        # Налаштування провайдера AWS та версії Terraform
├── vpc/                # Модуль мережі (Public/Private Subnets, NAT Gateway)
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tf
│   └── backend.tf      
└── eks/                # Модуль кластера (Control Plane, Node Groups, IAM Roles)
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tf
└── backend.tf      
```

## Попередні вимоги (Prerequisites)
Перед початком роботи переконайтеся, що у вас встановлені:
1. [Terraform](https://developer.hashicorp.com/terraform/downloads) (>= 1.3.0)
2. [AWS CLI](https://aws.amazon.com/cli/)
3. [kubectl](https://kubernetes.io/docs/tasks/tools/)
4. Налаштований AWS-профіль із необхідними правами доступу.

## Інструкція з розгортання (Deployment)

**Крок 1.** Задайте правильний AWS-профіль для вашого термінала:
```bash
export AWS_PROFILE=sergyinfo
```

**Крок 2.** Ініціалізуйте робочу директорію Terraform (завантаження модулів та провайдерів):
```bash
terraform init
```

**Крок 3.** Перегляньте план створення ресурсів:
```bash
terraform plan
```

**Крок 4.** Запустіть розгортання інфраструктури (процес створення EKS може зайняти ~15 хвилин):
```bash
terraform apply
```
*Введіть `yes`, коли Terraform попросить підтвердження.*

## Підключення до кластера

Після успішного розгортання оновіть конфігурацію `kubectl`, щоб отримати доступ до вашого нового кластера:

```bash
aws eks --region eu-west-3 update-kubeconfig --name ml-eks-cluster --profile sergyinfo
```

Перевірте статус вузлів та їхні мітки (labels), щоб переконатися, що група `ml-worker` створена успішно:
```bash
kubectl get nodes -L role
```

## Видалення інфраструктури (Clean Up)

**КРИТИЧНО ВАЖЛИВО:** Ресурси AWS (EKS Control Plane, EC2 інстанси, NAT Gateway та Load Balancers) тарифікуються погодинно. Після завершення роботи з кластером **обов'язково** видаліть інфраструктуру, щоб уникнути зайвих витрат:

```bash
terraform destroy
```
*Введіть `yes` для підтвердження видалення (процес займає ~10 хвилин).*