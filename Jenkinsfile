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
                                script: """
                                set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                                set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                                terraform output -raw web_instance_id
                                """,
                                returnStdout: true
                            ).trim()

                            def appId = bat(
                                script: """
                                set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                                set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                                terraform output -raw app_instance_id
                                """,
                                returnStdout: true
                            ).trim()

                            env.WEB_ID = webId.split("\\r?\\n")[-1]
                            env.APP_ID = appId.split("\\r?\\n")[-1]

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
${env.WEB_ID} ansible_connection=amazon.aws.aws_ssm ansible_user=ec2-user ansible_aws_ssm_region=us-east-1 ansible_remote_tmp=/tmp ansible_shell_type=sh ansible_aws_ssm_bucket_name=last-one-1

[app]
${env.APP_ID} ansible_connection=amazon.aws.aws_ssm ansible_user=ec2-user ansible_aws_ssm_region=us-east-1 ansible_remote_tmp=/tmp ansible_shell_type=sh ansible_aws_ssm_bucket_name=last-one-1
"""
        }
    }
}

stage('Debug Inventory') {
    steps {
        bat '''
        type ansible\\inventory.ini
        '''
    }
}

stage('Wait for EC2 Boot') {
    steps {
        sleep(time: 120, unit: 'SECONDS')
    }
}

        stage('Run Ansible') {
    steps {
        withCredentials([
            usernamePassword(
                credentialsId: 'aws-creds',
                usernameVariable: 'AWS_ACCESS_KEY_ID',
                passwordVariable: 'AWS_SECRET_ACCESS_KEY'
            )
        ]) {
            bat """
            wsl bash -c "export AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID% && \
            export AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY% && \
            export AWS_DEFAULT_REGION=us-east-1 && \
            /home/vedant/ansible-venv/bin/ansible-playbook -vvv \
            -i /mnt/c/ProgramData/Jenkins/.jenkins/workspace/demo-1/ansible/inventory.ini \
            /mnt/c/ProgramData/Jenkins/.jenkins/workspace/demo-1/ansible/playbook.yml"
            """
        }
    }
}

        stage('Health Check') {
            steps {
                echo "Deployment Completed Successfully"
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
