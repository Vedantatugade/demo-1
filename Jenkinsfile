pipeline {
    agent any

    environment {
        TF_DIR      = 'terraform'
        ANSIBLE_DIR = 'ansible'
        AWS_DEFAULT_REGION = 'us-east-1'

        TF_PLUGIN_CACHE_DIR = 'C:\\terraform-cache'
    }

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    stages {

        stage('Clean Workspace') {
            steps {
                cleanWs()
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

                        terraform init -reconfigure
                        terraform validate
                        terraform apply -auto-approve -var-file="terraform.tfvars"
                        """
                    }
                }
            }
        }

        stage('Fetch Instance IDs') {
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
                            def webId = bat(
                                script: "terraform output -raw web_instance_id",
                                returnStdout: true
                            ).trim()

                            def appId = bat(
                                script: "terraform output -raw app_instance_id",
                                returnStdout: true
                            ).trim()

                            env.WEB_ID = webId.tokenize('\n')[-1].trim()
                            env.APP_ID = appId.tokenize('\n')[-1].trim()

                            echo "WEB_ID=${env.WEB_ID}"
                            echo "APP_ID=${env.APP_ID}"
                        }
                    }
                }
            }
        }

        stage('Create Inventory (SSM)') {
    steps {
        script {
            writeFile file: "${ANSIBLE_DIR}/inventory.ini", text: """

[web]
${env.WEB_ID} ansible_connection=aws_ssm ansible_user=ec2-user ansible_python_interpreter=/home/vedant/ansible-venv/bin/python

[app]
${env.APP_ID} ansible_connection=aws_ssm ansible_user=ec2-user ansible_python_interpreter=/home/vedant/ansible-venv/bin/python
"""
        }
    }
}

        stage('Wait for EC2 Boot') {
            steps {
                echo "Waiting for EC2 + SSM..."
                sleep(time: 120, unit: 'SECONDS')
            }
        }

        stage('Run Ansible (SSM)') {
            steps {
                bat '''
                wsl bash -c "source ~/ansible-venv/bin/activate && \
                export AWS_DEFAULT_REGION=us-east-1 && \
                cd /mnt/c/ProgramData/Jenkins/.jenkins/workspace/demo-1/ansible && \
                ansible-playbook -vvv -i inventory.ini playbook.yml"
                '''
            }
        }

        stage('Health Check') {
            steps {
                echo "Skipping curl (SSM setup)"
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
            cleanWs()
        }
    }
}
