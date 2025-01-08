pipeline {
    agent any

    environment {
        IMAGE_NAME = "homoludens-backend"
        DB_URL = credentials('db_url')
        DB_USERNAME = credentials('db_username')
        DB_PASSWORD = credentials('db_password')
        SERVER_PORT = credentials('server_port')
        PROD_SERVER_IP = credentials('prod-server-ip')
    }

    stages {
        stage('Build Docker Image') {
            steps {
                echo '🐳 [CI] Docker 이미지 빌드 시작...'
                sh '''
                docker build -t ${IMAGE_NAME}:${BRANCH_NAME} .
                '''
            }
        }

        stage('Save Docker Image') {
            steps {
                echo '💾 [CI] Docker 이미지를 파일로 저장...'
                sh '''
                docker save -o ${IMAGE_NAME}-${BRANCH_NAME}.tar ${IMAGE_NAME}:${BRANCH_NAME}
                '''
            }
        }

        stage('Transfer Docker Image to Production Server') {
            when {
                branch 'main'
            }
            steps {
                echo '🚚 [CD] Docker 이미지를 운영 서버로 전송...'
                withCredentials([sshUserPrivateKey(credentialsId: 'prod-ssh-key', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    sh '''
                    scp -o StrictHostKeyChecking=no -i $SSH_KEY ${IMAGE_NAME}-${BRANCH_NAME}.tar $SSH_USER@${PROD_SERVER_IP}:/tmp/
                    '''
                }
            }
        }

        stage('Deploy to Development Server') {
            when {
                branch 'develop'
            }
            steps {
                echo '🚀 [CD] 개발 서버에 Docker 이미지 배포...'
                sh '''
                docker load -i ${IMAGE_NAME}-${BRANCH_NAME}.tar
                docker compose down || true
                docker compose up -d
                '''
            }
        }

        stage('Deploy to Production Server') {
            when {
                branch 'main'
            }
            steps {
                echo '🚀 [CD] 운영 서버에 Docker 이미지 배포...'
                withCredentials([sshUserPrivateKey(credentialsId: 'prod-ssh-key', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    sh '''
                    ssh -o StrictHostKeyChecking=no -i $SSH_KEY $SSH_USER@${PROD_SERVER_IP} << EOF
                        docker load -i /tmp/${IMAGE_NAME}-${BRANCH_NAME}.tar
                        docker compose down || true
                        docker compose up -d
                    EOF
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '🔍 [CD] 배포 검증 단계...'
                sh '''
                docker ps
                '''
            }
        }
    }

    post {
        success {
            echo '✅ [SUCCESS] 배포가 성공적으로 완료되었습니다.'
        }
        failure {
            echo '❌ [FAILURE] 배포 실패. 로그 확인이 필요합니다.'
        }
    }
}
