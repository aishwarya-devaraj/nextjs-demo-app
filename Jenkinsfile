pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                git 'https://github.com/aishwarya-devaraj/nextjs-demo-app.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('Build Next.js') {
            steps {
                sh 'npm run build'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t nextjs-app:v1 .'
            }
        }
    }
}
