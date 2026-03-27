pipeline {
agent any

```
environment {
    AWS_DEFAULT_REGION = 'ap-east-1'
}

stages {

    stage('Checkout Code') {
        steps {
            checkout scm
        }
    }

    stage('Terraform Init') {
        steps {
            dir('terraform') {
                bat 'terraform init'
            }
        }
    }

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

    stage('Terraform Output') {
        steps {
            withCredentials([usernamePassword(
                credentialsId: 'aws-credentials-1',
                usernameVariable: 'AWS_ACCESS_KEY_ID',
                passwordVariable: 'AWS_SECRET_ACCESS_KEY'
            )]) {
                dir('terraform') {
                    bat 'terraform output -raw web_public_ip > ip.txt'
                }
            }
        }
    }

    stage('Create Ansible Inventory') {
        steps {
            bat '''
            cd ansible
            echo [web] > inventory
            for /f %%i in (..\\terraform\\ip.txt) do echo %%i ansible_user=ec2-user ansible_ssh_private_key_file=../my-tf-key.pem >> inventory
            '''
        }
    }

    stage('Run Ansible Playbook') {
        steps {
            bat '''
            cd ansible
            ansible-playbook -i inventory playbook.yml
            '''
        }
    }

}

post {
    success {
        echo ' Deployment successful!'
    }
    failure {
        echo ' Pipeline failed. Check logs.'
    }
}
```

}
