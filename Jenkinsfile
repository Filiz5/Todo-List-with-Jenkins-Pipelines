pipeline {
    agent any
    environment {
        PATH=sh(script:"echo $PATH:/usr/local/bin", returnStdout:true).trim()
        AWS_REGION = "us-east-1"
        ANS_KEYPAIR="jenkins-project"
        AWS_ACCOUNT_ID=sh(script:'export PATH="$PATH:/usr/local/bin" && aws sts get-caller-identity --query Account --output text', returnStdout:true).trim()
        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        APP_REPO_NAME = "techpro-repo/todo-app"
        APP_NAME = "todo"
    }
    stages {
        stage('Create Key Pair for Ansible') {
            steps {
                echo "Creating Key Pair for ${APP_NAME} App"
                // Eğer anahtar çifti zaten varsa, önce silin
                sh "aws ec2 delete-key-pair --region ${AWS_REGION} --key-name ${ANS_KEYPAIR} || true"
                
                // Key pair oluştur ve dosyayı güvenli bir şekilde kaydet
                sh """
                aws ec2 create-key-pair --region ${AWS_REGION} --key-name ${ANS_KEYPAIR} --query KeyMaterial --output text > ${WORKSPACE}/${ANS_KEYPAIR}.pem
                chmod 400 ${WORKSPACE}/${ANS_KEYPAIR}.pem
                """
            }
        }

        stage('Create Infrastructure for the App') {
            steps {
                echo 'Creating Infrastructure for the App on AWS Cloud'
                sh 'terraform init'
                sh 'terraform apply --auto-approve'
            }
        }

        stage('Create ECR Repo') {
            steps {
                echo 'Creating ECR Repo for App'
                sh """
                    aws ecr describe-repositories --region ${AWS_REGION} --repository-name ${APP_REPO_NAME} || \
                    aws ecr create-repository \
                    --repository-name ${APP_REPO_NAME} \
                    --image-scanning-configuration scanOnPush=false \
                    --image-tag-mutability MUTABLE \
                    --region ${AWS_REGION}
                """
            }
        }

        stage('Build App Docker Image') {
            steps {
                echo 'Building App Image'
                script {
                    env.NODE_IP = sh(script: 'terraform output -raw node_public_ip', returnStdout:true).trim()
                    if (!env.NODE_IP) {
                        error "Node IP could not be retrieved."
                    }
                }
                sh 'echo ${NODE_IP}'
                sh 'echo "REACT_APP_BASE_URL=http://${NODE_IP}:5000/" > ./react/client/.env'
                sh 'cat ./react/client/.env'
                sh 'docker build --force-rm -t "$ECR_REGISTRY/$APP_REPO_NAME:postgr" -f ./postgresql/Dockerfile .'
                sh 'docker build --force-rm -t "$ECR_REGISTRY/$APP_REPO_NAME:nodejs" -f ./nodejs/dockerfile-nodejs .'
                sh 'docker build --force-rm -t "$ECR_REGISTRY/$APP_REPO_NAME:react" -f ./react/dockerfile-react .'
                sh 'docker image ls'
            }
        }

        stage('Push Image to ECR Repo') {
            steps {
                echo 'Pushing App Image to ECR Repo'
                sh 'aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin "$ECR_REGISTRY"'
                sh 'docker push "$ECR_REGISTRY/$APP_REPO_NAME:postgr"'
                sh 'docker push "$ECR_REGISTRY/$APP_REPO_NAME:nodejs"'
                sh 'docker push "$ECR_REGISTRY/$APP_REPO_NAME:react"'
            }
        }

        stage('Wait for the EC2 Instance') {
            steps {
                script {
                    echo 'Waiting for the instance'
                    id = sh(script: 'aws ec2 describe-instances --filters Name=tag-value,Values=jenkins_project Name=instance-state-name,Values=running --query Reservations[*].Instances[*].[InstanceId] --output text',  returnStdout:true).trim()
                    if (!id) {
                        error "No instance found or running."
                    }
                    sh 'aws ec2 wait instance-status-ok --instance-ids $id'
                }
            }
        }

        stage('Deploy the App') {
            steps {
                echo 'Deploy the App'
                sh 'ls -l'
                sh 'ansible --version'
                script {
                    def inventoryExists = fileExists("${WORKSPACE}/inventory_aws_ec2.yml")
                    if (!inventoryExists) {
                        error "Ansible inventory file not found!"
                    }
                }
                sh 'ansible-inventory -i inventory_aws_ec2.yml --graph'
                sh """
                    export ANSIBLE_PRIVATE_KEY_FILE="${WORKSPACE}/${ANS_KEYPAIR}.pem"
                    export ANSIBLE_HOST_KEY_CHECKING=False
                    ansible-playbook -i ./inventory_aws_ec2.yml -e "compose_dir=${env.WORKSPACE}" ./playbook.yml
                """
             }
        }

        stage('Destroy the infrastructure') {
            steps {
                timeout(time:5, unit:'DAYS'){
                    input message:'Approve terminate'
                }
                sh """
                docker image prune -af || true
                terraform destroy --auto-approve || true
                aws ecr delete-repository \
                  --repository-name ${APP_REPO_NAME} \
                  --region ${AWS_REGION} \
                  --force || true
                aws ec2 delete-key-pair --region ${AWS_REGION} --key-name ${ANS_KEYPAIR} || true
                rm -rf ${WORKSPACE}/${ANS_KEYPAIR}.pem || true
                """
            }
        }
    }

    post {
        always {
            echo 'Deleting all local images'
            sh 'docker image prune -af || true'
        }
        failure {
            echo 'Delete the Image Repository on ECR due to the Failure'
            sh """
                aws ecr delete-repository \
                  --repository-name ${APP_REPO_NAME} \
                  --region ${AWS_REGION} \
                  --force || true
            """
            sh """
                aws ec2 delete-key-pair --region ${AWS_REGION} --key-name ${ANS_KEYPAIR} || true
                rm -rf ${WORKSPACE}/${ANS_KEYPAIR}.pem || true
            """
            echo 'Deleting Terraform Stack due to the Failure'
            sh 'terraform destroy --auto-approve || true'
        }
    }
}
