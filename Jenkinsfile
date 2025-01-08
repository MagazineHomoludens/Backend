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
        // 📌 1. CI: 코드 체크아웃
        stage('CI: Checkout Code') {
            steps {
                echo '🔄 [CI] 코드 체크아웃...'
                checkout scm
            }
        }

        // 📌 2. CI: 빌드 및 테스트
        stage('CI: Build & Test') {
            steps {
                echo '🔍 [CI] 코드 빌드 및 테스트...'
                sh '''
                chmod +x ./gradlew
                ./gradlew clean build
                '''
            }
        }

        // 📌 3. CI: Docker 이미지 빌드
        stage('CI: Build Docker Image') {
            steps {
                echo '🐳 [CI] Docker 이미지 빌드...'
                sh '''
                DOCKER_BUILDKIT=1 docker build -t ${IMAGE_NAME}:${BRANCH_NAME} .
                '''
            }
        }

        // 📌 4. CI: Docker 이미지 저장
        stage('CI: Save Docker Image') {
            steps {
                echo '💾 [CI] Docker 이미지를 파일로 저장...'
                sh '''
                docker save -o ${IMAGE_NAME}-${BRANCH_NAME}.tar ${IMAGE_NAME}:${BRANCH_NAME}
                '''
            }
        }

        // 📌 5. CD: 운영 서버로 Docker 이미지 전송 (main 브랜치)
        stage('CD: Transfer Docker Image to Production Server') {
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

        // 📌 6. CD: 개발 서버 배포 (develop 브랜치)
        stage('CD: Deploy to Development Server') {
            when {
                branch 'develop'
            }
            steps {
                echo '🚀 [CD] 개발 서버 배포...'
                sh '''
                docker load -i ${IMAGE_NAME}-${BRANCH_NAME}.tar
                docker compose down || true
                docker compose up -d
                '''
            }
        }

        // 📌 7. CD: 운영 서버 배포 (main 브랜치)
        stage('CD: Deploy to Production Server') {
            when {
                branch 'main'
            }
            steps {
                echo '🚀 [CD] 운영 서버 배포...'
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

        // 📌 8. CD: 배포 검증
        stage('CD: Verify Deployment') {
            steps {
                echo '🔍 [CD] 배포 검증...'
                sh '''
                docker ps
                '''
            }
        }
    }

    post {
        success {
            echo '✅ [SUCCESS] CI/CD 파이프라인이 성공적으로 완료되었습니다.'
        }
        failure {
            echo '❌ [FAILURE] CI/CD 파이프라인 실패. 로그를 확인해주세요.'
        }
    }
}
