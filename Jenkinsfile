pipeline {
    agent any

    environment {
        TF_DIR      = 'terraform'
        ANSIBLE_DIR = 'ansible'
        AWS_DEFAULT_REGION = 'us-east-1'

        // SSH key (WSL path)
        KEY_PATH = '/home/vedant/.ssh/my-tf-key.pem'

        // Terraform plugin cache (Windows path)
        TF_PLUGIN_CACHE_DIR = 'C:\\terraform-cache'
    }

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    stages {

        stage('Clean Workspace') {
            steps {
                cleanWs()   // 🔥 better than deleteDir()
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
                        bat """
                        set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                        set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                        set TF_PLUGIN_CACHE_DIR=%TF_PLUGIN_CACHE_DIR%

                        terraform init
                        terraform validate
                        terraform apply -auto-approve -var-file="terraform.tfvars"
                        """
                    }
                }
            }
        }

        stage('Fetch IPs') {
    steps {
        withCredentials([
            usernamePassword(
                credentialsId: 'aws-creds',
                usernameVariable: 'AWS_ACCESS_KEY_ID',
                passwordVariable: 'AWS_SECRET_ACCESS_KEY'
            )
        ]) {
            dir("${TF_DIR}") {
                script {
                    def webOutput = bat(
                        script: """
                        set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                        set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                        terraform output -raw web_public_ip
                        """,
                        returnStdout: true
                    ).trim()

                    def appOutput = bat(
                        script: """
                        set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                        set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                        terraform output -raw app_private_ip
                        """,
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

        stage('Wait for EC2 Boot') {
            steps {
                echo "Waiting for EC2 to boot..."
                sleep(time: 90, unit: 'SECONDS')
            }
        }

        

        stage('Run Ansible') {
    steps {
        bat '''
        wsl bash -c "cd /mnt/c/ProgramData/Jenkins/.jenkins/workspace/demo-1/ansible && ansible-playbook -vvv -i inventory.ini playbook.yml"
        '''
    }
}

        stage('Health Check') {
            steps {
                bat "curl.exe -f http://${env.WEB_IP}"
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
        always {
            cleanWs()   // 🔥 AUTO CLEAN (prevents disk full issue)
        }
    }
}
