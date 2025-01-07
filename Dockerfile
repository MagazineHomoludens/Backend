# 1. OpenJDK 기반 이미지 사용
FROM openjdk:17-jdk-slim

# 2. 작업 디렉토리 설정
WORKDIR /app

# 3. JAR 파일 복사
COPY build/libs/*.jar app.jar

# 4. 환경 변수 설정 (Secrets 경로)
ENV DB_URL=/run/secrets/db_url
ENV DB_USERNAME=/run/secrets/db_username
ENV DB_PASSWORD=/run/secrets/db_password
ENV SERVER_PORT=/run/secrets/server_port

# 5. 포트 노출
EXPOSE ${SERVER_PORT}

# 6. 애플리케이션 실행
ENTRYPOINT ["sh", "-c", "java -jar app.jar \
  --spring.datasource.url=$(cat $DB_URL) \
  --spring.datasource.username=$(cat $DB_USERNAME) \
  --spring.datasource.password=$(cat $DB_PASSWORD) \
  --server.port=$(cat $SERVER_PORT)"]
