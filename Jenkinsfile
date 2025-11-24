pipeline {
    agent any 
    
    // Environment Variables: Saare URLs aur Credentials yahan define honge
    environment {
        // SonarQube Details (Aapke live URLs)
        SCANNER_HOME = tool 'SonarQubeScanner'
        SONAR_PROJECT_KEY = 'interview-stream-app' // SonarQube mein aapke project ka naam
        SONAR_HOST_URL = 'http://sonarqube.imcc.com/' 

        // Nexus Details
        NEXUS_REGISTRY_DOCKER = 'nexus.imcc.com:8082' // Aapka Docker Registry (Port 8082 assume kiya gaya hai)
        IMAGE_NAME = "interview-stream-app"
        
        // Kubernetes Details
        K8S_DEPLOYMENT_NAME = 'interview-stream-deployment'
    }
    
    stages {
        // Stage 1: Code Pull Karna
        stage('Checkout Code') {
            steps {
                echo 'Checking out code from GitHub...'
                git branch: 'master', 
                    credentialsId: 'github-credentials', 
                    url: 'https://github.com/sam160203/interview-stream.git'
            }
        }
        
        // Stage 2: Code Quality Check (SonarQube)
        stage('SonarQube Analysis') {
            steps {
                echo 'Running static code analysis via SonarQube...'
                withSonarQubeEnv('SonarQube-IMCC') { // 'SonarQube-IMCC' naam se configure kiya gaya tha
                    sh "${SCANNER_HOME}/bin/sonar-scanner -Dsonar.projectKey=${SONAR_PROJECT_KEY} -Dsonar.sources=."
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
                    
                    // Hum build command chala rahe hain taaki naye changes include ho saken.
                    sh "docker build -t ${IMAGE_NAME}:${env.IMAGE_TAG} ."
                }
            }
        }

        // Stage 5: Push Image to Nexus
        stage('Push to Nexus') {
            steps {
                echo "Pushing image to Nexus registry..."
                
                sh "docker tag ${IMAGE_NAME}:${env.IMAGE_TAG} ${NEXUS_REGISTRY_DOCKER}/${IMAGE_NAME}:${env.IMAGE_TAG}"

                // Nexus credentials ka use karke login aur push karna
                withCredentials([usernamePassword(credentialsId: 'nexus-credentials-imcc', 
                                                 usernameVariable: 'NEXUS_USER', 
                                                 passwordVariable: 'NEXUS_PASS')]) {
                    
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
                    
                    // 1. Image Tag Replace karna (deployment-and-secrets.yaml mein)
                    sh "sed -i 's|PLACEHOLDER_IMAGE_TAG|${NEXUS_REGISTRY_DOCKER}/${IMAGE_NAME}:${env.IMAGE_TAG}|g' k8s/deployment-and-secrets.yaml"
                    
                    // 2. Deployment aur Secrets Apply Karna
                    sh "kubectl apply -f k8s/deployment-and-secrets.yaml"
                    
                    // 3. Service Apply Karna
                    sh "kubectl apply -f k8s/service.yaml"
                    
                    // 4. Deployment ki safalta ka intezaar karna
                    sh "kubectl rollout status deployment/${K8S_DEPLOYMENT_NAME}"
                }
            }
        }
    }
}