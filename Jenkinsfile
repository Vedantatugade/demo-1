pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION = "true"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/Vedantatugade/demo-1'
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir('terraform') {
                        bat 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('terraform') {
                    bat 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    bat 'terraform plan -out=tfplan'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                input message: 'Approve Terraform Apply?', ok: 'Apply'
                dir('terraform') {
                    bat 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Fetch Outputs') {
            steps {
                dir('terraform') {
                    bat 'terraform output'
                }
            }
        }
    }

    post {
        success {
            echo '✅ Deployment Successful'
        }
        failure {
            echo '❌ Deployment Failed'
        }
    }
}
