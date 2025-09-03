pipeline {
  agent any

  environment {
    // ---- Artifact Registry ----
    PROJECT_ID    = credentials('gcp-project-id')      //  set as a plain env in Jenkins
    REGION        = 'australia-southeast1'
    CLUSTER_NAME  = 'calc-cluster'
    REPO_NAME     = 'calc-repo'
    IMAGE_NAME    = 'calculator'
    K8S_NAMESPACE = 'calculator'
    IMAGE_URI     = "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}"

    // ---- Datadog ----
    DATADOG_SITE  = 'datadoghq.com' // or 'datadoghq.eu' etc.
  }

  options {
    timestamps()
    ansiColor('xterm')
    timeout(time: 40, unit: 'MINUTES')
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Node CI') {
      steps {
        sh '''
          node -v || true
          npm ci
        '''
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('SonarServer') {
          sh '''
            if ! command -v sonar-scanner >/dev/null 2>&1; then
              npm i -g sonar-scanner
            fi
            sonar-scanner \
              -Dsonar.projectKey=calculator \
              -Dsonar.projectName="calculator" \
              -Dsonar.sources=. \
              -Dsonar.exclusions=**/node_modules/**,**/logs/**,**/tests/** \
              -Dsonar.tests=tests \
              -Dsonar.test.inclusions=tests/**/*.js \
              -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info || true
          '''
        }
      }
    }

    stage('Quality Gate') {
      when { expression { return env.CHANGE_ID == null } } // skip on PRs
      steps {
        script {
          timeout(time: 10, unit: 'MINUTES') {
            waitForQualityGate abortPipeline: true
          }
        }
      }
    }

    stage('Build Docker image') {
      steps {
        sh 'docker build -t ${IMAGE_NAME}:ci-${BUILD_NUMBER} .'
      }
    }

    stage('Integration env (docker-compose)') {
      steps {
        sh '''
          docker compose -f docker-compose.ci.yml down -v || true
          docker compose -f docker-compose.ci.yml up -d --build
          # Wait for health
          for i in $(seq 1 60); do
            curl -fsS http://localhost:3000/health && break || sleep 2
          done
        '''
      }
    }

    stage('API smoke + Selenium E2E') {
      steps {
        sh '''
          tests/api.smoke.sh
          node tests/health.selenium.test.js
        '''
      }
      post {
        always {
          sh 'docker compose -f docker-compose.ci.yml logs --no-color > compose-ci-logs.txt || true'
          archiveArtifacts artifacts: 'compose-ci-logs.txt', fingerprint: true
          sh 'docker compose -f docker-compose.ci.yml down -v || true'
        }
      }
    }

    stage('Auth to GCP & Push image') {
      environment {
        GCP_SA_JSON = credentials('gcp-sa-json') // Service Account JSON key
      }
      steps {
        sh '''
          echo "$GCP_SA_JSON" > sa.json
          gcloud auth activate-service-account --key-file=sa.json
          gcloud config set project ${PROJECT_ID}
          gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet

          docker tag ${IMAGE_NAME}:ci-${BUILD_NUMBER} ${IMAGE_URI}:${GIT_COMMIT}
          docker push ${IMAGE_URI}:${GIT_COMMIT}
          docker tag ${IMAGE_URI}:${GIT_COMMIT} ${IMAGE_URI}:latest
          docker push ${IMAGE_URI}:latest
        '''
      }
    }

    stage('Get GKE kubeconfig') {
      steps {
        sh '''
          gcloud container clusters get-credentials ${CLUSTER_NAME} --region ${REGION} --project ${PROJECT_ID}
          kubectl get ns ${K8S_NAMESPACE} || kubectl create ns ${K8S_NAMESPACE}
        '''
      }
    }

    stage('Deploy to GKE') {
      steps {
        sh '''
          # Apply manifests
          kubectl -n ${K8S_NAMESPACE} apply -f deployment.yaml
          kubectl -n ${K8S_NAMESPACE} apply -f service.yaml

          # Update image and rollout
          kubectl -n ${K8S_NAMESPACE} set image deployment/calculator-microservice \
            calculator-microservice=${IMAGE_URI}:${GIT_COMMIT}
          kubectl -n ${K8S_NAMESPACE} rollout status deployment/calculator-microservice --timeout=180s
        '''
      }
    }

    stage('Post-deploy smoke test') {
      steps {
        sh '''
          SVC_IP=$(kubectl -n ${K8S_NAMESPACE} get svc calculator-microservice -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
          for i in $(seq 1 60); do
            echo "Attempt $i: curl http://$SVC_IP/health"
            curl -fsS "http://$SVC_IP/health" && break || sleep 2
          done
        '''
      }
    }

    stage('Datadog: deployment event') {
      environment {
        DATADOG_API_KEY = credentials('datadog-api-key')
      }
      steps {
        sh '''
          npx -y @datadog/datadog-ci@latest report-deployment \
            --service ${IMAGE_NAME} \
            --env production \
            --version ${GIT_COMMIT} \
            --repository ${IMAGE_URI} \
            --datadog-site ${DATADOG_SITE} \
            --apiKey ${DATADOG_API_KEY} || true
        '''
      }
    }

    stage('Datadog Agent (optional Helm install/update)') {
      when { expression { return false } } // change to true to (re)install
      environment {
        DATADOG_API_KEY = credentials('datadog-api-key')
      }
      steps {
        sh '''
          helm repo add datadog https://helm.datadoghq.com
          helm repo update
          helm upgrade --install datadog datadog/datadog \
            --namespace datadog --create-namespace \
            --set datadog.apiKey=${DATADOG_API_KEY} \
            --set datadog.site=${DATADOG_SITE} \
            --set kubeStateMetricsCore.enabled=true \
            --set clusterAgent.enabled=true \
            --set datadog.logs.enabled=true \
            --set datadog.apm.enabled=true \
            --set datadog.processAgent.enabled=true
        '''
      }
    }
  }

  post {
    always {
      junit testResults: 'reports/**/*.xml', allowEmptyResults: true
      archiveArtifacts artifacts: 'tests/**/*.log', allowEmptyArchive: true
      cleanWs()
    }
  }
}
