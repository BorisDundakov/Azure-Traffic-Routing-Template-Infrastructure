<h1>Azure Traffic Routing Template Infrastructure</h1>

An introductionary project to Azure that I created with the help of some reddit suggestions. The project includes the following components:

    - Virtual Network (VNET)
    - Virtual Machines (VMs)
    - Network Security Group (NSG) Rules
    - Subnets
    - Public IP Address
    - Virtual Network Interfaces (VNICS)

One of the VMs serves as a router between the other two, called _RouterVM_. Each of the remaining VMs is in its own separate subnet. The idea is that the two non-routing VMs can only communicate through the Routing VM. NSG Rules are established to restrict any other traffic communication.

The Routing VM has two network interface cards: one for talking to VM2 in SubnetA and the other for talking to VM3 in SubnetB.

<h1> I. Project Infrastructure </h3>

<h3> Project Schema </h3>

![Project Schema](https://github.com/BorisDundakov/amazon/assets/71731579/a4ea08ab-f514-43e0-9e94-801f1bcc22c0)

The Azure topology diagrams provide a visual representation of the configured VNET, Subnets, and associated components such as Public IP Addresses and VNICS for each VM.

![VNET](https://github.com/BorisDundakov/OneLiner/assets/71731579/0cd59868-131d-4721-82ca-a7c389376c2d)

![SubnetA](https://github.com/BorisDundakov/OneLiner/assets/71731579/43d43034-f83d-43a9-af17-147edf18f8b7)

![SubnetB](https://github.com/BorisDundakov/OneLiner/assets/71731579/4735c170-b3fa-4899-ba8d-362708fd85e0)

![RouterVMNic](https://github.com/BorisDundakov/OneLiner/assets/71731579/31c6c4f5-8c80-47fa-bfa1-bb199b875baa)

![RouterVMNic2](https://github.com/BorisDundakov/OneLiner/assets/71731579/f8b193a5-f9d6-4353-811a-3f743d33327a)

![VM2VMNic](https://github.com/BorisDundakov/OneLiner/assets/71731579/6803aa85-71e2-4377-b64f-765bacbabcc7)

![VM3VMNIC](https://github.com/BorisDundakov/OneLiner/assets/71731579/e58ef4e5-4a7a-4051-bf35-ccdcc3237712)


<h3> IV. SSH tests via the terminal </h3>

The SSH tests demonstrate connectivity between different VMs using terminal commands.

![sshRouterVM](https://github.com/BorisDundakov/OneLiner/assets/71731579/545834c1-2c32-41d9-b99d-dbb6788c2eab)

![sshVM3](https://github.com/BorisDundakov/OneLiner/assets/71731579/a772ca58-fd8f-4499-8284-46f9dad8a286)

<h3> III. How to SSH via a DNS Name </h3>
The provided script sets up DNS names for VM2 and VM3. VM3's DNS name <i>(vm3-dns)</i> resides in the <i>www.understandnetworking.com</i> private DNS Zone. This allows connection from RouterVM to VM3 using the private DNS Zone address and VM3's DNS Name.

![sshDNSName](https://github.com/BorisDundakov/OneLiner/assets/71731579/9e53ac28-fd3b-48f7-8292-8e0eccb1ed2d)

<h3> IV. Tips </h3>
1. Remember to change the name and password of your VMs; the credentials in the script are just for demonstration. <br>
2. For RDP and SSH access to RouterVM without exposing it through a public IP, consider using Azure Bastion.
