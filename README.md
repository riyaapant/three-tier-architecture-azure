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


## 🚀 Deploy this architecture
### Prerequisites:
1. Install Azure CLI or use Azure Cloud Shell
2. Obtain necessary permissions to deploy and manage resources in a subscription
### 1. Create a resource group
``` bash
az group create --name myResourceGroup --location westeurope
```
### 2. Deploy the Bicep file

```bash
az deployment group create \
  --resource-group myResourceGroup \
  --template-file main.bicep \
  --parameters adminPassword='<YourSecurePassword>'
```
## 📈 Future Improvements
- Add Application Gateway or Azure Front Door for Web Firewall and CDN properties

- Include monitoring with Azure Monitor and Log Analytics

- Enable auto-scaling for the web/app tier VMs
