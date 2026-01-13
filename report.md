Вилучено зміст файлів із .ipynb і розкладено їх у директорії, відповідно до структури, описаної в README.md

# `.github/workflow/ci.yml`

Файл `ci.yml` описує CI-пайплайн для збірки контейнера.

## Відсутність контролю змін (PR-based gate)

**Опис**  
CI запускається на подію `push` без розділення на гілки та без обробки `pull_request`.

**Відсутній сигнал / перевірка**  
- Обов’язкова перевірка змін перед інтеграцією в основну гілку.
- Контроль якості та безпеки на етапі review.

**Порушений принцип / патерн**  
- Secure Change Management  
- Defense in Depth

**Архітектурне виправлення**  
- Додати тригер `pull_request` для основної гілки.
- Забезпечити політику merge protection з обов’язковим проходженням CI.

## Порушення Principle of Least Privilege для CI

**Опис**  
У workflow не визначено явні `permissions` для `GITHUB_TOKEN`.

**Відсутній сигнал / перевірка**  
- Контроль над правами автоматизованих агентів.
- Явна декларація мінімально необхідних дозволів.

**Порушений принцип / патерн**  
- Principle of Least Privilege (PoLP)

**Архітектурне виправлення**  
- Явно задати `permissions` (наприклад, `contents: read`).
- Заборонити невикористовувані scope за замовчуванням.

## Відсутність сигналів безпеки в CI (security blind spot)

**Опис порушення**  
Pipeline виконує лише збірку контейнера без будь-яких security-перевірок.

**Відсутній сигнал / перевірка**  
- Secret scanning  
- IaC security scanning  
- Container vulnerability scanning  
- Dockerfile linting

**Порушений принцип / патерн**  
- "Невидимість" (lack of observability)  
- Shift Left Security

**Архітектурне виправлення**  
- Додати автоматизовані security checks (наприклад, secrets, IaC, image scan).
- Заблокувати merge при виявленні критичних проблем.

## Невідтворюване середовище виконання CI

**Опис порушення**  
Використовується `ubuntu-latest` без фіксації версії runner.

**Відсутній сигнал / перевірка**  
- Контроль стабільності та передбачуваності середовища.
- Детекція змін у базовому execution environment.

**Порушений принцип / патерн**  
- Reproducible Builds  
- Controlled Environment

**Архітектурне виправлення**  
- Зафіксувати конкретну версію runner (наприклад, `ubuntu-22.04`).
- Оновлювати runner як окрему зміну.

## Неконтрольований build context для контейнера

**Опис порушення**  
Контейнер збирається з кореня репозиторію (`docker build .`).

**Відсутній сигнал / перевірка**  
- Контроль вмісту build context.
- Запобігання випадковому включенню конфіденційних файлів.

**Порушений принцип / патерн**  
- Least Exposure  
- Secure Build Pipeline

**Архітектурне виправлення**  
- Обмежити build context до каталогу сервісу (`app/`).
- Явно вказувати Dockerfile та контекст.

# `app/main.py`

Файл реалізує HTTP endpoints FastAPI (`/user`, `/login`).

## Відсутність контракту API (schema-first / validation)

**Опис**  
`/user` приймає `id` без типу та валідації; відсутній `response_model`.

**Відсутній сигнал / перевірка**  
- Автоматична валідація параметрів запиту (типи/межі/формати)
- Контрактні тести API (OpenAPI contract tests)
- Лінтинг/перевірка типів (mypy, ruff)

**Порушений принцип / патерн**  
- Secure-by-default (відсутність дефолтних гарантій)
- Schema / Contract-First
- Fail-safe defaults

**Архітектурне виправлення**  
- Ввести Pydantic-моделі для запитів/відповідей (`BaseModel`)
- Типізувати параметри (`id: int`)
- Додати `response_model` для формалізації контракту

## Хардкод секрету (credential in code)

**Опис**  
Пароль `"secret"` жорстко зашитий в коді.

**Відсутній сигнал / перевірка**  
- Secret scanning у CI (gitleaks/trufflehog)
- Політика управління секретами (Secrets Manager / Vault / K8s secrets + rotation)
- Code review rule: “no secrets in code”

**Порушений принцип / патерн**  
- Secret Management
- Separation of Configuration and Code
- Defense in Depth

**Архітектурне виправлення**  
- Винести секрет/ключі в кероване сховище секретів
- Використовувати хеші пар

## Відсутність безпечної автентифікації (authentication design flaw)

**Опис порушення**  
`/login` повертає `"ok"`/`"fail"` без сесії/токена, без rate limiting, без lockout, без журналювання, без MFA/політики паролів.

**Відсутній сигнал / перевірка**  
- Security requirements для auth (threat modeling / misuse cases)
- DAST/тести на brute force
- Моніторинг auth-аномалій (failed logins, IP reputation)

**Порушений принцип / патерн**  
- Secure Authentication Pattern 
- Abuse-resistance
- Least Effort Attack Surface 

