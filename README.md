# Automating-Deployment-VPP

In this repository you can find the Terraform scripts to automate the deployment of VPP inside AWS and Azure. 
Before starting using these scripts you should install Terraform, which could be [found here.](https://www.terraform.io/downloads.html)


Both the scripts deploy the configuration portraited in the file VPP_Scenario.pdf. At a glance, the configuration files create 1 VPC or VNet, to contain the resources, 3 different subnets (one with IPv6 addresses and another one used only for management purposes), route tables, firewalls rules and a virtual machine in which VPP should be deployed. In both cases, in order to get more automation, it is suggested to create a snapshot of the VM with VPP already installed. Every snapshot comes with an unique ID, which could be used inside the proper field of the vm_resource block. Doing this procedure, the VM created will have already VPP installed.   

In case, here you can find the procedures to deploy VPP inside AWS/Azure.

In order to make the scripts work, firstly we suggest to create a folder which will contain the script, and afterwards inside this folder, you should type:

```
terraform init
terraform apply
```

Then the script will ask you in which subnets, not present in the same VPC, you would to send packets. In case you don't need this option, you could comment the variable.


*Warning*: this guide is updated at 19/02/2019. Hence in the meantimes that you are reading this guide, there could have been some changes. 


