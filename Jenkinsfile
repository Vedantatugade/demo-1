pipeline {
agent any


environment {
    TF_DIR      = 'terraform'
    ANSIBLE_DIR = 'ansible'
    AWS_DEFAULT_REGION = 'us-east-1'

    // SSH key (WSL path)
    KEY_PATH = '/home/vedant/.ssh/my-tf-key.pem'

    // Terraform plugin cache (🚀 speeds up builds)
    TF_PLUGIN_CACHE_DIR = 'C:\\terraform-cache'
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
                    terraform init -upgrade=false
                    terraform validate
                    terraform apply -auto-approve -var-file="terraform.tfvars"
                    '''
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

    stage('Wait for SSH') {
        steps {
            retry(5) {
                bat """
                cd ${ANSIBLE_DIR}
                set ANSIBLE_HOST_KEY_CHECKING=False

                echo Testing SSH...

                wsl ssh -o StrictHostKeyChecking=no -i ${KEY_PATH} ec2-user@${env.WEB_IP} "echo connected"
                """
            }
        }
    }

    stage('Run Ansible') {
        steps {
            bat """
            cd ${ANSIBLE_DIR}

            echo Running Ansible...

            wsl ansible-playbook -vvv -i inventory.ini playbook.yml
            """
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
}


}
