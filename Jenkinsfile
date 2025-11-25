pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:

  - name: node
    image: node:18
    command: ['cat']
    tty: true

  - name: sonar-scanner
    image: sonarsource/sonar-scanner-cli
    command: ['cat']
    tty: true

  - name: kubectl
    image: bitnami/kubectl:latest
    command: ['cat']
    tty: true
    securityContext:
      runAsUser: 0
      readOnlyRootFilesystem: false
    env:
      - name: KUBECONFIG
        value: /kube/config
    volumeMounts:
      - name: kubeconfig-secret
        mountPath: /kube/config
        subPath: kubeconfig

  - name: dind
    image: docker:dind
    args: ["--storage-driver=overlay2"]
    securityContext:
      privileged: true
    env:
      - name: DOCKER_TLS_CERTDIR
        value: ""

  volumes:
    - name: kubeconfig-secret
      secret:
        secretName: kubeconfig-secret
'''
        }
    }

    environment {
        // change if needed
        SONAR_PROJECT_KEY = 'interview-stream-app'
        SONAR_HOST_URL = 'http://sonarqube.imcc.com'
        NEXUS_REGISTRY_DOCKER = '192.168.20.250:8082'
        IMAGE_NAME = "interview-stream-app"
        // k8s namespace (change if you use a different one)
        NAMESPACE = '2401054'
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo 'Checking out code from GitHub...'
                git branch: 'master',
                    credentialsId: 'github-credentials-sam',
                    url: 'https://github.com/sam160203/interview-stream.git'
            }
        }

        stage('Install + Build Frontend') {
            steps {
                container('node') {
                    sh '''
                        echo "Installing dependencies..."
                        # Use npm ci if package-lock.json exists for deterministic installs
                        if [ -f package-lock.json ]; then npm ci; else npm install; fi
                        echo "Building frontend (if present)..."
                        # If project has a build step; adjust if your project uses a different command
                        if grep -q "build" package.json 2>/dev/null; then npm run build || true; fi
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // short git commit for tag
                    env.IMAGE_TAG = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    env.FULL_IMAGE = "${NEXUS_REGISTRY_DOCKER}/${IMAGE_NAME}:${env.IMAGE_TAG}"
                }

                container('dind') {
                    sh """
                        echo "Waiting for docker daemon..."
                        sleep 5
                        echo "Building docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
                        docker build --build-arg NEXT_PUBLIC_CONVEX_URL="${NEXT_PUBLIC_CONVEX_URL ?: ''}" \
                                     --build-arg NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="${NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY ?: ''}" \
                                     --build-arg NEXT_PUBLIC_STREAM_API_KEY="${NEXT_PUBLIC_STREAM_API_KEY ?: ''}" \
                                     -t ${IMAGE_NAME}:${IMAGE_TAG} .
                    """
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                // withSonarQubeEnv uses the SonarQube config in Jenkins (Manage Jenkins -> Configure System)
                // Make sure you have a SonarQube server defined in Jenkins with name 'sonarqube' (or change below)
                withSonarQubeEnv('sonarqube') {
                    container('sonar-scanner') {
                        withCredentials([string(credentialsId: 'sonarqube-token-imcc', variable: 'SONAR_TOKEN')]) {
                            sh """
                                echo "Running sonar-scanner..."
                                sonar-scanner \
                                    -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                                    -Dsonar.sources=. \
                                    -Dsonar.host.url=${SONAR_HOST_URL} \
                                    -Dsonar.login=${SONAR_TOKEN}
                            """
                        }
                    }
                }
            }
        }

        stage('Quality Gate Check') {
            steps {
                echo 'Waiting for SonarQube Quality Gate...'
                // This requires the SonarQube plugin in Jenkins and that sonar analysis was performed with withSonarQubeEnv
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Login to Nexus Registry') {
            steps {
                container('dind') {
                    withCredentials([usernamePassword(credentialsId: 'nexus-credentials-imcc',
                                                     usernameVariable: 'NEXUS_USER',
                                                     passwordVariable: 'NEXUS_PASS')]) {
                        sh '''
                            echo "Logging in to Nexus Docker registry..."
                            docker login ${NEXUS_REGISTRY_DOCKER} -u $NEXUS_USER -p $NEXUS_PASS
                        '''
                    }
                }
            }
        }

        stage('Push to Nexus') {
            steps {
                container('dind') {
                    sh """
                        echo "Tagging image ${IMAGE_NAME}:${IMAGE_TAG} -> ${FULL_IMAGE}"
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${FULL_IMAGE}
                        echo "Pushing ${FULL_IMAGE} ..."
                        docker push ${FULL_IMAGE}
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    sh """
                        echo "Updating deployment image in namespace ${NAMESPACE}..."
                        # Use kubectl set image to update the container image in the running deployment
                        kubectl -n ${NAMESPACE} set image deployment/interview-stream-deployment interview-stream-app=${FULL_IMAGE} --record || true

                        echo "Applying deployment/service YAMLs from repo (if present)..."
                        if [ -f k8s/deployment.yaml ]; then
                            # Optionally replace PLACEHOLDER_IMAGE_TAG in repo file (in case you want to apply file too)
                            sed -i "s|PLACEHOLDER_IMAGE_TAG|${FULL_IMAGE}|g" k8s/deployment.yaml || true
                            kubectl -n ${NAMESPACE} apply -f k8s/deployment.yaml || true
                        fi
                        if [ -f k8s/service.yaml ]; then
                            kubectl -n ${NAMESPACE} apply -f k8s/service.yaml || true
                        fi

                        echo "Waiting for rollout to finish..."
                        kubectl -n ${NAMESPACE} rollout status deployment/interview-stream-deployment --timeout=180s
                    """
                }
            }
        }

        stage('Debug Pods') {
            steps {
                container('kubectl') {
                    sh """
                        echo "Listing pods in namespace ${NAMESPACE}..."
                        kubectl -n ${NAMESPACE} get pods -o wide
                        echo "First 200 lines of describe of pods (helpful if something failed)..."
                        kubectl -n ${NAMESPACE} describe pods | head -n 200 || true
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully. Image pushed: ${FULL_IMAGE}"
        }
        failure {
            echo "Pipeline failed. Check console output."
        }
    }
}
