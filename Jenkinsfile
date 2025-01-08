pipeline {
    agent any

    environment {
        DB_URL = credentials('db_url')
        DB_USERNAME = credentials('db_username')
        DB_PASSWORD = credentials('db_password')
        SERVER_PORT = credentials('server_port')
        PROD_SERVER_IP = credentials('prod-server-ip') // Credentials로 IP 참조
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
                docker compose down || true
                docker compose build
                '''
            }
        }

        stage('CD: Deploy to Production Server') {
            when {
                branch 'main'
            }
            steps {
                echo '🚀 [CD] 운영 서버 배포 시작...'
                withCredentials([sshUserPrivateKey(credentialsId: 'prod-ssh-key', keyFileVariable: 'SSH_KEY')]) {
                    sh '''
                    ssh -o StrictHostKeyChecking=no -i $SSH_KEY ubuntu@${PROD_SERVER_IP} << 'EOF'
                        cd /path/to/project
                        git pull origin main
                        docker compose down || true
                        docker compose build
                        docker compose up -d
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
