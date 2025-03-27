./mvnw clean package -Dquarkus.container-image.build=true -Dquarkus.container-image.builder=s2i -DskipTests
oc tag dashboard:1.0 dashboard:latest