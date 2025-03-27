package org.redhat.services;

import javax.ws.rs.GET;
import javax.ws.rs.HeaderParam;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.Consumes;

import org.eclipse.microprofile.rest.client.annotation.ClientHeaderParam;
import org.eclipse.microprofile.rest.client.annotation.RegisterClientHeaders;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

@Path("/")
@RegisterRestClient
//@RegisterClientHeaders(RequestHeaderFactory.class)
@RegisterClientHeaders
public interface PolicyProxyService {
    
     /**
     * 
     * @return
     */
    @GET
    @Path("/")
    @Produces("application/json")
    @Consumes("application/json")
    @ClientHeaderParam(name = "header-from-method-param", value = "Bearer {token}")
    Object getPolicies();

    @GET
    @Path("/")
    @Produces("application/json")
    @Consumes("application/json")
    @ClientHeaderParam(name = "header-from-method-param", value = "Bearer {token}")
    Object getPolicies1(@HeaderParam("Authorization") String token);

    
}