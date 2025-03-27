package org.redhat;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import jakarta.inject.Inject;
import io.quarkus.qute.TemplateInstance;
import io.quarkus.qute.Template;
import org.eclipse.microprofile.rest.client.inject.RestClient;
import java.util.Map;

@Path("/")
public class PageController {

    @ConfigProperty(name = "api.url")
    String api;

    @Inject
    Template home;

    @Inject
    @RestClient
    APIRestClient apis;

    @GET
    @Produces(MediaType.TEXT_HTML)
    @Path("")
    public TemplateInstance home() {
        return  home.data("view", "grid")
                    .data("username", "Kees")
                    .data("emp", "")
                    .data("email", "email");
    }

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Consumes(MediaType.APPLICATION_JSON)
    @Path("/all")
    public Map<String,Object> all() {
        System.out.println("===================");
        System.out.println(api);
        System.out.println("===================");
        return apis.all();
    }

    
}
