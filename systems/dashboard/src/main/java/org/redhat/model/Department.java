package org.redhat.model;

import javax.persistence.Cacheable;
import javax.persistence.Entity;
import javax.persistence.NamedQuery;
import javax.persistence.QueryHint;
import javax.persistence.Table;
import javax.persistence.OneToMany;
import javax.persistence.FetchType;
import javax.persistence.CascadeType;
import java.util.Set;
import io.quarkus.hibernate.orm.panache.PanacheEntity;


@Entity
@Table(name="Department")
@NamedQuery(name = "Department.findAll", query = "SELECT t FROM Department t", hints = @QueryHint(name = "org.hibernate.cacheable", value = "true"))
@NamedQuery(name = "Department.findByStatus", query = "SELECT b FROM Department b where status=:status", hints = @QueryHint(name = "org.hibernate.cacheable", value = "true"))
@NamedQuery(name = "Department.findSystemStatusByIds", query = "SELECT b FROM Department b where id in(:ids)", hints = @QueryHint(name = "org.hibernate.cacheable", value = "true"))

@Cacheable
public class Department extends PanacheEntity {
    public static String PROVISIONED = "provisioned";
    public static String DEPRIVED = "deprived";

    public static String NAMESPACE = "ns";
    public static String CLUSTER = "cluster";
    public static String NODES = "odes";
    
    private String name;
    private String description;
    private String status;  // deprived, provisioned

    private String tenantType;  // ns, cluster, nodes, VMs

    private Boolean azure;
    private Boolean dc;
    private Boolean aws;

    private String provider;

    public String getProvider() {
        return provider;
    }

    public void setProvider(String provider) {
        this.provider = provider;
    }
    @OneToMany(mappedBy = "department", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    private Set<App> applications;

    public Set<App> getApplications() {
        return applications;
    }

    public void setApplications(Set<App> applications) {
        this.applications = applications;
    }

    public String getTenantType() {
        return tenantType;
    }

    public void setTenantType(String tenantType) {
        this.tenantType = tenantType;
    }
    
    public Boolean isDc() {
        return dc;
    }

    public void setDc(Boolean dc) {
        this.dc = dc;
    }

    public Boolean isAws() {
        return aws;
    }

    public void setAws(Boolean aws) {
        this.aws = aws;
    }

    public void setAzure(Boolean azure) {
        this.azure = azure;
    }

    public Boolean isAzure() {
        return azure;
    }

    public static Department findByDescription(String description){
        return find("description", description).firstResult();
    }

    public static Department findById(long id){
        return find("id", id).firstResult();
    }

    public String getDescription() {
        return description;
    }
    public void setDescription(String description) {
        this.description = description;
    }
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }
    
    public String getStatus() {
        return status;
    }
    public void setStatus(String status) {
        this.status = status;
    }

    public static Department findByName(String name){
        return find("name", name).firstResult();
    }
}