**Архітектурне виправлення**  
- Впровадити стандартний механізм: OAuth2 Password Flow або зовнішній IdP
- Видавати короткоживучий access token (JWT/opaque) + refresh, або серверні сесії
- Додати rate limiting і політику блокування/затримок при невдалих спробах

## Відсутність аудит-сигналів (security observability gap)

**Опис**  
Немає журналювання спроб логіну, correlation-id, метрик, сигналів для детекції атак.

**Відсутній сигнал / перевірка**  
- Security logging (успішні/невдалі логіни)
- Метрики та алерти (rate of failures, spikes)
- Traceability (request id)

**Порушений принцип / патерн**  
- Observability / “видимість”
- Detection and Response readiness

**Архітектурне виправлення**  
- Додати структуроване логування подій auth (без секретів)
- Додати middleware для request-id і кореляції
- Інтегрувати метрики та алерти

`app/Dockerfile`

Dockerfile збирає контейнер для FastAPI сервісу.

## Непіновані залежності 

**Опис порушення**  
`pip install fastapi uvicorn` без фіксації версій та без lock-файлу.

**Відсутній сигнал / перевірка**  
- Dependency policy/lock enforcement (requirements.txt + hash-checking)
- SCA (Software Composition Analysis) у CI (вразливості Python залежностей)
- Перевірка відтворюваності build (rebuild parity)

**Порушений принцип / патерн**  
- Reproducible Builds  
- Supply Chain Security

**Архітектурне виправлення**  
- Додати `requirements.txt` (або `poetry.lock`) з пінуванням версій.
- У CI: SCA (Trivy/Safety/pip-audit) як блокуючий сигнал.

## Відсутність практик зменшення привілеїв у контейнері (PoLP)

**Опис**  
Контейнер запускається від root (за замовчуванням), без створення непривілейованого користувача.

**Відсутній сигнал / перевірка**  
- Policy check “runAsNonRoot” (kube policy / Dockerfile lint)
- Container hardening checks (CIS Docker recommendations) у CI

**Порушений принцип / патерн**  
- Principle of Least Privilege (PoLP)  

**Архітектурне виправлення**  
- Створити користувача і запускати процес під ним (`USER appuser`).
- У Kubernetes: вимагати `runAsNonRoot: true`, `allowPrivilegeEscalation: false`.

## Роздутий та неконтрольований build context (ризик витоку артефактів/секретів)

**Опис**  
`COPY app /app` копіює всю директорію `app`. Без `.dockerignore` є ризик включити зайве (тести, ключі, локальні конфіги), збільшити поверхню атаки та розмір образу.

**Відсутній сигнал / перевірка**  
- Перевірка `.dockerignore` (політика build hygiene)
- Сканування образу на секрети (Trivy filesystem/image scan)

**Порушений принцип / патерн**  
- Least Exposure  
- Secure Build Hygiene

**Архітектурне виправлення**  
- Додати `.dockerignore` з виключенням секретів/артефактів.
- Копіювати лише необхідні файли (наприклад, `COPY app/main.py ...` або структуру проекту з явним переліком).

## Відсутність multi-stage build та базового hardening

**Опис**  
Один етап збірки на повному образі `python:3.10` без оптимізації та hardening.

**Відсутній сигнал / перевірка**  
- Policy для зменшення базового образу (slim/distroless)
- Container scanning gate (CRITICAL/HIGH) для базового образу

**Порушений принцип / патерн**  
- Attack Surface Minimization  
- Defense in Depth

**Архітектурне виправлення**  
- Перейти на `python:3.10-slim` (мінімум) або distroless (за потреби).
- Додати сканування образу в CI як блокуючий сигнал.

# `terraform/main.tf`

Terraform-код створює AWS Security Group для сервісу `user-api`.

## Відкрите правило доступу (`0.0.0.0/0`) без обмежень

**Опис порушення**  
Ingress-правило дозволяє доступ на порт 443 з будь-якої IP-адреси.

**Відсутній сигнал / перевірка**  
- IaC security scanning (tfsec / Checkov) з блокуючими правилами
- Policy-as-Code для мережевих меж (network boundaries)

**Порушений принцип / патерн**  
- Principle of Least Privilege (PoLP)  
- Network Segmentation  
- Zero Trust (implicit trust порушено)

**Архітектурне виправлення**  
- Обмежити джерела трафіку (CIDR, SG-to-SG)
- Параметризувати дозволені CIDR або source security groups
- Заборонити `0.0.0.0/0` на рівні політик

## Хардкод регіону AWS

**Опис порушення**  
AWS region жорстко заданий у provider.

**Відсутній сигнал / перевірка**  
- Environment-specific configuration validation
- Захист від випадкового деплою в неправильне середовище

**Порушений принцип / патерн**  
- Separation of Configuration and Code  
- Explicit Configuration

**Архітектурне виправлення**  
- Винести регіон у змінну без небезпечного дефолту
- Визначати регіон через tfvars / environment

## Відсутність параметризації мережевих правил

**Опис порушення**  
Порт, протокол і правила доступу жорстко зашиті в ресурсі.

**Відсутній сигнал / перевірка**  
- Контроль конфігурацій між середовищами (dev/stage/prod)
- Policy перевірки відповідності мережевої моделі

