pipeline {
    agent any

    environment {
        DOCKERHUB_REPO = 'aishwaryadevaraj/nextjs-demo-app'
        IMAGE_TAG = 'latest'
    }

    stages {

        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
            }
        }

        stage('Build Next.js') {
            steps {
                sh 'npm run build'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${DOCKERHUB_REPO}:${IMAGE_TAG} .'
            }
        }

        stage('Login to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USERNAME',
                        passwordVariable: 'DOCKERHUB_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "$DOCKERHUB_PASSWORD" | \
                        docker login \
                        --username "$DOCKERHUB_USERNAME" \
                        --password-stdin
                    '''
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                sh 'docker push ${DOCKERHUB_REPO}:${IMAGE_TAG}'
            }
        }

        stage('Docker Logout') {
            steps {
                sh 'docker logout'
            }
        }
    }

    post {
        always {
            echo 'Pipeline Finished'
        }

        success {
            echo 'Build and Docker Push Successful!'
        }

        failure {
            echo 'Build or Docker Push Failed!'
        }
    }
}
