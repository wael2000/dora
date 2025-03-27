mvn clean package -Dquarkus.container-image.build=true -DskipTests
oc tag apis:1.0 apis:latest