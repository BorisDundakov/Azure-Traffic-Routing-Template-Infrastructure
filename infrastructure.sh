""" Azure infrastructure:
        - 3 VM's
        - One of the VM's acts a router between the other 2
        - Each of the other VM's is in a separate subnet
        - The idea is that the other 2 VM's can only communicate with each other through the Routing VM
        - The subnets are called 'SubnetA' and 'SubnetB'
        - Routing VM is called 'Router VM', 'VM2' is in 'SubnetA' and 'VM3' is in 'SubnetB'
"""

#0. Setting up the variable names
locationRG=uksouth

nameVM1=RouterVM
nameVM1IP=RouterVMPublicIP
vmNameInSubnetA=VM2
vmNameInSubnetB=VM3

nameRG=UnderstandNetworkingRG
nameVnet=UnderstandNetworkingVNET
nameSubnetA=SubnetA
nameSubnetB=SubnetB

addressVnet=10.0.0.0/16
addressSubnetA=10.0.1.0/24 # the subnet preffix for SubnetA
addressSubnetB=10.0.2.0/24 # possible IP Addresses range: {10.0.2.0 - 10.0.2.255}

VM2VMNIC=10.0.1.4 # Private IP for VM2 located in SubnetA
VM3VMNIC=10.0.2.4 # Private IP for VM3 located in SubnetB

RouterVMNIC=10.0.1.9 #eth0 for Router VM located in SubnetA
RouterVMNIC2=10.0.2.5 #eth1 for Router VM located in SubnetB

adminUsername=boris
adminPassword=boris_pass123@@B

privateDNSZone=www.understandnetworking.com

#1. Create a resourse group in Azure
az group create \
    --location $locationRG \
    --resource-group $nameRG

#2. Create a Virtual Network with 1 Subnet, called 'Subnet A' (Vnet + Subnet)
az network vnet create \
    --resource-group $nameRG \
    --name $nameVnet \
    --address-prefixes $addressVnet \
    --subnet-name $nameSubnetA \
    --subnet-prefixes $addressSubnetA

#3. Create 'Subnet B' and associate it within the same Virtual Network (Subnet)
az network vnet subnet create \
    --resource-group $nameRG \
    --vnet-name $nameVnet \
    --name $nameSubnetB \
    --address-prefix $addressSubnetB


#II. Add a internal DNS for VM

# Extracting the ResourceID for SubnetA and SubnetB
subnetAResourceId=$(az network vnet subnet show --resource-group $nameRG --vnet-name $nameVnet --name $nameSubnetA --query id --output tsv)
subnetBResourceId=$(az network vnet subnet show --resource-group $nameRG --vnet-name $nameVnet --name $nameSubnetB --query id --output tsv)

#4. Creating the VM which will lie in SubnetA
az vm create \
    --resource-group $nameRG \
    --name $vmNameInSubnetA \
    --image Ubuntu2204 \
    --admin-username $adminUsername \
    --admin-password $adminPassword \
    --vnet-address-prefix $$addressVnet \
    --subnet-address-prefix $addressSubnetA \
    --public-ip-address ""  # To prevent the assignment of a public IP


#5. Creating the VM which will lie in SubnetB
az vm create \
    --resource-group $nameRG \
    --name $vmNameInSubnetB \
    --image Ubuntu2204 \
    --admin-username $adminUsername \
    --admin-password $adminPassword \
    --vnet-address-prefix $$addressVnet \
    --subnet $subnetBResourceId \
    --subnet-address-prefix $addressSubnetB \
    --public-ip-address ""  # To prevent the assignment of a public IP


#6. Create 'VM1' that will act as a router
# I have associated eth0(NIC1) for RouterVM to be connected to SubnetA, while eth1(NIC2) for RouterVM will be connected to SubnetB
# 6.1 Create RouterVM with NIC1 in SunbetA
az vm create \
    --resource-group $nameRG \
    --name $nameVM1 \
    --image Ubuntu2204 \
    --admin-username $adminUsername \
    --admin-password $adminPassword \
    --subnet $subnetAResourceId \
    --private-ip-address $RouterVMNIC \
    --public-ip-address ""  # To prevent the assignment of a public IP

# 6.2 Creating NIC2 (eth1) for the router VM (SubnetB)
az network nic create \
   --resource-group $nameRG \
   --name "${nameVM1}NIC2" \
   --vnet-name $nameVnet \
   --subnet $nameSubnetB


#7. Create a DNS record for VM2 and VM3:
#7.1 Create private dns zone
az network private-dns zone create \
    --resource-group $nameRG \
    --name $privateDNSZone

#7.2 Link dns zone to vnet
az network private-dns link vnet create \
    -g $nameRG \
    -n MyDNSLink \
    -z $privateDNSZone \
    -v $nameVnet \
    -e false

#7.3 DNS record for the VM in SubnetA
az network private-dns record-set a add-record \
    -g $nameRG \
    -z $privateDNSZone \
    -n vm2-dns \
    -a $VM2VMNIC


