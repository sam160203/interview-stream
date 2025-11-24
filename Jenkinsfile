pipeline {
    agent any

    environment {
        SONAR_PROJECT_KEY = 'interview-stream-app'
        SONAR_HOST_URL = 'http://192.168.20.250:9000/'

        NEXUS_REGISTRY_DOCKER = '192.168.20.250:8082'
        IMAGE_NAME = "interview-stream-app"

        K8S_DEPLOYMENT_NAME = 'interview-stream-deployment'
        K8S_DEPLOYMENT_YAML = 'k8s/deployment-and-secrets.yaml'
        K8S_SERVICE_YAML = 'k8s/service.yaml'
    }

    stages {
        
        stage('Checkout Code') {
            steps {
                git branch: 'master',
                    credentialsId: 'github-credentials-sam',
                    url: 'https://github.com/sam160203/interview-stream.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonarqube-token-imcc', variable: 'SONAR_TOKEN')]) {
                    sh """
                    docker run --rm \
                    -e SONAR_HOST_URL=${SONAR_HOST_URL} \
                    -e SONAR_LOGIN=${SONAR_TOKEN} \
                    -e SONAR_PROJECT_KEY=${SONAR_PROJECT_KEY} \
                    -v \$(pwd):/usr/src \
                    sonarsource/sonar-scanner-cli
                    """
                }
            }
        }

        stage('Quality Gate Check') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def gitCommit = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    env.IMAGE_TAG = gitCommit
                    sh "docker build -t ${IMAGE_NAME}:${env.IMAGE_TAG} ."
                }
            }
        }

        stage('Push to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-credentials-imcc',
                                                 usernameVariable: 'NEXUS_USER',
                                                 passwordVariable: 'NEXUS_PASS')]) {
                    sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${NEXUS_REGISTRY_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker login -u ${NEXUS_USER} -p ${NEXUS_PASS} ${NEXUS_REGISTRY_DOCKER}"
                    sh "docker push ${NEXUS_REGISTRY_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withKubeConfig(credentialsId: 'kubernetes-credentials') {

                    sh "sed -i 's|PLACEHOLDER_IMAGE_TAG|${NEXUS_REGISTRY_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG}|g' ${K8S_DEPLOYMENT_YAML}"

                    sh "kubectl apply -f ${K8S_DEPLOYMENT_YAML}"
                    sh "kubectl apply -f ${K8S_SERVICE_YAML}"

                    sh "kubectl rollout status deployment/${K8S_DEPLOYMENT_NAME}"
                }
            }
        }
    }
}
