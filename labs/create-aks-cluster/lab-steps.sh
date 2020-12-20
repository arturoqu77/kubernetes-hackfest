# Start lab
az ad sp create-for-rbac --skip-assignment
# Persist for Later Sessions in Case of Timeout
APPID=ebbd2634-15f2-4a4f-aa88-7fd43f31f79c
echo export APPID=$APPID >> ~/.bashrc
CLIENTSECRET=rQ2JRxfQsYl.HXN~by44PdiU0OtF48Vz0d
echo export CLIENTSECRET=$CLIENTSECRET >> ~/.bashrc

# Create a unique identifier suffix for resources to be created in this lab.
UNIQUE_SUFFIX=$USER$RANDOM
# Remove Underscores and Dashes (Not Allowed in AKS and ACR Names)
UNIQUE_SUFFIX="${UNIQUE_SUFFIX//_}"
UNIQUE_SUFFIX="${UNIQUE_SUFFIX//-}"

# Check Unique Suffix Value (Should be No Underscores or Dashes)
echo $UNIQUE_SUFFIX
# Persist for Later Sessions in Case of Timeout
echo export UNIQUE_SUFFIX=$UNIQUE_SUFFIX >> ~/.bashrc

# Create an Azure Resource Group in Canada Central.
# Set Resource Group Name using the unique suffix
RGNAME=aks-rg-$UNIQUE_SUFFIX
# Persist for Later Sessions in Case of Timeout
echo export RGNAME=$RGNAME >> ~/.bashrc
# Set Region (Location)
LOCATION=canadacentral
# Persist for Later Sessions in Case of Timeout
echo export LOCATION=eastus >> ~/.bashrc
# Create Resource Group
az group create -n $RGNAME -l $LOCATION

# Create cluster
# Set AKS Cluster Name
CLUSTERNAME=aks${UNIQUE_SUFFIX}
# Look at AKS Cluster Name for Future Reference
echo $CLUSTERNAME
# Persist for Later Sessions in Case of Timeout
echo export CLUSTERNAME=aks${UNIQUE_SUFFIX} >> ~/.bashrc
# Get AKS versions for location
az aks get-versions -l $LOCATION --output table
# For this we will use 1.19.3
K8SVERSION=1.19.3
# Create AKS Cluster
az aks create -n $CLUSTERNAME -g $RGNAME \
--kubernetes-version $K8SVERSION \
--service-principal $APPID \
--client-secret $CLIENTSECRET \
--generate-ssh-keys -l $LOCATION \
--node-count 3 \
--no-wait

# Verify your cluster status. The ProvisioningState should be Succeeded
az aks list -o table

# Get credentials
az aks get-credentials -n $CLUSTERNAME -g $RGNAME

# Verify you have API access to your new AKS cluster
# Note: It can take 5 minutes for your nodes to appear and be in READY state. 
# You can run watch kubectl get nodes to monitor status.
kubectl get nodes -o wide
kubectl cluster-info

# Navigate to the directory of the cloned repository
cd kubernetes-hackfest
# Create three namespaces
# Create namespaces
kubectl apply -f labs/create-aks-cluster/create-namespaces.yaml
# Look at namespaces
kubectl get ns

# Assign CPU, memory and storage limits to namespaces
# Create namespace limits
kubectl apply -f labs/create-aks-cluster/namespace-limitranges.yaml

# Assign CPU, Memory and Storage Quotas to Namespaces
# Create namespace quotas
kubectl apply -f labs/create-aks-cluster/namespace-quotas.yaml

# Get list of namespaces and drill into one
kubectl get ns
kubectl describe ns dev

# Test out Limits and Quotas in dev Namespace
# Test Limits - Forbidden due to assignment of CPU too low
kubectl run nginx-limittest --image=nginx --restart=Never --replicas=1 --port=80 --requests='cpu=100m,memory=256Mi' -n dev
# Test Limits - Pass due to automatic assignment within limits via defaults
kubectl run nginx-limittest --image=nginx --restart=Never --replicas=1 --port=80 -n dev
# Check running pod and dev Namespace Allocations
kubectl get po -n dev
kubectl describe ns dev
# Test Quotas - Forbidden due to memory quota exceeded
kubectl run nginx-quotatest --image=nginx --restart=Never --replicas=1 --port=80 --requests='cpu=500m,memory=1Gi' -n dev
# Test Quotas - Pass due to memory within quota
kubectl run nginx-quotatest --image=nginx --restart=Never --replicas=1 --port=80 --requests='cpu=500m,memory=512Mi' -n dev
# Check running pod and dev Namespace Allocations
kubectl get po -n dev
kubectl describe ns dev

# Clean up limits, quotas, pods
kubectl delete -f labs/create-aks-cluster/namespace-limitranges.yaml
kubectl delete -f labs/create-aks-cluster/namespace-quotas.yaml
kubectl delete po nginx-limittest nginx-quotatest -n dev
kubectl describe ns dev
kubectl describe ns uat
kubectl describe ns prod

# Create namespace for our application. This will be used in subsequent labs.
kubectl create ns hackfest
