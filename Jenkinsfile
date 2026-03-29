pipeline {
    agent any

    environment {
        TF_DIR = 'terraform'
        ANSIBLE_DIR = 'ansible'
        AWS_DEFAULT_REGION = 'us-east-1'
    }

    options {
        disableConcurrentBuilds()
        timestamps()
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
                    dir("${TF_DIR}") {
                        bat 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir("${TF_DIR}") {
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
                    dir("${TF_DIR}") {
                        bat 'terraform plan -out=tfplan'
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
                    dir("${TF_DIR}") {
                        bat 'terraform apply -auto-approve tfplan'
                    }
                }
            }
        }

        stage('Fetch IPs') {
            steps {
                script {
                    env.WEB_IP = bat(
                        script: "cd ${TF_DIR} && terraform output -raw web_public_ip",
                        returnStdout: true
                    ).trim()

                    env.APP_IP = bat(
                        script: "cd ${TF_DIR} && terraform output -raw app_private_ip",
                        returnStdout: true
                    ).trim()

                    echo "Web IP: ${env.WEB_IP}"
                    echo "App IP: ${env.APP_IP}"
                }
            }
        }

        stage('Create Inventory') {
            steps {
                script {
                    writeFile file: "${ANSIBLE_DIR}/inventory.ini", text: """
[web]
${env.WEB_IP} ansible_user=ec2-user

[app]
${env.APP_IP} ansible_user=ec2-user
"""
                }
            }
        }

        stage('Wait for EC2') {
            steps {
                echo "Waiting for EC2..."
                bat 'timeout /t 60'
            }
        }

        stage('Run Ansible') {
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'ec2-key', keyFileVariable: 'KEY_FILE')
                ]) {
                    bat """
                    cd ${ANSIBLE_DIR}

                    set ANSIBLE_HOST_KEY_CHECKING=False

                    ansible-playbook -i inventory.ini web.yml --private-key %KEY_FILE%
                    ansible-playbook -i inventory.ini app.yml --private-key %KEY_FILE%
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ Deployment Successful (Terraform + Ansible)'
        }
        failure {
            echo '❌ Deployment Failed'
        }
        always {
            echo 'Pipeline execution completed.'
        }
    }
}
