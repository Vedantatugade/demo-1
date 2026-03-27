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

        stage('Debug Tools') {
            steps {
                bat '''
                echo ===== DEBUG START =====
                terraform --version
                dir
                echo ===== DEBUG END =====
                '''
            }
        }

        #################################
        # TERRAFORM INIT (WITH AWS CREDS)
        #################################
        stage('Terraform Init') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-credentials-1',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    dir('terraform') {
                        bat 'terraform init -reconfigure'
                    }
                }
            }
        }

        #################################
        # TERRAFORM VALIDATE
        #################################
        stage('Terraform Validate') {
            steps {
                dir('terraform') {
                    bat 'terraform validate'
                }
            }
        }

        #################################
        # TERRAFORM PLAN
        #################################
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

        #################################
        # TERRAFORM APPLY
        #################################
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

        #################################
        # TERRAFORM OUTPUT
        #################################
        stage('Terraform Output') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-credentials-1',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    dir('terraform') {
                        bat '''
                        terraform output
                        terraform output -raw web_public_ip > ip.txt
                        type ip.txt
                        '''
                    }
                }
            }
        }

        #################################
        # CREATE ANSIBLE INVENTORY
        #################################
        stage('Create Ansible Inventory') {
            steps {
                bat '''
                cd ansible

                if not exist ..\\terraform\\ip.txt (
                    echo ERROR: ip.txt not found
                    exit 1
                )

                echo [web] > inventory
                for /f %%i in (..\\terraform\\ip.txt) do (
                    echo %%i ansible_user=ec2-user ansible_ssh_private_key_file=../my-tf-key.pem >> inventory
                )

                type inventory
                '''
            }
        }

        #################################
        # RUN ANSIBLE PLAYBOOK
        #################################
        stage('Run Ansible Playbook') {
            steps {
                bat '''
                wsl ansible-playbook -i ansible/inventory ansible/playbook.yml
                '''
            }
        }
    }

    #################################
    # POST ACTIONS
    #################################
    post {
        success {
            echo '✅ Deployment successful!'
        }
        failure {
            echo '❌ Pipeline failed. Check logs.'
        }
    }
}