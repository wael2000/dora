package org.redhat.model;

import jakarta.persistence.Cacheable;
import jakarta.persistence.Table;
import jakarta.persistence.Entity;
import jakarta.persistence.Column;
import io.quarkus.hibernate.orm.panache.PanacheEntity;


 @Entity
 @Table(name="Config")
 @Cacheable
public class Config extends PanacheEntity{
    private String key;
    private String value;
    
    public void setKey(String key) {
        this.key = key;
    }
    public void setValue(String value) {
        this.value = value;
    }
    public String getKey() {
        return key;
    }
    public String getValue() {
        return value;
    }
    
}
