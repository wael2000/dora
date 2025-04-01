# desktop env, JDK17
#export JAVA_HOME=/usr/local/opt/openjdk@17
export JAVA_HOME=/opt/homebrew/Cellar/openjdk@17/17.0.14/libexec/openjdk.jdk/Contents/Home
export TESTCONTAINERS_RYUK_DISABLED=true

#export quarkus.container-image.username=
#export quarkus.container-image.password=

#alias oc ~/Documents/openshift/oc

# replace CLUSTER_URL with env url (e.g. cluster-dtvxj.dtvxj.sandbox3050.opentlc.com)
# =====================================================================
export HUB_CLUSTER_URL=
export BASE_DOMAIN=
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
#baseDomain: sandbox2941.opentlc.com
# =====================================================================

clear 

# https://patorjk.com/software/taag/#p=display&h=1&v=1&f=RubiFont&t=Config
# if no argument arguments, print the help
if [[ $# -eq 0 ]] ; then
    echo " ▗▄▄▖ ▗▄▖ ▗▖  ▗▖▗▄▄▄▖▗▄▄▄▖ ▗▄▄▖"
    echo "▐▌   ▐▌ ▐▌▐▛▚▖▐▌▐▌     █  ▐▌   "
    echo "▐▌   ▐▌ ▐▌▐▌ ▝▜▌▐▛▀▀▘  █  ▐▌▝▜▌           _\|/_      "
    echo "▝▚▄▄▖▝▚▄▞▘▐▌  ▐▌▐▌   ▗▄█▄▖▝▚▄▞▘           (o o)      "
    echo '┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━oOO.{-}.OOo━━┓'
    echo '┃ [x] use one of the following arguments            ┃'
    echo '┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫'
    echo '┃  ./config.sh infra             # create infra     ┃'
    echo '┃  ./config.sh aap i             # install aap      ┃'
    echo '┃  ./config.sh aap c             # configure aap    ┃'
    echo '┃  ./config.sh pipeline c        # create pipelines ┃'
    echo '┃  ./config.sh pipeline d        # delete pipelines ┃'
    echo '┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛'
    exit 0
fi


# /////////////////// Infra ///////////////////////////
# ./config.sh infra

# if infra argument is provided
if [ $1 = "infra" ]
then

# add provider=dc lable to local cluster
oc label managedcluster local-cluster provider=dc

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


# cluster as a service settings
# cluster provisioning 
# ===================
# you need to create env secrets
# you can use base64 online site to check https://emn178.github.io/online-tools/base64_encode.html
# - update install-config.yaml
# - update cluster-secrets-list.yaml
# - update cluser-secrets.yaml with the three entries (base64 encoded values)

export CLUSTER_DEFINITION=$(sed -e "s/BASE_DOMAIN/$BASE_DOMAIN/g" gitops/provisioning/cluster/cluster.yaml | base64)
export CLUSTER_SET_DEFINITION=$(cat gitops/provisioning/cluster/cluster-set.yaml | base64)

export INSTALL_CONFIG=$(sed -e "s/BASE_DOMAIN/$BASE_DOMAIN/g" gitops/provisioning/cluster/install-config.yaml | base64)
export SECRETS=$(sed -e "s|INSTALL_CONFIG|$INSTALL_CONFIG|" -e "s|AWS_ACCESS_KEY_ID|$AWS_ACCESS_KEY_ID|" -e "s|AWS_SECRET_ACCESS_KEY|$AWS_SECRET_ACCESS_KEY|" gitops/provisioning/cluster/cluster-secrets-list.yaml | base64)

#create secret/cluster-secrets 
sed -e "s|CLUSTER_DEFINITION|$CLUSTER_DEFINITION|" -e "s|CLUSTER_SET_DEFINITION|$CLUSTER_SET_DEFINITION|" -e "s|SECRETS|$SECRETS|" gitops/provisioning/cluster/cluster-secrets.yaml | oc create -f - -n hub-ns


fi
# enf of if infra argument is provided

# /////////////////// Pipeliens ///////////////////////////
# ./config.sh pipeline

# if pipeline argument is provided
if [ $1 = "pipeline" ]
then

tar -cvzf pipelines.tar.gz gitops/pipelines

# pipelines
# replace all CLUSTER_URL with HUB_CLUSTER_URL
# for Linux, use following
# find gitops/pipelines/ -name "*.yaml" -exec sed -i "s/CLUSTER_URL/${HUB_CLUSTER_URL}/g" {} +
# only for Mac OS
find gitops/pipelines/ -name "*.yaml" -exec sed -i '' "s/CLUSTER_URL/${HUB_CLUSTER_URL}/g" {} +
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
# end of create pipelines

# delete all pipelines and pipeline custom tasks 
if [ $2 = "d" ]
then
oc delete -k gitops/pipelines
# delete event listeners routes
oc delete route -n hub-ns -l app.kubernetes.io/managed-by=EventListener
fi 
# end of delete pipelines

tar -xvzf pipelines.tar.gz -C .
rm pipelines.tar.gz

fi
# end of pipeline arguments


# start AAP Setup
if [[ $1 = "aap" ]] && [[ $2 = "i" ]]
then

oc new-project ansible-automation-platform

# install AAP Operator
cat <<EOF | oc apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  labels:
    openshift.io/cluster-monitoring: "true"
  name: ansible-automation-platform
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: ansible-automation-platform-operator
  namespace: ansible-automation-platform
spec:
  targetNamespaces:
    - ansible-automation-platform
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ansible-automation-platform
  namespace: ansible-automation-platform
spec:
  channel: 'stable-2.5'
  installPlanApproval: Automatic
  name: ansible-automation-platform-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
---
EOF

echo "Check until PHASE Routes --> Succeeded "
oc get csv -n ansible-automation-platform -w

fi


# configure AAP
if [[ $1 = "aap" ]] && [[ $2 = "c" ]]
then

oc project ansible-automation-platform

# Create AnsibleAutomationPlatform CRD instance 
oc apply -f - <<EOF
apiVersion: aap.ansible.com/v1alpha1
kind: AnsibleAutomationPlatform
metadata:
  name: myaap
  namespace: ansible-automation-platform
spec:
  # Platform
  image_pull_policy: IfNotPresent
  # Components
  controller:
    disabled: false
  eda:
    disabled: false
  hub:
    disabled: false
    ## Modify to contain your RWM storage class name
    storage_type: file
    file_storage_storage_class: <your-read-write-many-storage-class>
    file_storage_size: 10Gi

    ## uncomment if using S3 storage for Content pod
    # storage_type: S3
    # object_storage_s3_secret: example-galaxy-object-storage

    ## uncomment if using Azure storage for Content pod
    # storage_type: azure
    # object_storage_azure_secret: azure-secret-name
  lightspeed:
    disabled: true
EOF

oc wait --for=condition=Admitted route/myaap -n ansible-automation-platform --timeout=60s

oc get routes -n ansible-automation-platform

# get admin user password
oc get secret/myaap-admin-password -o jsonpath={.data.password} | base64 --decode

fi

# create azuer native on DC cluster 
# change requesy : namespace per department oc create pss-azure
#oc new-project azure-native
#oc label ns azure-native argocd.argoproj.io/managed-by=openshift-gitops --overwrite
