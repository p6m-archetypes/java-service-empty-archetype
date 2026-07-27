# prd/Dockerfile — used for CI/CD production builds
# Builder stage
# A pinned Maven+JDK image rather than the project's ./mvnw: this overlay retrofits an EXISTING
# application and cannot assume it carries the wrapper, and the pinned image keeps the toolchain
# reproducible either way. Matches what the java service archetypes build with.
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /workspace

COPY . .
RUN mvn -q -B -pl {{ project-name }}-server -am -DskipTests package

# Runtime stage
FROM eclipse-temurin:21-jre-alpine AS runtime
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app

COPY --from=builder /workspace/{{ project-name }}-server/target/*.jar app.jar

USER appuser
EXPOSE {{ service_port }} {{ management_port }}
ENTRYPOINT ["java", "-jar", "app.jar"]
