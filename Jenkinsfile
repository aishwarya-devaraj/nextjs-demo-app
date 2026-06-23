pipeline {

    agent any

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/aishwarya-devaraj/nextjs-demo-app.git'
            }
        }

        stage('Workspace') {
            steps {
                sh 'pwd'
                sh 'whoami'
                sh 'ls -la'
            }
        }

        stage('Build') {
            steps {
                echo 'Build Started'
            }
        }
    }

    post {
        success {
            echo 'Pipeline Success'
        }

        failure {
            echo 'Pipeline Failed'
        }

        always {
            echo 'Pipeline Finished'
        }
    }
}
