pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'homoludensmz/homoludens-backend'
        DOCKER_TAG = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
        DB_URL = credentials('db_url')
        DB_USERNAME = credentials('db_username')
        DB_PASSWORD = credentials('db_password')
        SERVER_PORT = credentials('server_port')
        PROD_SERVER_IP = credentials('prod-server-ip')
    }

    stages {
        stage('CI: Checkout Code') {
            steps {
                echo '🔄 [CI] 코드 체크아웃 단계 시작...'
                git branch: "${env.BRANCH_NAME}", credentialsId: 'homoludens_jenkins_token', url: 'https://github.com/MagazineHomoludens/Backend.git'
            }
        }

        stage('CI: Build Project') {
            steps {
                echo '🔄 [CI] Gradle 빌드 단계 시작...'
                sh 'chmod +x ./gradlew'
                sh './gradlew clean build'
            }
        }

        stage('CI: Build and Push Docker Image') {
            steps {
                echo '🔄 [CI] Docker 이미지 빌드 및 푸시 단계 시작...'
                withCredentials([usernamePassword(credentialsId: 'docker_hub_credentials', usernameVariable: 'DOCKER_HUB_USER', passwordVariable: 'DOCKER_HUB_PASSWORD')]) {
                    sh '''
                    echo $DOCKER_HUB_PASSWORD | docker login -u $DOCKER_HUB_USER --password-stdin
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                    '''
                }
            }
        }

        stage('CD: Deploy to Development Server') {
            when {
                branch 'develop'
            }
            steps {
                echo '🚀 [CD] 개발 서버 배포 시작...'
                sh '''
                docker compose pull backend
                docker compose up -d backend
                '''
            }
        }

        stage('CD: Deploy to Production Server') {
            when {
                branch 'main'
            }
            steps {
                echo '🚀 [CD] 운영 서버 배포 시작...'
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'prod-ssh-key', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER'),
                    usernamePassword(credentialsId: 'docker_hub_credentials', usernameVariable: 'DOCKER_HUB_USER', passwordVariable: 'DOCKER_HUB_PASSWORD')
                ]) {
                    sh '''
                    # 🔑 Docker Hub 로그인 (Jenkins 서버에서 수행)
                    echo $DOCKER_HUB_PASSWORD | docker login -u $DOCKER_HUB_USER --password-stdin

                    # 🚀 SSH로 운영 서버에 접속
                    ssh -i $SSH_KEY $SSH_USER@${PROD_SERVER_IP} << 'ENDSSH'
                    set -e

                    # 📥 docker-compose.yml 다운로드
                    mkdir -p /home/ubuntu/backend
                    cd /home/ubuntu/backend
                    curl -o docker-compose.yml https://raw.githubusercontent.com/MagazineHomoludens/Backend/main/docker-compose-prod.yml

                    # 🐳 환경 변수 설정 및 Docker Compose 실행
                    env DOCKER_TAG="${DOCKER_TAG}" \
                        DB_URL="${DB_URL}" \
                        DB_USERNAME="${DB_USERNAME}" \
                        DB_PASSWORD="${DB_PASSWORD}" \
                        SERVER_PORT="${SERVER_PORT}" \
                        docker compose -f docker-compose.yml pull backend

                    env DOCKER_TAG="${DOCKER_TAG}" \
                        DB_URL="${DB_URL}" \
                        DB_USERNAME="${DB_USERNAME}" \
                        DB_PASSWORD="${DB_PASSWORD}" \
                        SERVER_PORT="${SERVER_PORT}" \
                        docker compose -f docker-compose.yml up -d backend
                    ENDSSH
                    '''
                }
            }
        }

    }

    post {
        success {
            echo '✅ 전체 배포 성공!'
        }
        failure {
            echo '❌ 전체 배포 실패. 로그 확인 필요!'
        }
    }
}
