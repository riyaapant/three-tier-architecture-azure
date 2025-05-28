# Azure 3-Tier Web Application Architecture

This project implements a classic **3-tier architecture** for a web application using **Azure Bicep**. The infrastructure is fully deployable and includes network isolation, a public load balancer, virtual machines, a managed MySQL database, and backup configuration using a Recovery Services Vault.

![image](https://github.com/user-attachments/assets/dcb05b8a-484a-4daa-9f33-b376878136a0)


---

## 🧱 Architecture Overview

This solution separates the application into three logical tiers:


Client (Browser) --> Web tier (Frontend) --> Application Tier (Backend APIs) --> Database Tier

### 🔹 Tiers Breakdown:

### 1. Web Tier
- Two Windows VMs behind an **External Load Balancer**
- Public access through the Load Balancer IP
- Outbound traffic via **NAT Gateway**

### 2. Application Tier
- Two VMs in an internal subnet
- Uses an **Internal Load Balancer** for communication from Web Tier

### 3. Data Tier
- **Azure Database for MySQL** hosted in a private subnet
- Accessed within virtual network via **Private Link** only

### Additional Services
- **Azure Bastion Host** to connect to all VMs through secure RDP/SSH for management purposes
- **Recovery Services Vault** for backups of all VMs

## 📌 Key Features

### 1. Separation of Concerns  
Three tiers (Web, Application, Data) in separate subnets for easier maintenance and independent scaling.

### 2. Enhanced Security  
Internal tiers are isolated within the VNet; only the Web tier is exposed via a public load balancer.

### 3. Scalability and Availability  
Load balancers distribute traffic evenly; more VMs can be added for horizontal scaling.

### 4. Secure Outbound Connectivity  
NAT gateway provides secure, consistent outbound internet access without exposing VMs’ public IPs.

### 5. Managed Database with Private Link  
MySQL Flexible Server uses VNet integration with private access for secure database connectivity.

### 6. Backup and Disaster Recovery  
VMs are backed up via Recovery Services Vault for data protection and recovery.


## 🚀 Deploy this architecture (Az PowerShell)
### Prerequisites:
1. Install Azure PowerShell
2. Obtain necessary permissions to deploy and manage resources in a subscription
### 1. Connect your Az Account
```bash
Connect-AzAccount
```
### 2. Set Az Context
```bash
$context = Get-AzSubscription -SubscriptionName <your subscription name>
Set-AzContext $context
```
### 3. Create a resource group and set default resource group
```bash
New-AzResourceGroup -Name bicep -Location swedencentral
Set-AzDefault -ResourceGroupName bicep
```
### 4. Deploy the resources
```bash
New-AzResourceGroupDeployment -name main -TemplateFile main.bicep
```
You will be prompted to enter values for serverAdminLogin and serverAdminPassword
## 🚀 Deploy this architecture (Azure CLI)
### 1. Create a resource group
```bash
az group create --name bicep --location swedencentral
```
### 2. Deploy the Bicep file

```bash
az deployment group create \
  --resource-group bicep \
  --template-file main.bicep \
```
## Test
I also added some scripts in each virtual machines to test that I can access all tiers from outside the network.
### Script for web tier vm
```bash
#!/bin/bash
sudo apt-get update
sudo apt-get install -y apache2 curl

sudo rm -f /var/www/html/index.html

{
echo "<html><body>Hello world from $(hostname)</body></html>"
curl -s 10.0.2.10
} | sudo tee /var/www/html/index.html

sudo systemctl restart apache2
```
### Script for app tier vm
```bash

#!/bin/bash
sudo apt-get update
sudo apt-get install -y apache2 mysql-client

DB_HOST=',your-db-server-name>.privatelink.mysql.database.azure.com'
DB_USER=<username>
DB_PASS=<password>
DB_NAME=<database-name>
DB_QUERY='SELECT * FROM <table-name> LIMIT 5;'

sudo rm -f /var/www/html/index.html

{
  echo "<html><body>"
  echo "<h2>Hello World from $(hostname)</h2>"
  echo "<h3>Database Results:</h3>"
  echo "<pre>"
  mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "$DB_QUERY"
  echo "</pre>"
  echo "</body></html>"
} | sudo tee /var/www/html/index.html > /dev/null

sudo systemctl restart apache2
```
## Prepare the database
Access the database from any of your vms withing the vnet like this:
```bash
mysql -h <your-db-server-name>.privatelink.mysql.database.azure.com -u <serverAdminLogin> -p
```
Then create a test database, table and add some records.

## How to run and test
### 1. Create a file script.sh in each vm and add the script according to the tier
### 2. Make the script executable
```bash
chmod +x script.sh
```
### 3. Run the script
```bash
./script.sh
```
### 4. Access the web tier
Open a browser and navigate to the public IP address of the External Load Balancer (for the Web Tier). You should see a simple web page showing a "Hello world" message from the Web VM. The Web Tier page will call the Application Tier VM's internal IP, which in turn queries the MySQL Flexible Server. You should see database query results displayed on the Web Tier web page if everything is connected correctly.

## Finally
- Ensure that you cannot access the vms from outside the vnet since they don't have a public IP address
- Ensure that you cannot access the database server from outside the vnet

## 📈 Future Improvements
- Add Application Gateway or Azure Front Door for Web Firewall and CDN properties

- Include monitoring with Azure Monitor and Log Analytics

- Enable auto-scaling for the web/app tier VMs
