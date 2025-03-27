package org.redhat.services;

import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.rest.client.ext.ClientHeadersFactory;

import javax.enterprise.context.ApplicationScoped;
import javax.ws.rs.core.MultivaluedHashMap;
import javax.ws.rs.core.MultivaluedMap;

@ApplicationScoped
public class RequestHeaderFactory implements ClientHeadersFactory {
    @ConfigProperty(name = "ocp.token" , defaultValue="" )
    String ocptoken;
    
    @Override
    public MultivaluedMap<String, String> update(MultivaluedMap<String, String> incomingHeaders, MultivaluedMap<String, String> clientOutgoingHeaders) {
        MultivaluedMap<String, String> result = new MultivaluedHashMap<>();
        System.out.println(ocptoken);
        result.add("Authorization: Bearer ", ocptoken);
        return result;
    }
}