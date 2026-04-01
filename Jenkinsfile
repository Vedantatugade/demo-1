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
                        bat '''
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
                        env.WEB_IP = bat(
                            script: "terraform output -raw web_public_ip",
                            returnStdout: true
                        ).trim()

                        env.APP_IP = bat(
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
                bat """
                cd ${ANSIBLE_DIR}
                set ANSIBLE_HOST_KEY_CHECKING=False

                wsl ansible --version

                wsl ansible -i inventory.ini web -m wait_for_connection --timeout=300
                """
            }
        }

        stage('Run Ansible') {
            steps {
                bat """
                cd ${ANSIBLE_DIR}

                echo Running Ansible...

                wsl ansible --version

                wsl ansible-playbook -i inventory.ini playbook.yml
                """
            }
        }

        stage('Health Check') {
            steps {
                bat "curl -f http://${env.WEB_IP}"
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
