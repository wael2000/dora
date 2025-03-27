package org.redhat.services;


import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.Consumes;

import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

@Path("/")
@RegisterRestClient
public interface OpsPipelineProxyService {
   
    /**
     * 
     * @param application
     * @return
     */
    @POST
    @Path("/")
    @Produces("application/json")
    @Consumes("application/json")
    Object deploy(Object application);


}
