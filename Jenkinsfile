pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
    }

    stages {

        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-credentials-1',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    dir('terraform') {
                        bat 'terraform init -upgrade'
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
                withCredentials([usernamePassword(
                    credentialsId: 'aws-credentials-1',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    dir('terraform') {
                        bat 'terraform plan'
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-credentials-1',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    dir('terraform') {
                        bat 'terraform apply -auto-approve'
                    }
                }
            }
        }

        stage('Terraform Output') {
    steps {
        withCredentials([usernamePassword(
            credentialsId: 'aws-credentials-1',
            usernameVariable: 'AWS_ACCESS_KEY_ID',
            passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
            dir('terraform') {
                bat '''
                terraform output -raw web_public_ip > ip.txt
                '''
            }
        }
    }
}

        stage('Create Ansible Inventory') {
            steps {
                bat '''
                cd ansible

                echo [web] > inventory
                for /f %%i in (..\\terraform\\ip.txt) do (
                    echo %%i ansible_user=ec2-user ansible_ssh_private_key_file=../my-tf-key.pem >> inventory
                )
                '''
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                bat 'ansible-playbook -i ansible/inventory ansible/playbook.yml'
            }
        }
    }

    post {
        success {
            echo 'SUCCESS'
        }
        failure {
            echo 'FAILED'
        }
    }
}
