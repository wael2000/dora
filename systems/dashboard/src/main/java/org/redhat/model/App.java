package org.redhat.model;

import javax.persistence.Cacheable;
import javax.persistence.Entity;
import javax.persistence.NamedQuery;
import javax.persistence.QueryHint;
import javax.persistence.Table;
import javax.persistence.ManyToOne;
import io.quarkus.hibernate.orm.panache.PanacheEntity;
import javax.json.bind.annotation.JsonbTransient;

@Entity
@Table(name="Application")
@Cacheable
public class App extends PanacheEntity {

    private String name;
    private String description;
    private Boolean deployed; 

    @ManyToOne
    @JsonbTransient
    private Department department;

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }
    
    public Department getDepartment() {
        return department;
    }

    public void setDepartment(Department department) {
        this.department = department;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public Boolean isDeployed() {
        return deployed;
    }

    public void setDeployed(Boolean deployed) {
        this.deployed = deployed;
    }

    public static App findByName(String name){
        return find("name", name).firstResult();
    }
    
}
