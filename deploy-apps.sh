# replace CLUSTER_URL with env url (e.g. cluster-dtvxj.dtvxj.sandbox3050.opentlc.com)
# =====================================================================
export HUB_CLUSTER_URL=cluster-64mtg.64mtg.sandbox2461.opentlc.com
# =====================================================================

# create placement objects if not created
oc create -f gitops/placements/apps-placement.yaml
oc create -f gitops/placements/location-placement.yaml
oc create -f gitops/placements/baremetal-placement.yaml

oc project hub-ns
# create hub-apis sa and generate token with cluster-admin role
oc create sa hub-apis
# create token valid for 10days
#oc create token hub-apis --duration 14400m
export TOKEN=$(oc create token hub-apis --duration 14400m)
# add -w 0 to base64 to avoid line breakers
export BASE64_TOKEN=$(echo -n $TOKEN | base64 -w 0)

# a secret will be created with the token that can be used fot he API calls (hub-apis-token-XXXXX)
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:hub-ns:hub-apis
# curl -k -H "Authorization: Bearer TOOKEN" "https://api.cluster-sql9s.sql9s.[Base DNS Domain]:6443/apis/policy.open-cluster-management.io/v1/namespaces/openshift-gitops/policies/hub-ns"

# create hub-apis-token secret
cat <<EOF | oc apply -f -
kind: Secret
apiVersion: v1
metadata:
  name: hub-apis-token
  namespace: hub-ns
data:
  token: $BASE64_TOKEN
type: Opaque
EOF


# create application confog map with HUB_CLUSTER_URL
cat <<EOF | oc apply -f -
kind: ConfigMap
apiVersion: v1
metadata:
  name: dashboard-config
data:
  pipeline.el: http://el-provisioning-event-listener-hub-ns.apps.${HUB_CLUSTER_URL}
  ops.pipeline.el: http://el-application-event-listener-hub-ns.apps.${HUB_CLUSTER_URL}
  azure.pipeline.el: http://el-azure-event-listener-hub-ns.apps.${HUB_CLUSTER_URL}
  build.pipeline.el: http://dummy
  department.url: dashboard-hub-ns.apps.${HUB_CLUSTER_URL}
  policy.url: https://api.${HUB_CLUSTER_URL}:6443/apis/policy.open-cluster-management.io/v1/namespaces/openshift-gitops/policies
EOF


# deploy dashboard app
oc create -f gitops/dashboard-applicationset.yaml -n openshift-gitops

# delete 
#oc delete  -f dashboard-applicationset.yaml -n openshift-gitops
