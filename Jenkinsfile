pipeline {

    agent any

    environment {
        NEXUS_URL = "http://nexus.imcc.com/repository/student-repo/"
        ARTIFACT_NAME = "nextjs-app-build.zip"
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo "Pulling project from GitHub..."
                git branch: 'master',
                    credentialsId: 'github-credentials-sam',
                    url: 'https://github.com/sam160203/interview-stream.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                echo "Installing Node.js dependencies..."
                sh "npm install"
            }
        }

        stage('Build Next.js App') {
            steps {
                echo "Running Next.js build..."
                sh "npm run build"
            }
        }

        stage('Prepare Artifact') {
            steps {
                echo "Zipping build folder..."

                sh """
                    rm -f ${ARTIFACT_NAME}
                    zip -r ${ARTIFACT_NAME} .next public package.json
                """
            }
        }

        stage('Upload to Nexus') {
            steps {

                withCredentials([usernamePassword(
                    credentialsId: 'nexus-credentials-imcc',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {

                    echo "Uploading zip to Nexus..."

                    sh """
                        curl -v -u ${NEXUS_USER}:${NEXUS_PASS} \
                        --upload-file ${ARTIFACT_NAME} \
                        ${NEXUS_URL}${ARTIFACT_NAME}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "🎉 Build & Upload successful!"
        }
        failure {
            echo "❌ Build failed!"
        }
    }
}
