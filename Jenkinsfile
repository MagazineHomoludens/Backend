pipeline {
    agent any

    environment {
        // 공통 환경 변수
        DB_URL = credentials('db_url')
        DB_USERNAME = credentials('db_username')
        DB_PASSWORD = credentials('db_password')
        SERVER_PORT = credentials('server_port')

        // 운영 서버 환경 변수
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
                sh './gradlew build'
            }
        }

        stage('CI: Build Docker Image') {
            steps {
                echo '🔄 [CI] Docker 이미지 빌드 단계 시작...'
                sh '''
                docker-compose down || true
                docker-compose build
                '''
            }
        }

        stage('CD: Deploy to Development Server') {
            when {
                branch 'develop'
            }
            steps {
                echo '🚀 [CD] 개발 서버(로컬) 배포 시작...'
                sh '''
                echo "[CD] Docker Compose Down (If Running)"
                docker-compose down || true

                echo "[CD] Docker Compose Up"
                docker-compose up -d
                '''
            }
        }

        stage('CD: Deploy to Production Server') {
            when {
                branch 'main'
            }
            steps {
                echo '🚀 [CD] 운영 서버 배포 시작...'
                withCredentials([sshUserPrivateKey(credentialsId: 'prod-ssh-key', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    sh '''
                    ssh -o StrictHostKeyChecking=no -i $SSH_KEY $SSH_USER@${PROD_SERVER_IP} << 'EOF'
                        cd /home/ubuntu/production
                        git pull origin main
                        docker-compose down || true
                        docker-compose build
                        docker-compose up -d
                    EOF
                    '''
                }
            }
        }

        stage('CD: Verify Deployment') {
            steps {
                echo '🔍 [CD] 배포 검증 단계 시작...'
                sh '''
                echo "[CD] Running docker ps to verify containers..."
                docker ps
                '''
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
