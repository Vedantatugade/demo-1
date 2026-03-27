pipeline {
    agent any

    stages {

        stage('Terraform Init') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir('terraform') {
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir('terraform') {
                        sh 'terraform plan'
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
                    dir('terraform') {
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }

        stage('Run Ansible') {
            steps {
                script {
                    def EC2_IP = sh(
                        script: "cd terraform && terraform output -raw web_public_ip",
                        returnStdout: true
                    ).trim()

                    sh """
                    cd 3tier
                    chmod 400 ../my-tf-key.pem
                    echo "[web]" > inventory
                    echo "$EC2_IP ansible_user=ec2-user ansible_ssh_private_key_file=../my-tf-key.pem" >> inventory
                    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory playbook.yml
                    """
                }
            }
        }

    }
}