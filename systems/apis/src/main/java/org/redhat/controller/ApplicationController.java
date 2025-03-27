package org.redhat.controller;

import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.redhat.model.App;
import org.redhat.model.Config;

@Path("/system")
public class ApplicationController {
    @ConfigProperty(name = "department" , defaultValue="1" )
    String department;

    @ConfigProperty(name = "location" , defaultValue="DC" )
    String location;

    @ConfigProperty(name = "system" , defaultValue="RTGS" )
    String system;

    @GET
    @Path("/equipment")
    @Produces(MediaType.APPLICATION_JSON)
    public List<App> equipment() {
        return App.find("name=?1",system).list();
    }

    @GET
    @Path("/info")
    @Produces(MediaType.APPLICATION_JSON)
    public Map<String,String> location() {
        Map<String,String> map = new HashMap<>();
        map.put("location",location);
        map.put("system",system);
        return map;
    }

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Map<String,Object> all() {
        Map<String,Object> map = new HashMap<>();
        Config config = Config.find("key", "dblocation").firstResult();
        map.put("dblocation",config!=null?config.getValue():"");
        map.put("apilocation",location);
        map.put("system",system);
        map.put("department",department);
        map.put("apps", App.find("name=?1",system).list());
        return map;
    }
  
}
