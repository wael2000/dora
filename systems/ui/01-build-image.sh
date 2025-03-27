mvn clean package -Dquarkus.container-image.build=true -DskipTests
oc tag ui:1.0 ui:latest