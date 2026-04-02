pipeline {
    agent any

    environment {
        TF_DIR      = 'terraform'
        ANSIBLE_DIR = 'ansible'
        AWS_DEFAULT_REGION = 'us-east-1'

        KEY_PATH = '/mnt/c/Users/Shubham/OneDrive/Desktop/demo-1/my-tf-key.pem'
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
                        def webOutput = bat(
                            script: "terraform output -raw web_public_ip",
                            returnStdout: true
                        ).trim()

                        def appOutput = bat(
                            script: "terraform output -raw app_private_ip",
                            returnStdout: true
                        ).trim()

                        env.WEB_IP = webOutput.tokenize('\n')[-1].trim()
                        env.APP_IP = appOutput.tokenize('\n')[-1].trim()

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
${env.WEB_IP} ansible_user=ec2-user ansible_ssh_private_key_file=${KEY_PATH}

[app]
${env.APP_IP} ansible_user=ec2-user ansible_ssh_private_key_file=${KEY_PATH}

[app:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p ec2-user@${env.WEB_IP} -i ${KEY_PATH}"'
"""
                }
            }
        }

        stage('Fix Key Permission') {
            steps {
                bat """
                wsl chmod 400 ${KEY_PATH}
                """
            }
        }

        stage('Wait for Instances') {
            steps {
                bat """
                cd ${ANSIBLE_DIR}
                set ANSIBLE_HOST_KEY_CHECKING=False

                wsl ansible -i inventory.ini web -m ping
                """
            }
        }

        stage('Run Ansible') {
            steps {
                bat """
                cd ${ANSIBLE_DIR}

                echo Running Ansible...

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
