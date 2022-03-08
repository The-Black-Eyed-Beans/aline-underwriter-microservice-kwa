FROM openjdk:11-jre-slim
ARG JAR_FILE=underwriter-microservice/target/*.jar
COPY ${JAR_FILE} app.jar
ENTRYPOINT ["java", "-jar", "/app.jar"]
