# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
This Project is to create a webserver framwork using the packer image and terraform file to make it easy and quick to deploy.

### Getting Started
1. Clone this repository

2. Create your infrastructure as code

3. Update this README to reflect how someone would use your code.

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
Please get the access credentials to the Azure Portal and Subscription.
Install the Packer, Azure-Cli and Terraform on the machine you want to deploy this script from. 

### Creating the Image
Step 1. 
Please export your SubcriptionID, ClientID and ClientSecret to the environment. 
Step 2. 
Run Azure-CLI to get login setup done.
    az login 
Follow the onscreen instruction to login via web browser. 
Step 3. 
Run the packer to create the base image. 
    packer build server.json
Once if the packer has created the image, verify the same in the resource group at portal.

### Creating the infrastructure
Now that the image is ready with webserver, we can now run the terraform code to create the infrastructure. 
Step 1
Download the terraform code from the repository. 
Step 2
Run
terraform init
This will initialize the environment using the registry. 
Step 3
Run
terraform plan
This will list all the resources that are going to be created. 
(Note: You have import the AzureDevops resource group as it is already their in the subscription)
Step 4
Run 
terraform apply
This will again list the resources to be created and please provide yes after verifying all the resources.
Step 5
Once the resource is created check the health probe in the Loadbalancer and verify if the webserver are online. 
(hint: you can set the vm_count variable to increase the webserver in the backendpool)
Step 6
Once your verified the working of the index.html please run the following command to destroy the resources.
terraform destroy
### Output
The packer part did had some issues and i went through the slack channel discussion to get a solution.
The terraform LB configuration took me some time to configure the dynamic backend pool, but again i visited the slack channel and got some idea from the stackoverflow. 


