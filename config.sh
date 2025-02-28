# desktop env, JDK17
#export JAVA_HOME=/usr/local/opt/openjdk@17
export JAVA_HOME=/opt/homebrew/Cellar/openjdk@17/17.0.14/libexec/openjdk.jdk/Contents/Home
export TESTCONTAINERS_RYUK_DISABLED=true

# replace CLUSTER_URL with env url (e.g. cluster-dtvxj.dtvxj.sandbox3050.opentlc.com)
# =====================================================================
export HUB_CLUSTER_URL=cluster-ghw99.ghw99.sandbox2941.opentlc.com
# =====================================================================

# if no argument arguments, print the help
if [[ $# -eq 0 ]] ; then
    echo ' ===================================='
    echo '| use one of the following arguments |'
    echo '| ./config.sh infra                  |'
    echo '| ./config.sh pipeline c             |'
    echo '| ./config.sh pipeline d             |'
    echo ' ===================================='
    exit 0
fi


# /////////////////// Infra ///////////////////////////
# ./config.sh infra

# if infra argument is provided
if [ $1 = "infra" ]
then

# install the operators
oc create ns openshift-gitops-operator
oc label namespace openshift-gitops-operator openshift.io/cluster-monitoring=true

# OpenShift gitops
# BEGIN
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-gitops-operator
  namespace: openshift-gitops-operator
  labels:
    operators.coreos.com/openshift-gitops-operator.openshift-operators: ''
spec:
  channel: latest
  installPlanApproval: manual
  name: openshift-gitops-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-gitops-operator
  namespace: openshift-gitops-operator
spec:
  upgradeStrategy: Default
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: argocd-application-controller-cluster-admin
subjects:
  - kind: ServiceAccount
    name: openshift-gitops-argocd-application-controller
    namespace: openshift-gitops
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
EOF

oc adm groups new cluster-admins
oc adm groups add-users cluster-admins admin
oc adm policy add-cluster-role-to-group cluster-admin cluster-admins
# create following GitOpsCluster and its binding and placement 
oc create -f gitops/placements/argocd-placement.yaml
# END

# OpenShift pipelines
# !!!!! check the issue of tekton CRD objects are created cluster wide
# BEGIN
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-pipelines-operator
  namespace: openshift-operators
spec:
  channel: latest
  installPlanApproval: Automatic
  name: openshift-pipelines-operator-rh
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: openshift-pipelines-operator-rh.v1.17.1
EOF

# END


# hub-ns namespace  
oc new-project hub-ns
# managed by gitops
oc label ns hub-ns argocd.argoproj.io/managed-by=openshift-gitops --overwrite
# assign pipeline sa admin role in openshift-gitops namesapce
oc policy add-role-to-user admin system:serviceaccount:hub-ns:pipeline -n openshift-gitops

# lift pipeline permission up 
# create a new cluster role 
cat <<EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: namespaces-manager
rules:
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["get", "watch", "list", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["managedclusters"]
  verbs: ["get", "watch", "list", "create", "update", "patch", "delete"]
EOF

# assign namespaces-manager role to  pipeline service account 
oc adm policy add-cluster-role-to-user namespaces-manager system:serviceaccount:hub-ns:pipeline
# grant pipeline service account access to manage clusters and cluster-sets
oc adm policy add-cluster-role-to-user open-cluster-management:admin:local-cluster system:serviceaccount:hub-ns:pipeline
oc adm policy add-cluster-role-to-user open-cluster-management:cluster-manager-admin system:serviceaccount:hub-ns:pipeline
oc adm policy add-cluster-role-to-user open-cluster-management:managedclusterset:admin:default system:serviceaccount:hub-ns:pipeline
 
# add cluster-reader role
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:hub-ns:pipeline
# add self-provisioner role
oc adm policy \
    add-cluster-role-to-user self-provisioner \
    system:serviceaccount:hub-ns:pipeline

# install operators
# Start: We usually use web console for this 
# Azure services operator
# Service interconnect

# RHSI: creaet SA account
oc create sa rhsi -n hub-ns
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:hub-ns:rhsi

fi
# enf of if infra argument is provided

# /////////////////// Pipeliens ///////////////////////////
# ./config.sh pipeline

# if pipeline argument is provided
if [ $1 = "pipeline" ]
then

# pipelines
# replace all CLUSTER_URL with HUB_CLUSTER_URL
find gitops/pipelines/ -name "*.yaml" -exec sed -i "s/CLUSTER_URL/${HUB_CLUSTER_URL}/g" {} +
# only for Mac OS
# find gitops/pipelines/ -name "*.yaml" -exec sed -i '' "s/CLUSTER_URL/${HUB_CLUSTER_URL}/g" {} +
# Note: to restore back 
# find gitops/pipelines/ -name "*.yaml" -exec sed -i '' "s/${HUB_CLUSTER_URL}/CLUSTER_URL/g" {} +

# create all pipelines and pipeline custom tasks 
if [ $2 = "c" ]
then
oc apply -k gitops/pipelines
# once pipelines created, we need to expose the evernt listener svc
oc expose svc el-application-event-listener -n hub-ns
oc expose svc el-provisioning-event-listener -n hub-ns
oc expose svc el-azure-event-listener -n hub-ns
# print EL routes
oc get route -n hub-ns | grep el-

fi 

# create all pipelines and pipeline custom tasks 
if [ $2 = "d" ]
then
oc delete -k gitops/pipelines
# delete event listeners routes
oc delete route -n hub-ns -l app.kubernetes.io/managed-by=EventListener
fi 


# create pipelines 
#oc create -f gitops/pipelines/tasks/provision-callback.yaml
#oc create -f gitops/pipelines/tasks/deployment-callback.yaml
#oc create -f gitops/pipelines/provisioning-pipeline.yaml \
#          -f gitops/pipelines/provisioning-pipeline-template.yaml \
#          -f gitops/pipelines/provisioning-pipeline-triggerbinding.yaml \
#          -f gitops/pipelines/provisioning-pipeline-eventlistener.yaml 

#oc create -f gitops/pipelines/application-pipeline.yaml \
#          -f gitops/pipelines/application-pipeline-template.yaml \
#          -f gitops/pipelines/application-pipeline-triggerbinding.yaml \
#          -f gitops/pipelines/application-pipeline-eventlistener.yaml 
# oc create -f gitops/pipelines/azure-native-pipeline.yaml

# update the dashboard-config configmap with route values 
# el-application-event-listener-hub-ns.apps.cluster-sql9s.sql9s.[Base DNS Domain]
# el-azure-event-listener-hub-ns.apps.cluster-sql9s.sql9s.[Base DNS Domain]
# el-provisioning-event-listener-hub-ns.apps.cluster-sql9s.sql9s.[Base DNS Domain]

fi
# end of pipeline arguments





# cluster provisioning 
# ===================
# you need to create env secrets
# you can use base64 online site https://emn178.github.io/online-tools/base64_encode.html
# - update cluster-secrets-list.yaml
# - update cluser-secrets.yaml with the three entries (base64 encoded values)

#oc create -f cluster-secrets.yaml -n hub-ns


# you need to create all placement rule including 
# placement/apps-placement.yaml
# placement/location-placement.yaml

#moved to deploy-apps.sh
#oc create -f gitops/placements/apps-placement.yaml
#oc create -f gitops/placements/location-placement.yaml

# create following GitOpsCluster and its binding and placement 
#oc create -f gitops/placements/argocd-placement.yaml


# create azuer native on DC cluster 
# change requesy : namespace per department oc create pss-azure
#oc new-project azure-native
#oc label ns azure-native argocd.argoproj.io/managed-by=openshift-gitops --overwrite
