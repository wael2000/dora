./mvnw clean package -Dquarkus.container-image.build=true -DskipTests
oc tag mc-ui:1.0 mc-ui:latest