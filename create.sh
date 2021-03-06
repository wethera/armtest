#!/bin/bash
set -ex

group="armtest"
location="southcentralus"
tags="Owner=OWNER"

# Create resource group
az group create --name $group --location $location --tags $tags

# Loop througn run directory and execute ARM templates
for dir in rundir/*; do
	az deployment group create --resource-group $group --template-file $dir/azuredeploy.json --parameters $dir/azuredeploy.parameters.json
done