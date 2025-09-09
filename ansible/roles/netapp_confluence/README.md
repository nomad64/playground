# **Ansible Role: NetApp Confluence Reporter**

This role gathers volume information from a NetApp ONTAP appliance and creates or updates a Confluence page with the details.

## **How it Works**

The role performs the following actions:

1. Connects to the specified NetApp vServer/SVM.  
2. Gathers details for every volume, including its size and security style.  
3. For each volume, it queries the associated NFS export policy and CIFS share information.  
4. It then connects to the Confluence REST API using the ansible.builtin.uri module.  
5. It first checks if the target page already exists.  
   * If the page exists, it updates it with the new volume data.  
   * If the page does not exist, it creates it under the specified parent page.

This role uses the built-in uri module, so it does **not** require any external Ansible collections like community.general.

## **Variables**

All variables are defined in defaults/main.yml and can be overridden when calling the role.

**NetApp Variables:**

* netapp\_hostname: The hostname or IP of the NetApp appliance.  
* netapp\_username: Username for NetApp authentication.  
* netapp\_password: Password for NetApp authentication.  
* netapp\_vserver: The specific vServer/SVM to query.  
* netapp\_validate\_certs: (boolean) Whether to validate SSL certificates.

**Confluence Variables:**

* confluence\_url: The base URL of your Confluence instance (e.g., https://your-org.atlassian.net).  
* confluence\_user: The email address of the user for Confluence authentication.  
* confluence\_api\_token: The API token generated for the user. **(Do not use the user's password)**.  
* confluence\_space: The key for the Confluence space (e.g., "IT").  
* confluence\_parent\_page: The title of the page under which this new page will be created.  
* confluence\_page\_title: The title for the page that will be created or updated.

## **Example Playbook**

\- name: Update Confluence with NetApp Volume Information  
  hosts: localhost  
  gather\_facts: no  
  roles:  
    \- role: netapp\_confluence\_reporter  
      netapp\_hostname: "prod-netapp-01.example.com"  
      netapp\_vserver: "svm\_finance"  
      confluence\_page\_title: "Production Finance SVM Volume Report"  
      confluence\_parent\_page: "Infrastructure Reports"  
      \# You should use Ansible Vault for secrets  
      confluence\_api\_token: "your\_secret\_token"
