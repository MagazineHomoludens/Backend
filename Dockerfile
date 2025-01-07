# 1. OpenJDK 기반 이미지 사용
FROM openjdk:17-jdk-slim

# 2. 작업 디렉토리 설정
WORKDIR /app

# 3. JAR 파일 복사
COPY build/libs/*.jar app.jar

# 4. 포트 노출
EXPOSE ${SERVER_PORT}

# 5. 애플리케이션 실행
ENTRYPOINT ["sh", "-c", "java -jar app.jar \
  --spring.datasource.url=${DB_URL} \
  --spring.datasource.username=${DB_USERNAME} \
  --spring.datasource.password=${DB_PASSWORD} \
  --server.port=${SERVER_PORT}"]
