package org.redhat.ui;

import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;


import io.quarkus.qute.TemplateInstance;
import io.quarkus.qute.Template;
import org.eclipse.microprofile.config.inject.ConfigProperty;


@Path("/")
public class PageResource {
    @Inject
    Template index; 

    
    @ConfigProperty(name = "battalionService.url")
    String compositeURL;

    @GET
    @Produces(MediaType.TEXT_HTML)
    @Path("")
    public TemplateInstance home() {
        return  index.data("composite",compositeURL)
                    .data("username", "wael")
                    .data("email", "email");
    }


    @GET
    @Produces(MediaType.TEXT_HTML)
    @Path("index")
    public TemplateInstance index() {
        return  index.data("composite",compositeURL)
                    .data("username", "wael")
                    .data("email", "email");
    }

}