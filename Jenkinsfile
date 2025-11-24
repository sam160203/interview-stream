pipeline {
    agent any 
    
    // Environment Variables: Saare URLs aur Credentials yahan define honge
    environment {
        // SonarQube Details (Aapke live URLs)
        SONAR_PROJECT_KEY = 'interview-stream-app'
        SONAR_HOST_URL = 'http://sonarqube.imcc.com/' 

        // Nexus Details
        NEXUS_REGISTRY_DOCKER = 'nexus.imcc.com:8082' // Nexus Docker Registry URL/Port
        IMAGE_NAME = "interview-stream-app"
        
        // Kubernetes Details
        K8S_DEPLOYMENT_NAME = 'interview-stream-deployment'
        K8S_DEPLOYMENT_YAML = 'k8s/deployment-and-secrets.yaml'
        K8S_SERVICE_YAML = 'k8s/service.yaml'
    }
    
    stages {
        // Stage 1: Code Pull Karna
        stage('Checkout Code') {
            steps {
                echo 'Checking out code from GitHub...'
                // FIX: Sahi GitHub Credential ID ka use
                git branch: 'master', 
                    credentialsId: 'github-credentials-sam', 
                    url: 'https://github.com/sam160203/interview-stream.git'
            }
        }
        
        // Stage 2: Code Quality Check (SonarQube)
        stage('SonarQube Analysis') {
            steps {
                echo 'Running static code analysis via SonarQube using Docker...'
                
                // 1. Token ko Jenkins Credentials Manager se nikaalna
                withCredentials([string(credentialsId: 'sonarqube-token-imcc', variable: 'SONAR_TOKEN')]) {
                    
                    // 2. SonarQube Scanner ko ek alag, SonarQube-specific Docker image mein chalaana
                    // Yeh sabse zaroori fix hai: hum sonar-scanner ka official image use karenge
                    sh """
                    docker run --rm \
                    -e SONAR_HOST_URL='${SONAR_HOST_URL}' \
                    -e SONAR_LOGIN='${SONAR_TOKEN}' \
                    -v \$(pwd):/usr/src \
                    sonarsource/sonar-scanner-cli
                    """
                }
            }
        }

        // Stage 3: Quality Gate Check
        stage('Quality Gate Check') {
            steps {
                echo 'Checking SonarQube Quality Gate status...'
                timeout(time: 5, unit: 'MINUTES') {
                    // Requires SonarQube Plugin (not scanner tool) to be installed
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        // Stage 4: Docker Image Build
        stage('Build Docker Image') {
            steps {
                echo 'Building Docker Image...'
                script {
                    def gitCommit = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    env.IMAGE_TAG = gitCommit
                    
                    // Docker build command
                    sh "docker build -t ${IMAGE_NAME}:${env.IMAGE_TAG} ."
                }
            }
        }

        // Stage 5: Push Image to Nexus
        stage('Push to Nexus') {
            steps {
                echo "Pushing image to Nexus registry..."
                
                // 1. Image ko Nexus URL se tag karna
                sh "docker tag ${IMAGE_NAME}:${env.IMAGE_TAG} ${NEXUS_REGISTRY_DOCKER}/${IMAGE_NAME}:${env.IMAGE_TAG}"

                // 2. Nexus credentials (nexus-credentials-imcc) ka use karna
                withCredentials([usernamePassword(credentialsId: 'nexus-credentials-imcc', 
                                                 usernameVariable: 'NEXUS_USER', 
                                                 passwordVariable: 'NEXUS_PASS')]) {
                    
                    // 3. Docker login and push
                    sh "docker login -u ${NEXUS_USER} -p ${NEXUS_PASS} ${NEXUS_REGISTRY_DOCKER}" 
                    sh "docker push ${NEXUS_REGISTRY_DOCKER}/${IMAGE_NAME}:${env.IMAGE_TAG}"
                }
                echo 'Image successfully pushed to Nexus.'
            }
        }

        // Stage 6: Deploy to Kubernetes
        stage('Deploy to Kubernetes') {
            steps {
                echo "Deploying image to Kubernetes cluster..."
                
                // Kubernetes credentials ka use karna
                withKubeConfig(credentialsId: 'kubernetes-credentials') { 
                    
                    // 1. Image Tag Replace karna
                    sh "sed -i 's|PLACEHOLDER_IMAGE_TAG|${NEXUS_REGISTRY_DOCKER}/${IMAGE_NAME}:${env.IMAGE_TAG}|g' ${K8S_DEPLOYMENT_YAML}"
                    
                    // 2. Deployment aur Secrets Apply Karna
                    sh "kubectl apply -f ${K8S_DEPLOYMENT_YAML}"
                    
                    // 3. Service Apply Karna
                    sh "kubectl apply -f ${K8S_SERVICE_YAML}"
                    
                    // 4. Deployment ki safalta ka intezaar karna
                    sh "kubectl rollout status deployment/${K8S_DEPLOYMENT_NAME}"
                }
            }
        }
    }
}