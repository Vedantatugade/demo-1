pipeline {
    agent any

    environment {
        TF_DIR      = 'terraform'
        ANSIBLE_DIR = 'ansible'
        AWS_DEFAULT_REGION = 'ap-south-1'
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

        stage('Terraform Deploy') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    dir("${TF_DIR}") {
                        sh '''
                        terraform init
                        terraform validate
                        terraform plan -var-file="terraform.tfvars" -out=tfplan
                        terraform apply -auto-approve tfplan
                        '''
                    }
                }
            }
        }

        stage('Fetch IPs') {
            steps {
                dir("${TF_DIR}") {
                    script {
                        env.WEB_IP = sh(
                            script: "terraform output -raw web_public_ip",
                            returnStdout: true
                        ).trim()

                        env.APP_IP = sh(
                            script: "terraform output -raw app_private_ip",
                            returnStdout: true
                        ).trim()

                        echo "WEB_IP=${env.WEB_IP}"
                        echo "APP_IP=${env.APP_IP}"
                    }
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

[app:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p ec2-user@${env.WEB_IP}"'
"""
                }
            }
        }

        stage('Wait for Instances') {
            steps {
                sh """
                cd ${ANSIBLE_DIR}
                export ANSIBLE_HOST_KEY_CHECKING=False
                ansible -i inventory.ini web -m wait_for_connection --timeout=300
                """
            }
        }

        stage('Run Ansible') {
            steps {
                sh """
                cd ${ANSIBLE_DIR}

                echo "Running as:"
                whoami

                echo "Checking Ansible:"
                which ansible
                ansible --version

                export ANSIBLE_HOST_KEY_CHECKING=False

                ansible -i inventory.ini web -m wait_for_connection --timeout=300
                """
            }
        }

        stage('Health Check') {
            steps {
                sh "curl -f http://${env.WEB_IP}"
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
