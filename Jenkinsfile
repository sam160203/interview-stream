pipeline {
    // FIX 1: Agent ko hamesha 'any' rakhte hain, aur Docker commands 'container('dind')' ke andar chalaate hain
    agent any 
    
    // Environment Variables: Saare URLs aur Credentials yahan define honge
    environment {
        // SonarQube Details (FIX 2: IP aur Port hardcode kiye gaye hain)
        SONAR_PROJECT_KEY = 'interview-stream-app'
        SONAR_HOST_URL = 'http://192.168.20.250:9000/' 
        
        // Nexus Details
        NEXUS_REGISTRY_DOCKER = '192.168.20.250:8082' // FIX: Hardcoded IP aur Port
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
                // FIX 3: Sahi GitHub Credential ID ka use
                git branch: 'master', 
                    credentialsId: 'github-credentials-sam', 
                    url: 'https://github.com/sam160203/interview-stream.git'
            }
        }
        
        // Stage 2: SonarQube Analysis
        stage('SonarQube Analysis') {
            steps {
                echo 'Running static code analysis via Dockerized SonarQube Scanner...'
                
                // 1. Token ko Jenkins Credentials Manager se nikaalna
                withCredentials([string(credentialsId: 'sonarqube-token-imcc', variable: 'SONAR_TOKEN')]) {
                    
                    // FIX 4: Execution ko 'sonar-scanner' container mein wrap karna (jahan dind service available hai)
                    container('dind') { // Dind container mein hi Sonar Scanner chalate hain
                        sh """
                        docker run --rm \
                        -e SONAR_PROJECTKEY=${SONAR_PROJECT_KEY} \
                        -e SONAR_SOURCES=. \
                        -e SONAR_HOST_URL='${SONAR_HOST_URL}' \
                        -e SONAR_LOGIN='${SONAR_TOKEN}' \
                        -v \$(pwd):/usr/src \
                        sonarsource/sonar-scanner-cli
                        """
                    }
                }
            }
        }

        // Stage 3: Quality Gate Check
        stage('Quality Gate Check') {
            steps {
                echo 'Checking SonarQube Quality Gate status...'
                timeout(time: 5, unit: 'MINUTES') {
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
                    
                    // FIX 5: Docker build command ko 'dind' container ke andar wrap karna
                    container('dind') {
                        sh "docker build -t ${IMAGE_NAME}:${env.IMAGE_TAG} ."
                    }
                }
            }
        }

        // Stage 5: Push Image to Nexus
        stage('Push to Nexus') {
            steps {
                echo "Pushing image to Nexus registry..."
                
                // FIX 6: Image Tagging ko 'dind' ke andar chalaana
                container('dind') {
                     sh "docker tag ${IMAGE_NAME}:${env.IMAGE_TAG} ${NEXUS_REGISTRY_DOCKER}/${IMAGE_NAME}:${env.IMAGE_TAG}"
                }

                // Nexus credentials ka use karke login aur push karna
                withCredentials([usernamePassword(credentialsId: 'nexus-credentials-imcc', 
                                                 usernameVariable: 'NEXUS_USER', 
                                                 passwordVariable: 'NEXUS_PASS')]) {
                    
                    // FIX 7: Docker login aur push ko 'dind' container ke andar chalaana
                    container('dind') {
                        sh "docker login -u ${NEXUS_USER} -p ${NEXUS_PASS} ${NEXUS_REGISTRY_DOCKER}" 
                        sh "docker push ${NEXUS_REGISTRY_DOCKER}/${IMAGE_NAME}:${env.IMAGE_TAG}"
                    }
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
                    
                    // FIX 8: kubectl commands ko 'kubectl' container ke andar chalaana
                    container('kubectl') {
                        def gitCommit = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                        env.IMAGE_TAG = gitCommit
                        
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
}