pipeline {
    agent any 
    
    // Environment Variables: Saare URLs aur Credentials yahan define honge
    environment {
        // SonarQube Details (FIX: IP aur Port hardcode kiye gaye hain)
        SONAR_PROJECT_KEY = 'interview-stream-app'
        SONAR_HOST_URL = 'http://sonarqube.imcc.com' 
        
        // Nexus Details
        NEXUS_REGISTRY_DOCKER = '192.168.20.250:8082' // FIX: Hardcoded IP aur Port
        IMAGE_NAME = "interview-stream-app"
    }
    
    stages {
        // Stage 1: Code Pull Karna
        stage('Checkout Code') {
            steps {
                echo 'Checking out code from GitHub...'
                git branch: 'master', 
                    credentialsId: 'github-credentials-sam', 
                    url: 'https://github.com/sam160203/interview-stream.git'
            }
        }
        
        // Stage 2: SonarQube Analysis
        stage('SonarQube Analysis') {
            steps {
                echo 'Running static code analysis via Dockerized SonarQube Scanner...'
                
                withCredentials([string(credentialsId: 'sonarqube-token-imcc', variable: 'SONAR_TOKEN')]) {
                    container('dind') { 
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
                }
                
                container('dind') {
                    sh "docker build -t ${IMAGE_NAME}:${env.IMAGE_TAG} ."
                }
            }
        }

        // Stage 5: Push Image to Nexus
        stage('Push to Nexus') {
            steps {
                echo "Pushing image to Nexus registry..."
                
                container('dind') {
                     sh "docker tag ${IMAGE_NAME}:${env.IMAGE_TAG} ${NEXUS_REGISTRY_DOCKER}/${IMAGE_NAME}:${env.IMAGE_TAG}"
                }

                withCredentials([usernamePassword(credentialsId: 'nexus-credentials-imcc', 
                                                 usernameVariable: 'NEXUS_USER', 
                                                 passwordVariable: 'NEXUS_PASS')]) {
                    
                    container('dind') {
                        sh "docker login -u ${NEXUS_USER} -p ${NEXUS_PASS} ${NEXUS_REGISTRY_DOCKER}" 
                        sh "docker push ${NEXUS_REGISTRY_DOCKER}/${IMAGE_NAME}:${env.IMAGE_TAG}"
                    }
                }
                echo 'Image successfully pushed to Nexus.'
            }
        }

        // ❌ Stage 6: Deploy to Kubernetes - HATA DIYA GAYA HAI
    }
}