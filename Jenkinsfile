pipeline {

    agent any

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['DEV', 'QA', 'PROD'],
            description: 'Select the deployment environment'
        )
    }

    stages {

        stage('Display Environment') {
            steps {
                echo "Selected Environment: ${params.ENVIRONMENT}"
            }
        }

    }

    post {
        always {
            echo "Pipeline Finished"
        }
    }
}
