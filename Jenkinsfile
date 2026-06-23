pipeline {

    agent any

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['DEV', 'QA', 'PROD'],
            description: 'Select Environment'
        )
    }

    stages {

        stage('Build') {
            steps {
                echo "Building Application..."
            }
        }

        stage('Deploy') {

            when {
                expression {
                    params.ENVIRONMENT == 'PROD'
                }
            }

            steps {
                echo "Deploying to Production..."
            }
        }
    }

    post {
        always {
            echo "Pipeline Finished"
        }
    }
}
