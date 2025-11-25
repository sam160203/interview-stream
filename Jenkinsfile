pipeline {
    agent any

    environment {
        SONAR_PROJECT_KEY = 'interview-stream-app'
        SONAR_HOST_URL = 'http://192.168.20.250:9000'

        NEXUS_REGISTRY = '192.168.20.250:8082'
        IMAGE_NAME = 'interview-stream-app'

        K8S_DEPLOYMENT_YAML = 'k8s/deployment-and-secrets.yaml'
        K8S_SERVICE_YAML = 'k8s/service.yaml'
        K8S_DEPLOYMENT_NAME = 'interview-stream-deployment'
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo "Pulling code from GitHub..."
                git branch: 'master',
                    credentialsId: 'github-credentials-sam',
                    url: 'https://github.com/sam160203/interview-stream.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {

                withCredentials([string(credentialsId: 'sonarqube-token-imcc', variable: 'SONAR_TOKEN')]) {
                    sh """
                        mvn clean verify sonar:sonar \
                        -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                        -Dsonar.host.url=${SONAR_HOST_URL} \
                        -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 3, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    env.IMAGE_TAG = sh(
                        returnStdout: true,
                        script: "git rev-parse --short HEAD"
                    ).trim()
                }

                sh """
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                """
            }
        }

        stage('Push to Nexus') {
            steps {

                withCredentials([
                    usernamePassword(credentialsId: 'nexus-credentials-imcc',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS')
                ]) {

                    sh """
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${NEXUS_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker login -u ${NEXUS_USER} -p ${NEXUS_PASS} ${NEXUS_REGISTRY}
                        docker push ${NEXUS_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withKubeConfig(credentialsId: 'kubernetes-credentials') {

                    sh """
                        sed -i 's|PLACEHOLDER_IMAGE_TAG|${NEXUS_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}|g' ${K8S_DEPLOYMENT_YAML}

                        kubectl apply -f ${K8S_DEPLOYMENT_YAML}
                        kubectl apply -f ${K8S_SERVICE_YAML}

                        kubectl rollout status deployment/${K8S_DEPLOYMENT_NAME}
                    """
                }
            }
        }
    }
}
