#!/bin/bash
# Quick reference commands for Spring PetClinic Docker operations

# Build the Docker image
build() {
    echo "Building Spring PetClinic Docker image..."
    docker build -t spring-petclinic:4.0.0-SNAPSHOT .
}

# Run with H2 (in-memory database)
run_h2() {
    echo "Running Spring PetClinic with H2 database..."
    docker run -d -p 8080:8080 --name petclinic spring-petclinic:4.0.0-SNAPSHOT
    echo "Application available at http://localhost:8080"
}

# Run with MySQL
run_mysql() {
    echo "Running Spring PetClinic with MySQL..."
    docker run -d -p 8080:8080 \
        -e SPRING_PROFILES_ACTIVE=mysql \
        -e MYSQL_URL="${MYSQL_URL:-jdbc:mysql://localhost/petclinic}" \
        -e MYSQL_USER="${MYSQL_USER:-petclinic}" \
        -e MYSQL_PASS="${MYSQL_PASS:-petclinic}" \
        --name petclinic \
        spring-petclinic:4.0.0-SNAPSHOT
    echo "Application available at http://localhost:8080"
}

# Run with PostgreSQL
run_postgres() {
    echo "Running Spring PetClinic with PostgreSQL..."
    docker run -d -p 8080:8080 \
        -e SPRING_PROFILES_ACTIVE=postgres \
        -e POSTGRES_URL="${POSTGRES_URL:-jdbc:postgresql://localhost/petclinic}" \
        -e POSTGRES_USER="${POSTGRES_USER:-petclinic}" \
        --name petclinic \
        spring-petclinic:4.0.0-SNAPSHOT
    echo "Application available at http://localhost:8080"
}

# Stop and remove container
stop() {
    echo "Stopping Spring PetClinic container..."
    docker stop petclinic
    docker rm petclinic
}

# View logs
logs() {
    docker logs -f petclinic
}

# Check health
health() {
    echo "Container health status:"
    docker inspect --format='{{.State.Health.Status}}' petclinic
    echo ""
    echo "Actuator health endpoint:"
    curl -s http://localhost:8080/actuator/health | jq
}

# Show image info
info() {
    echo "Docker image information:"
    docker images spring-petclinic:4.0.0-SNAPSHOT
    echo ""
    echo "Image layers:"
    docker history spring-petclinic:4.0.0-SNAPSHOT
}

# Show usage
usage() {
    echo "Spring PetClinic Docker Helper"
    echo "=============================="
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  build         - Build the Docker image"
    echo "  run_h2        - Run with H2 database (default)"
    echo "  run_mysql     - Run with MySQL database"
    echo "  run_postgres  - Run with PostgreSQL database"
    echo "  stop          - Stop and remove container"
    echo "  logs          - View container logs"
    echo "  health        - Check container health"
    echo "  info          - Show image information"
    echo ""
    echo "Examples:"
    echo "  $0 build"
    echo "  $0 run_h2"
    echo "  MYSQL_URL=jdbc:mysql://myhost/petclinic $0 run_mysql"
}

# Main
case "$1" in
    build)
        build
        ;;
    run_h2)
        run_h2
        ;;
    run_mysql)
        run_mysql
        ;;
    run_postgres)
        run_postgres
        ;;
    stop)
        stop
        ;;
    logs)
        logs
        ;;
    health)
        health
        ;;
    info)
        info
        ;;
    *)
        usage
        exit 1
        ;;
esac
