
# Build stage
FROM maven:3.6.3-jdk-8-slim AS builder

WORKDIR /app

# Copiar pom.xml y descargar dependencias
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copiar el código fuente
COPY src ./src

# Compilar la aplicación (omitiendo tests)
RUN mvn clean package -DskipTests

# Runtime stage
FROM openjdk:8-jre-slim

WORKDIR /app

# Copiar el JAR desde la etapa de build
COPY --from=builder /app/target/users-api-*.jar app.jar

# Exponer puerto
EXPOSE 8083

# Variables de entorno por defecto
ENV SERVER_PORT=8083
ENV JWT_SECRET=myfancysecret

# Ejecutar la aplicación
ENTRYPOINT ["java", "-jar", "app.jar"]
