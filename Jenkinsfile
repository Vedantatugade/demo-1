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
            withCredentials([
                string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
            ]) {
                dir("${TF_DIR}") {
                    sh '''
                    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                    terraform init
                    '''
                }
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
            withCredentials([
                string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
            ]) {
                dir("${TF_DIR}") {
                    sh '''
                    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                    terraform plan -var-file="terraform.tfvars" -out=tfplan
                    '''
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
                dir("${TF_DIR}") {
                    sh '''
                    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                    terraform apply -auto-approve tfplan
                    '''
                }
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
${env.APP_IP} ansible_user=ec2-user ansible_ssh_common_args='-o ProxyCommand="ssh -i $KEY_FILE -W %h:%p ec2-user@${env.WEB_IP}"'
"""
}
}
}

```
    stage('Wait for Instances') {
        steps {
            sh 'sleep 120'
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

                ansible -i inventory.ini web -m ping --private-key $KEY_FILE
                ansible-playbook -i inventory.ini web.yml --private-key $KEY_FILE

                ansible -i inventory.ini app -m ping --private-key $KEY_FILE
                ansible-playbook -i inventory.ini app.yml --private-key $KEY_FILE
                '''
            }
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