#7.4 Create a DNS record for the VM in SubnetB
az network private-dns record-set a add-record \
    -g $nameRG \
    -z $privateDNSZone \
    -n vm3-dns \
    -a $VM3VMNIC


# 8. NSG's to restrict communication between VM2 and VM3 (happens through RouterVM instead) 
# NSG Rules:
# - Define NSG rules to allow inbound traffic in VM2 and VM3 only from the RouterVM.
# - Deny all other inbound traffic in VM2 and VM3. 
# - Deny outbound traffic to VM2 and VM3 to all sources except RouterVM.


# 8.1 Create NSG rules for VM2:
# A) Allow inbound traffic from RouterVM
az network nsg rule create \
    --resource-group $nameRG \
    --nsg-name VM2NSG \
    --name allow-router-inbound \
    --priority 100 \
    --source-address-prefix $RouterVMNIC \
    --source-port-range '*' \
    --destination-address-prefix '*' \
    --destination-port-range '*' \
    --access Allow \
    --direction Inbound \
    --protocol '*'

# B) Deny outbound traffic to VM3
az network nsg rule create \
    --resource-group $nameRG \
    --nsg-name VM2NSG \
    --name deny-vm3-outbound \
    --priority 200 \
    --source-address-prefix '*' \
    --source-port-range '*' \
    --destination-address-prefix $VM3VMNIC \
    --destination-port-range '*' \
    --access Deny \
    --direction Outbound \
    --protocol '*'

# C) Allow outbound traffic to RouterVM
az network nsg rule create \
    --resource-group $nameRG \
    --nsg-name VM2NSG \
    --name allow-router-outbound \
    --priority 300 \
    --source-address-prefix '*' \
    --source-port-range '*' \
    --destination-address-prefix $RouterVMNIC \
    --destination-port-range '*' \
    --access Allow \
    --direction Outbound \
    --protocol '*'

# D) Deny all other outbound traffic 
az network nsg rule create \
    --resource-group $nameRG \
    --nsg-name VM2NSG \
    --name deny-other-outbound \
    --priority 400 \
    --source-address-prefix '*' \
    --source-port-range '*' \
    --destination-address-prefix '*' \
    --destination-port-range '*' \
    --access Deny \
    --direction Outbound \
    --protocol '*'


# 8.2 Create NSG rules for VM3:
# A) Allow inbound traffic from RouterVM
az network nsg rule create \
    --resource-group $nameRG \
    --nsg-name VM3NSG \
    --name allow-router-inbound \
    --priority 100 \
    --source-address-prefix $RouterVMNIC2 \
    --source-port-range '*' \
    --destination-address-prefix '*' \
    --destination-port-range '*' \
    --access Allow \
    --direction Inbound \
    --protocol '*'

# B) Deny outbound traffic to VM2
az network nsg rule create \
    --resource-group $nameRG \
    --nsg-name VM3NSG \
    --name deny-vm2-outbound \
    --priority 200 \
    --source-address-prefix '*' \
    --source-port-range '*' \
    --destination-address-prefix $VM2VMNIC \
    --destination-port-range '*' \
    --access Deny \
    --direction Outbound \
    --protocol '*'

# C) Allow outbound traffic to RouterVM
az network nsg rule create \
    --resource-group $nameRG \
    --nsg-name VM3NSG \
    --name allow-router-outbound \
    --priority 300 \
    --source-address-prefix '*' \
    --source-port-range '*' \
    --destination-address-prefix $RouterVMNIC2 \
    --destination-port-range '*' \
    --access Allow \
    --direction Outbound \
    --protocol '*'

# extract VM3's NSG name and store it in a variable

# D) Deny all other outbound traffic 
az network nsg rule create \
    --resource-group $nameRG \
    --nsg-name VM3NSG \
    --name deny-other-outbound \
    --priority 400 \
    --source-address-prefix '*' \
    --source-port-range '*' \
    --destination-address-prefix '*' \
    --destination-port-range '*' \
    --access Deny \
    --direction Outbound \
    --protocol '*'


############################################################
# This is how you can ssh from the RouterVM to VM2/VM3:
##  ssh boris@vm3-dns.www.understandnetworking.com ##
############################################################

# 9. Add public IP to RouterVM

# 9.1 Allocate public ip to RouterVM
az network public-ip create \
    --name $nameVM1IP \
    --resource-group $nameRG \
    --allocation-method Static \
    --sku Standard \
    --location $locationRG

# 9.2 Associate it with NIC0
NICRouterVM=$(az vm show -g $nameRG -n $nameVM1 --query 'networkProfile.networkInterfaces[].id' -o tsv | awk -F'/' '{print $NF}')

az network nic ip-config update \
    --name ipconfigRouterVM \
    --nic-name $NICRouterVM \
    --resource-group $nameRG \
    --public-ip-address $nameVM1IP