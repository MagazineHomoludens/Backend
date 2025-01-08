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
                    docker compose build  # docker compose를 사용해 이미지 빌드
                    docker compose push  # 이미지를 Docker Hub로 푸시
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
                docker compose pull  # 이미지를 Docker Hub에서 가져오기
                docker compose up -d  # 컨테이너 실행
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
                    ssh -T -i $SSH_KEY $SSH_USER@${PROD_SERVER_IP} <<EOF
                    echo $DOCKER_HUB_PASSWORD | docker login -u $DOCKER_HUB_USER --password-stdin
                    docker compose pull # 이미지를 Docker Hub에서 가져오기
                    docker compose up -d # 컨테이너 실행
                    EOF
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
