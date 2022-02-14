FROM openjdk:8-jdk-alpine
ENV APP_HOME=/usr/app/
WORKDIR $APP_HOME
COPY build/*.jar app.jar
CMD ["java","-jar","/app.jar"]
