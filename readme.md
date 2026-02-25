# ML-Infrastructure: GitOps with EKS, ArgoCD & MLflow

Цей проєкт демонструє сучасний підхід до управління інфраструктурою (IaC) та розгортання застосунків (GitOps). За допомогою Terraform автоматично створюється базова інфраструктура в AWS (VPC, EKS-кластер), після чого через Helm-провайдер розгортається ArgoCD. ArgoCD автоматично підхоплює конфігурацію з Git-репозиторію та розгортає MLflow у кластері.

##  Посилання на GitOps репозиторій
Файли конфігурації для ArgoCD (включно з `application.yaml`) знаходяться в окремому репозиторії:
 **https://github.com/sergyinfo/goit-argo**

---

## 📁 Структура проєкту (Terraform)

```text
eks-vpc-cluster/
├── main.tf             # Головний файл (виклик VPC, EKS та ArgoCD)
├── variables.tf        # Змінні (регіони, назви)
├── outputs.tf          # Виходи (VPC ID, Cluster Endpoint)
├── terraform.tf        # Налаштування провайдерів (AWS, Helm, Kubernetes)
├── vpc/                # Модуль мережі (Public/Private Subnets, NAT Gateway)
├── eks/                # Модуль EKS-кластера (Control Plane, Node Groups)
└── argocd/             # Модуль розгортання ArgoCD
    ├── main.tf         # Helm-реліз для ArgoCD
    └── values/
        └── argocd-values.yaml # Налаштування (ClusterIP, rbac, timeouts)
```

---

##  1. Розгортання інфраструктури (Terraform)

Перед початком переконайтеся, що у вас налаштовано AWS-профіль із необхідними правами доступу.

1. **Експортуйте ваш профіль AWS:**
   ```bash
   export AWS_PROFILE=sergyinfo
   ```

2. **Ініціалізуйте Terraform** (завантаження модулів та провайдерів):
   ```bash
   terraform init
   ```

3. **Перевірте план:**
   ```bash
   terraform plan
   ```

4. **Запустіть створення ресурсів:**
   ```bash
   terraform apply
   ```
   *Примітка: Створення повноцінної мережі, EKS-кластера та встановлення ArgoCD займає приблизно 15-20 хвилин.*

---

##  2. Перевірка ArgoCD та доступ до UI

Після успішного відпрацювання Terraform, ArgoCD буде автоматично розгорнуто у namespace `infra-tools`.

1. **Оновіть конфігурацію `kubectl` для підключення до кластера:**
   ```bash
   aws eks --region eu-west-3 update-kubeconfig --name ml-eks-cluster --profile sergyinfo
   ```

2. **Переконайтеся, що поди ArgoCD запущені та працюють:**
   ```bash
   kubectl get pods -n infra-tools
   ```

3. **Отримайте пароль адміністратора для входу в UI:**
   ```bash
   kubectl -n infra-tools get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
   ```

4. **Відкрийте доступ до вебінтерфейсу (Port-Forwarding):**
   ```bash
   kubectl port-forward svc/argocd-server -n infra-tools 8080:80
   ```
   Відкрийте браузер за адресою: **http://localhost:8080**
    * Логін: `admin`
    * Пароль: *(результат виконання команди з кроку 3)*

---

##  3. Перевірка деплою MLflow

ArgoCD автоматично зчитає маніфест `application.yaml` з підключеного Git-репозиторію та розгорне MLflow у namespace `application`.

1. **Перевірте статус створення подів MLflow:**
   ```bash
   kubectl get pods -n application
   ```
   *Дочекайтеся статусу `Running`.*

2. **Отримайте доступ до інтерфейсу MLflow:**
   Коли поди запущені, прокиньте порт сервісу:
   ```bash
   kubectl port-forward svc/mlflow -n application 5000:5000
   ```
   Відкрийте браузер за адресою: **http://localhost:5000**, щоб побачити панель MLflow.

---

##  4. Видалення ресурсів (Clean Up)

⚠️ **КРИТИЧНО ВАЖЛИВО:** Щоб уникнути зайвих витрат за використання ресурсів AWS (EKS, NAT Gateway, EC2), після завершення роботи обов'язково видаліть інфраструктуру:

```bash
terraform destroy
```
*Введіть `yes` і дочекайтеся повного видалення всіх ресурсів.*