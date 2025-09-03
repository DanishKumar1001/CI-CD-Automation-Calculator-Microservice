# 🧮 Calculator Microservice

A containerized **Node.js + Express** microservice with **MongoDB Atlas** integration.  
It provides simple arithmetic and CRUD APIs, containerization with **Docker**, orchestration with **Kubernetes (GKE)**, and  DevOps pipelines with **GitHub Actions**, **Jenkins**, **SonarQube**, **Selenium**, **Stackdriver Monitoring/Logging**, and **Datadog**.

---

## 🚀 Features

- REST API with arithmetic operations:  
  `/add`, `/subtract`, `/multiply`, `/divide`, `/power`, `/modulo`, `/sqrt`, `/percentage`
- CRUD API for calculation history:  
  `/operations`, `/operations/:id`
- MongoDB integration (Atlas or in-cluster)
- Containerization with Docker
- Ochestration with Kubernetes (Local and GKE - GCP)
- Logging with Winston (stdout → Stackdriver/Datadog)
- Health endpoint `/health` for probes & uptime checks
- CI/CD with GitHub Actions and Jenkins
- Quality analysis (SonarQube) & E2E testing (Selenium)
- Observability with **Google Cloud Operations (Stackdriver)** and **Datadog**

---

## 📂 Project Structure

├── calculator.js # Node.js service
├── Dockerfile # Container image
├── docker-compose.yml # Local dev
├── deployment.yaml # Calculator Deployment (K8s)
├── service.yaml # Calculator Service (K8s)
├── mongo-pvc.yaml # PVC for MongoDB
├── mongodb-deployment.yaml # MongoDB Deployment
├── mongo-service.yaml # MongoDB Service
├── mongo-secret.yaml # Kubernetes Secret (credentials/URI)
├── .env.example # Example environment file
├── .gitignore # Ignore sensitive/local files
├── sonar-project.properties # SonarQube config
├── tests/ # Smoke + Selenium tests
├── .github/workflows/ # GitHub Actions CI/CD
└── Jenkinsfile # Jenkins pipeline

## ⚙️ Local Development

### 1. Clone & install

git clone https://github.com/DanishKumar1001/CI-CD-Automation-Calculator-Microservice.git
cd CI-CD-Automation-Calculator-Microservice
npm install

### 2. Configure environment

**Set values in .env:**

MONGO_USERNAME=admin
MONGO_PASSWORD=changeme123
MONGO_URI=mongodb://admin:changeme123@mongo:27017/
NODE_ENV=development
PORT=3000

### 3. Run with Docker Compose

docker-compose up --build

## ☸️ Kubernetes on GKE

### 1. Build & push image

docker build -t calculator:v1 .
docker tag calculator:v1 REGION-docker.pkg.dev/PROJECT_ID/REPO_NAME/calculator:v1
docker push REGION-docker.pkg.dev/PROJECT_ID/REPO_NAME/calculator:v1

### 2. Create namespace & secrets

kubectl create ns calculator
kubectl -n calculator apply -f mongo-secret.yaml

### 3. Apply manifests

kubectl -n calculator apply -f mongo-pvc.yaml
kubectl -n calculator apply -f mongodb-deployment.yaml
kubectl -n calculator apply -f mongo-service.yaml
kubectl -n calculator apply -f deployment.yaml
kubectl -n calculator apply -f service.yaml

### 4. Get external IP

kubectl -n calculator get svc calculator-microservice -w

## Test:

curl http://<EXTERNAL_IP>/health
curl "http://<EXTERNAL_IP>/add?num1=10&num2=5"

## 🔄 CI/CD Pipelines

### GitHub Actions

**CI (ci.yml)**

Installs deps, runs tests
Optional SonarQube scan

**CD (cd.yml)**

Builds & pushes image to Artifact Registry
Deploys to GKE (rolling update)

### Jenkins

**Jenkinsfile stages:**

Checkout → Node.js build
SonarQube static analysis & Quality Gate
Integration env via Docker Compose
API smoke + Selenium E2E tests
Build & push image to Artifact Registry
Deploy to GKE via kubectl
Post-deploy smoke test
Datadog deployment event (+ optional Helm install of Datadog Agent)

## 🧪 Tests

**Smoke tests**

tests/api.smoke.sh checks /health + arithmetic API.

**Selenium E2E**

tests/health.selenium.test.js opens /health in headless Chrome via Selenium Grid.

**Run locally:**

docker-compose -f docker-compose.ci.yml up --build -d
tests/api.smoke.sh
node tests/health.selenium.test.js

## 📊 Monitoring & Observability

### Google Cloud Operations (Stackdriver)

**Logging:** All stdout/stderr → Logs Explorer (resource.type="k8s_container")
**Monitoring:** GKE dashboards (CPU, memory, restarts)
**Uptime checks**: Configure /health with alert policy

### Datadog

**Agent:** Install via Helm → collects logs, metrics, traces
**Deployment events:** Reported via Jenkins (datadog-ci report-deployment)
**APM:** Enable dd-trace in calculator.js

## 🔐 Security Notes

1. Never commit .env
2. **Use Kubernetes Secrets** for MONGO_URI, MONGO_USERNAME, MONGO_PASSWORD
3. URL-encode special characters in MongoDB URIs:
! → %21
@ → %40
# → %23

## 📦 References

Docker
Kubernetes
GKE
Artifact Registry
GitHub Actions
Jenkins
SonarQube
Selenium
Datadog
Cloud Operations (Stackdriver)