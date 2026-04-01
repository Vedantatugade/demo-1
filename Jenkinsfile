pipeline {
agent any

```
environment {
    TF_DIR      = 'terraform'
    ANSIBLE_DIR = 'ansible'
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

    stage('Terraform Init') {
        steps {
            dir("${TF_DIR}") {
                sh 'terraform init'
            }
        }
    }

    stage('Terraform Validate') {
        steps {
            dir("${TF_DIR}") {
                sh 'terraform validate'
            }
        }
    }

    stage('Terraform Plan') {
        steps {
            dir("${TF_DIR}") {
                sh 'terraform plan -var-file="terraform.tfvars" -out=tfplan'
            }
        }
    }

    stage('Terraform Apply') {
        steps {
            dir("${TF_DIR}") {
                sh 'terraform apply -auto-approve tfplan'
            }
        }
    }

    stage('Fetch IPs') {
        steps {
            script {
                env.WEB_IP = sh(
                    script: "cd ${TF_DIR} && terraform output -raw web_public_ip",
                    returnStdout: true
                ).trim()

                env.APP_IP = sh(
                    script: "cd ${TF_DIR} && terraform output -raw app_private_ip",
                    returnStdout: true
                ).trim()
            }
        }
    }

    stage('Create Inventory') {
        steps {
            script {
                writeFile file: "${ANSIBLE_DIR}/inventory.ini", text: """
```

[web]
${env.WEB_IP} ansible_user=ec2-user

[app]
${env.APP_IP} ansible_user=ec2-user

[app:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -i $KEY_FILE -W %h:%p ec2-user@${env.WEB_IP}"'
"""
}
}
}

```
    stage('Wait for Instances') {
        steps {
            sh '''
            cd ${ANSIBLE_DIR}
            export ANSIBLE_HOST_KEY_CHECKING=False
            ansible -i inventory.ini web -m wait_for_connection --timeout=300
            '''
        }
    }

    stage('Run Ansible') {
        steps {
            withCredentials([
                sshUserPrivateKey(
                    credentialsId: 'ec2-key',
                    keyFileVariable: 'KEY_FILE'
                )
            ]) {
                sh '''
                cd ${ANSIBLE_DIR}
                chmod 400 $KEY_FILE
                export ANSIBLE_HOST_KEY_CHECKING=False

                ansible-playbook -i inventory.ini web.yml --private-key $KEY_FILE
                ansible-playbook -i inventory.ini app.yml --private-key $KEY_FILE
                '''
            }
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
```

}