**Порушений принцип / патерн**  
- Configuration as Data  
- Reusable Secure Modules

**Архітектурне виправлення**  
- Винести порти, CIDR, опис у змінні
- Інкапсулювати SG у Terraform module

## Відсутність egress-обмежень (implicit allow)

**Опис порушення**  
Egress-правила не визначені, отже застосовується default allow-all.

**Відсутній сигнал / перевірка**  
- Контроль вихідного трафіку
- Виявлення data exfiltration paths

**Порушений принцип / патерн**  
- Principle of Least Privilege (PoLP)  
- Egress Control

**Архітектурне виправлення**  
- Явно визначити egress-правила
- Обмежити egress до необхідних сервісів/портів

## Відсутність тегування та ідентифікації ресурсу

**Опис порушення**  
Security Group не має тегів.

**Відсутній сигнал / перевірка**  
- Inventory / asset management
- Policy enforcement по тегах (cost, owner, env, data classification)

**Порушений принцип / патерн**  
- Asset Traceability  
- Governance by Design

**Архітектурне виправлення**  
- Додати обов’язкові теги (env, owner, app, managed-by)
- Забезпечити policy: “no untagged resources”

# `charts/user-api/templates/deployment.yaml`

Файл описує Kubernetes `Deployment` для сервісу `user-api`. Розміщення у `charts/` передбачає Helm-шаблонізацію та керованість конфігурацій між середовищами.

## Використання `image:latest` (невідтворюваний деплой, supply chain ризик)

**Відсутній сигнал / перевірка**
- Policy enforcement: заборона `:latest` (OPA Gatekeeper / Kyverno)
- Контроль артефактів: відповідність image tag/digest до CI build
- Container image scanning gate (CRITICAL/HIGH)

**Порушений принцип / патерн**
- Reproducible Deployments
- Supply Chain Integrity

**Архітектурне виправлення**
- Використовувати immutable tag (commit SHA або semver) або image digest `@sha256:...`
- Додати admission policy: “deny latest”

## Відсутність шаблонізації/параметризації 

**Відсутній сигнал / перевірка**
- Helm lint + schema validation values (values schema)
- Контроль конфіг-дрейфу між env (dev/stage/prod)

**Порушений принцип / патерн**
- Separation of Configuration and Code
- Configuration as Data

**Архітектурне виправлення**
- Перетворити значення на Helm-параметри (`.Values`): replicas, image, ports, resources, secret name
- Додати `values.yaml` і (бажано) `values.schema.json` для валідації типів/обов’язкових полів
- Запровадити environment-specific values (dev/prod overlays)

## Відсутність readinessProbe (часткова “невидимість” та неконтрольований rollout)

**Відсутній сигнал / перевірка**
- Перевірка наявності readinessProbe (kube-linter / policy)
- Smoke tests після деплою (мінімальна перевірка доступності)

**Порушений принцип / патерн**
- Observability / “видимість”
- Safe rollout patterns

**Архітектурне виправлення**
- Додати `readinessProbe` (окремо від liveness) з узгодженими шляхом/портом
- За потреби: додати `startupProbe` для повільного старту
- Стандартизувати `/health` 

## Відсутність securityContext (PoLP порушено на рівні Pod/Container)

**Відсутній сигнал / перевірка**
- Pod Security Admission / Pod Security Standards enforcement
- Policy checks: `runAsNonRoot`, `allowPrivilegeEscalation=false`, `capabilities.drop=ALL`

**Порушений принцип / патерн**
- Principle of Least Privilege (PoLP)
- Defense in Depth

**Архітектурне виправлення**
- Додати container/pod `securityContext`:
  - `runAsNonRoot: true`
  - `allowPrivilegeEscalation: false`
  - `readOnlyRootFilesystem: true` (якщо сумісно)
  - `seccompProfile: RuntimeDefault`
  - `capabilities.drop: ["ALL"]`
- Узгодити з Dockerfile (запуск під non-root)

---

## Невизначені `resources.requests` (ризик деградації та DoS-сценарії)

**Відсутній сигнал / перевірка**
- Policy enforcement: вимога `requests` і `limits` (kube-linter / Kyverno)
- SLO/ресурсні алерти (CPU throttling, OOMKills)

**Порушений принцип / патерн**
- Reliability as a security prerequisite
- Resource Governance

**Архітектурне виправлення**
- Додати `resources.requests` (CPU/memory) і параметризувати через Helm values

## `envFrom.secretRef` без мінімізації поверхні секретів (надлишкове надання доступу)

**Відсутній сигнал / перевірка**
- Policy: заборона “широкого” `envFrom` або вимога явного переліку змінних
- Аудит доступу до секретів (RBAC + логування)

**Порушений принцип / патерн**
- Principle of Least Privilege (PoLP)
- Secret Scope Minimization

**Архітектурне виправлення**
- Замінити `envFrom` на `env` з точковим переліком ключів, які реально потрібні
- Обмежити ServiceAccount та RBAC доступ до конкретних секретів