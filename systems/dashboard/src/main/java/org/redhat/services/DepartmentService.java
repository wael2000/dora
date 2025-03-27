package org.redhat.services;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.List;

import javax.enterprise.context.ApplicationScoped;
import javax.inject.Inject;
import javax.persistence.EntityManager;
import javax.transaction.Transactional;

import org.redhat.model.Department;

import org.redhat.model.App;


@ApplicationScoped
public class DepartmentService {
    @Inject
    EntityManager em; 

    public Department[] getAll(){
        return em.createNamedQuery("Department.findAll", Department.class)
                .getResultList().toArray(new Department[0]);
    }

    @Transactional 
    public Department setStatus(Department department){
        Department bat = Department.findById(department.id);
        bat.setStatus(department.getStatus());
        em.persist(bat);
        return bat;
    }

    public Department getByName(String description){
        return Department.findByDescription(description);
    }

    public Department getById(long id){
        return Department.findById(id);
    }

    public Department[] getByStatus(String status){
        return em.createNamedQuery("Banch.findByStatus", Department.class)
                .setParameter("status",status)
                .getResultList().toArray(new Department[0]);
    }

    public List<App> getApps(){
        return App.listAll();
    }

    public Map<Long, Department> findSystemStatusByIds(Set<Long> ids){
        Map<Long, Department> systems = new HashMap<>();
        Department[] departments = em.createNamedQuery("Department.findSystemStatusByIds", Department.class)
                .setParameter("ids",ids)
                .getResultList().toArray(new Department[0]);
        for (int i = 0; i < departments.length; i++) {
            systems.put(departments[i].id,departments[i]);
        }
        return systems ;
    }

    // lifecycle 
    /**
     * default provisioning on DC
     * @param department
     */
    @Transactional
    public Department provision(Map<String,String> data){
        System.out.println(data);
        Department dep = Department.findByName(data.get("name"));
        switch (data.get("action")) {
            case "create":
                System.out.println("create action");
                if("dc".equals(data.get("location"))) dep.setDc(true);
                else 
                if("azure".equals(data.get("location"))) dep.setAzure(true);
                else 
                if("aws".equals(data.get("location"))) dep.setAws(true);
                break;
            case "delete":
                System.out.println("delete action");
                if("dc".equals(data.get("location"))) dep.setDc(false);
                else 
                if("azure".equals(data.get("location"))) dep.setAzure(false);
                else 
                if("aws".equals(data.get("location"))) dep.setAws(false);
                break;
            default:
                break;
        }
        if(!dep.isAws() && !dep.isAzure() && !dep.isDc()){
            System.out.println("tatus DEPRIVED");
            dep.setStatus(Department.DEPRIVED);
        }
        else {
            System.out.println("tatus PROVISIONED");
            dep.setStatus(Department.PROVISIONED);
        }
        em.persist(dep);
        return dep;
    }

        /**
     * deploy App
     * @param app
     */
    @Transactional
    public App deploy(App app){
        App object = App.findByName(app.getName().toUpperCase());
        object.setDeployed(app.isDeployed());
        em.persist(object);
        return object;
    }

    /**
     * scale on public cloud
     * @param scaler
     * @param department
     */
    @Transactional
    public Department scale(Department department){
        Department dep = Department.findById(department.id);
        dep.setStatus(Department.PROVISIONED);
        if(department.getProvider().equals("azure"))
            dep.setAzure(true);
        else if(department.getProvider().equals("aws"))
            dep.setAws(true);
        em.persist(dep);
        return dep;
    }

/**
     * scale on public cloud
     * @param scaler
     * @param department
     */
    @Transactional
    public Department scaleTrigger(Department department){
        Department dep = Department.findById(department.id);
        // trigger the pipeline         
        return dep;
    }


    @Transactional 
    public Department deployOnAzure(String description){
        Department branch = Department.findByDescription(description);
        branch.setAzure(true);
        em.persist(branch);
        return branch;
    }

    
}
