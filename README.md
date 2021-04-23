# ARM-deployed Test Environment 
Deploys a test environment including VNET, Azure NetApp Files (ANF) , Azure CycleCloud (CC) and infrastructure VM's into a subscription using a script-executed set of Azure Resource Manager (ARM) templates.

## Introduction
- This repo contains several ARM templates for deploying various resources into Azure
- The **01-net** template deploys a VNET in the "10.0.0.0/20" address space with 5 separate subnets:

  1. `infra`: A 10.0.1.0/26 subnet for infrastructure components
  2. `login`: An optional 10.0.1.64/26 subnet for login serve use
  3. `anf`: A 10.0.1.128/27 subnet for deployng Azure Netapp Files access
  4. `compute`: A 10.0.2.0/23 subnet for deploying compute nodes
  5. `viz`: A 10.0.4.0/24 subnet for deploying visualization workstations

- The **02-cycle** template deploys an Azure CycleCloud server and storage account using the `infra` subnet.
- The **03-anf** template deploys a NetApp account with a 4TB storage pool. The pool "pool1" contains a 1TB "vol1" volume and a 3TB "vol2" volume, both configured for NFS access, in the `anf` subnet.
- the **04-infra-vm** configures a small infrastructure linux VM runing CentOS 7.8, also in the `infra` subnet.

## Pre-requisites
1. Service Principal for CycleCloud
    - Azure CycleCloud requires a service principal with contributor access to your Azure subscription. 

    - The simplest way to create one is using the [Azure CLI in Cloud Shell](https://shell.azure.com), which is already configured with your Azure subscription:
        ```
        $ az ad sp create-for-rbac --name CycleCloudApp --years 1
        {
                "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
                "displayName": "CycleCloudApp",
                "name": "http://CycleCloudApp",
                "password": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
                "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
        }
        ```
        - Save the output -- you'll need the `appId`, `secret/password` and `tenantId`. 

    - Alternatively, follow these [instructions to create a Service Principal](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal) 
        -  In this case, the authentication key is the `password`

2. SSH key

    - An SSH key is needed to log into the CycleCloud VM, clusters and Infrastructure VM's
    - Specify a SSH public key, and that will be used in all VM's. 
    - See [section below](#trouble-with-ssh) for instructions on creating an SSH key if you do not have one.

3. Azure NetApp Files whitelist and RP Registration

Deploying ANF resources currently requires a whitelisting and registration process, outlined below:
[Azure NetApp Files Whitelist and Registration](https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-register)

## Deploy the ARM templates
* Clone this repo:

        $ git clone https://github.com/wethera/armtest.git

* Edit and update the parameters in the `azuredeploy.parameters.json` files for all sub-directories in the `rundir` directory. This includes changing the names of the variables to conform to your specific naming and network scheme, as well as adding the service principal fields noted in the steps above.

* Run the deployment script to walk through all ARM templates and deploy them - This process takes between 10-15 mins:

        $ chmod +x rundir.sh
        $ ./rundir.sh

## Login to the CycleCloud application server
* To connect to the CycleCloud webserver, first retrieve the IP of the CycleServer VM from the Azure Portal, then browse to https://cycleserverIP/. 

* The first time you access the webserver, the Azure CycleCloud End User License Agreement will be displayed, and you will be prompted to accept it.

* After that, you will be prompted to create an admin user for the application server. For convenience, it is recommended that you use the same username specified in the parameters. 

![createuser](images/cyclecloud-create-user.png)


## Initialize the CycleCloud CLI
* The CycleCloud CLI is required for importing custom cluster templates and projects, and is installed in the **Azure CycleCLoud** VM. 
* To use the CLI, SSH into the VM with the private key that matches the public key supplied in the parameter file. The SSH user is username specified in the parameters.

* Once on the CycleCloud server, initialize the CycleCloud CLI. The username and password are the ones you created and entered in the web UI in the section above.

        $ cyclecloud initialize --batch --url=https://localhost --verify-ssl=false --username=${USERNAME} --password=${PASSWORD}

* Test the CycleCloud CLI

        $ cyclecloud locker list

* The CycleCloud CLI should also be installed (preferably) on a separate administrative machine for ease of template editing and management.

[How to install the CycleCloud CLI](https://docs.microsoft.com/en-us/azure/cyclecloud/how-to/install-cyclecloud-cli?view=cyclecloud-8)


## Trouble with SSH
- Both Bash and Powershell variants of the Azure Cloud Shell have the SSH client tools installed.
- To generate an ssh-key:
![ssh-keygen](images/powershell-ssh-keygen.png)

- To obtain the public key of the generated key, run the following command and copy the output:

        PS Azure:\> cat ~/.ssh/id_rsa.pub

- You may also SSH into the VM from Cloud Shell:

       PS Azure:\> ssh username@cyclecloud.fqdn 
