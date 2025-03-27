package org.redhat.model;

import javax.persistence.Cacheable;
import javax.persistence.Table;
import javax.persistence.Entity;
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
