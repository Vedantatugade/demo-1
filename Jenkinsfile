pipeline {
    agent any

    environment {
        TF_DIR = 'terraform'
        ANSIBLE_DIR = 'ansible'
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
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir("${TF_DIR}") {
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir("${TF_DIR}") {
                        sh 'terraform plan -out=tfplan'
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir("${TF_DIR}") {
                        sh 'terraform apply -auto-approve tfplan'
                    }
                }
            }
        }

        stage('Fetch IPs') {
            steps {
                script {
                    env.WEB_IP = sh(
                        script: "cd ${TF_DIR} && terraform output -raw web_public_ip",
                        returnStdout: true
                    ).trim()

                    env.APP_IP = sh(
                        script: "cd ${TF_DIR} && terraform output -raw app_private_ip",
                        returnStdout: true
                    ).trim()

                    echo "Web IP: ${env.WEB_IP}"
                    echo "App IP: ${env.APP_IP}"
                }
            }
        }

        stage('Create Ansible Inventory') {
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
                echo "Waiting for EC2 instances..."
                sh 'sleep 60'
            }
        }

        stage('Run Ansible') {
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'ec2-key', keyFileVariable: 'KEY_FILE')
                ]) {
                    sh """
                    cd ${ANSIBLE_DIR}

                    chmod 400 \$KEY_FILE

                    export ANSIBLE_HOST_KEY_CHECKING=False

                    ansible-playbook -i inventory.ini web.yml --private-key \$KEY_FILE
                    ansible-playbook -i inventory.ini app.yml --private-key \$KEY_FILE
                    """
                }
            }
        }
    }

    post {
        success {
            echo 'Deployment Successful (Terraform + Ansible)'
        }
        failure {
            echo 'Deployment Failed'
        }
        always {
            echo 'Pipeline execution completed.'
        }
    }
}