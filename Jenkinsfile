pipeline {
  agent any

  options {
    timeout(time: 40, unit: 'MINUTES')
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '10'))
    timestamps()
  }

  environment {
    IMAGE          = 'ashish256/rest-api'
    APP_HOST       = '10.0.1.68'
    SONAR_HOST_URL = 'http://localhost:9000'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        script {
          def sha = sh(returnStdout: true, script: 'git rev-parse --short=7 HEAD').trim()
          env.TAG = "${env.BUILD_NUMBER}-${sha}"
        }
        echo "Image tag will be ${env.TAG}"
      }
    }

    stage('Validate') {
      steps {
        sh 'test -f Dockerfile && test -f package-lock.json && test -f deploy/deploy.sh && test -f deploy/docker-compose.prod.yml'
      }
    }

    stage('Install and Unit Tests') {
      steps {
        sh '''
          mkdir -p test-results
          docker run --rm -u "$(id -u):$(id -g)" -e HOME=/tmp -v "$WORKSPACE":/app -w /app node:22-alpine \
            sh -c "npm ci && npx vitest run --reporter=default --reporter=junit --outputFile.junit=test-results/junit.xml"
        '''
      }
      post {
        always {
          junit allowEmptyResults: true, testResults: 'test-results/junit.xml'
        }
      }
    }

    stage('Code Quality (SonarQube)') {
      steps {
        withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
          sh '''
            docker run --rm --network host -u "$(id -u):$(id -g)" \
              -e SONAR_HOST_URL="$SONAR_HOST_URL" -e SONAR_TOKEN="$SONAR_TOKEN" -e SONAR_USER_HOME=/tmp/.sonar \
              -v "$WORKSPACE":/usr/src sonarsource/sonar-scanner-cli:latest \
              -Dsonar.projectKey=rest-api -Dsonar.sources=src -Dsonar.tests=tests \
              -Dsonar.exclusions=node_modules/** -Dsonar.qualitygate.wait=true
          '''
        }
      }
    }

    stage('Dependency Scan') {
      steps {
        sh '''
          docker run --rm -u "$(id -u):$(id -g)" -e HOME=/tmp -v "$WORKSPACE":/app -w /app node:22-alpine \
            sh -c "npm audit --omit=dev --audit-level=critical"
        '''
      }
    }

    stage('Docker Build') {
      steps {
        sh 'docker build -t "$IMAGE:$TAG" .'
      }
    }

    stage('Image Scan (Trivy)') {
      steps {
        sh '''
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v trivy-cache:/root/.cache/ \
            aquasec/trivy:latest image --no-progress --severity HIGH,CRITICAL --ignore-unfixed --exit-code 0 "$IMAGE:$TAG"
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v trivy-cache:/root/.cache/ \
            aquasec/trivy:latest image --no-progress --severity CRITICAL --ignore-unfixed --exit-code 1 "$IMAGE:$TAG"
        '''
      }
    }

    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
          sh '''
            echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
            docker push "$IMAGE:$TAG"
            docker logout
          '''
        }
      }
    }

    stage('Deployment Approval') {
      steps {
        timeout(time: 15, unit: 'MINUTES') {
          input message: "Deploy ${env.TAG} to the app server?", ok: 'Deploy'
        }
      }
    }

    stage('Deploy') {
      steps {
        sshagent(credentials: ['app-ssh-key']) {
          sh '''
            OPTS="-o StrictHostKeyChecking=accept-new"
            scp $OPTS deploy/docker-compose.prod.yml ubuntu@$APP_HOST:/opt/rest-api/docker-compose.yml
            scp $OPTS deploy/deploy.sh ubuntu@$APP_HOST:/opt/rest-api/deploy.sh
            ssh $OPTS ubuntu@$APP_HOST "chmod +x /opt/rest-api/deploy.sh && /opt/rest-api/deploy.sh $TAG"
          '''
        }
      }
    }

    stage('Health Check and Smoke Tests') {
      steps {
        sh '''
          for i in $(seq 1 15); do curl -fsS "http://$APP_HOST/health" && break; sleep 2; done
          curl -fsS "http://$APP_HOST/health" | grep -q '"status":"ok"'
          code=$(curl -s -o /dev/null -w '%{http_code}' "http://$APP_HOST/api/items")
          [ "$code" = "401" ]
          echo "Smoke tests passed"
        '''
      }
    }
  }

  post {
    success { echo "SUCCESS: ${env.IMAGE}:${env.TAG} is deployed and healthy" }
    failure { echo "FAILED: check the red stage. deploy.sh rolls back automatically if the health check fails." }
    always {
      sh 'docker image prune -f || true'
      deleteDir()
    }
  }
}
