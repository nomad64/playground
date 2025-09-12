# **Ansible Role: Confluence Page Management**

This role provides a set of tasks to interact with the Atlassian Confluence REST API for creating, reading, updating, and deleting pages.

## **Requirements**

* Access to a Confluence Cloud or Confluence Server instance.  
* An API token for authentication. For Confluence Cloud, you can generate one from your Atlassian account settings.

## **Role Variables**

The role's behavior is controlled by the following variables.

### **Connection and Authentication**

These variables must be defined for the role to connect to your Confluence instance.

| Variable | Description | Default |
| :---- | :---- | :---- |
| confluence\_api\_url | The base URL for the Confluence REST API. | https://your-instance.atlassian.net/wiki/rest/api |
| confluence\_api\_user | The email address associated with your Confluence account. | '' |
| confluence\_api\_token | The API token for authentication. **Should be secured with Ansible Vault.** | '' |
| confluence\_validate\_certs | Whether to validate SSL certificates. | true |

### **Action Control**

This variable determines which action the role will perform.

| Variable | Description | Options | Default |
| :---- | :---- | :---- | :---- |
| confluence\_action | The operation to perform on a Confluence page. | get, create, update, delete | get |

### **Page Attributes**

These variables provide the necessary details for the chosen action.

| Variable | Description | Required For |
| :---- | :---- | :---- |
| confluence\_space\_key | The key of the Confluence space (e.g., "DOC"). | get, create |
| confluence\_page\_title | The title of the page to get or create. | get, create |
| confluence\_page\_id | The unique ID of the page to update or delete. | update, delete |
| confluence\_parent\_page\_title | The title of the parent page when creating a new page. | create |
| confluence\_page\_content | The HTML content for the page to be created or updated. | create, update |

### **Security: Using Ansible Vault**

**Do not store your API token in plain text.** Use ansible-vault to encrypt it.

1. Encrypt your token:  
   ansible-vault encrypt\_string 'YOUR\_API\_TOKEN' \--name 'confluence\_api\_token'

2. Paste the resulting encrypted block into your inventory or group vars file.

## **Example Playbooks**

Below are examples of how to use this role for each action. You would typically save these as playbook.yml and run them.

### **Get Page Info**

This example retrieves the details for a page titled "My Important Document" in the "IT" space.

\- name: Get Confluence Page Information  
  hosts: localhost  
  gather\_facts: false  
  roles:  
    \- role: ansible-confluence  
      vars:  
        confluence\_action: "get"  
        confluence\_space\_key: "IT"  
        confluence\_page\_title: "My Important Document"  
        \# Securely provide your credentials here or in inventory  
        confluence\_api\_url: "\[https://your-instance.atlassian.net/wiki/rest/api\](https://your-instance.atlassian.net/wiki/rest/api)"  
        confluence\_api\_user: "your-email@example.com"  
        confluence\_api\_token: "{{ vault\_confluence\_api\_token }}" \# Loaded from vault

### **Create a New Page**

This creates a new page titled "Project Kickoff Notes" under the parent page "Project Alpha".

\- name: Create a Confluence Page  
  hosts: localhost  
  gather\_facts: false  
  roles:  
    \- role: ansible-confluence  
      vars:  
        confluence\_action: "create"  
        confluence\_space\_key: "PROJ"  
        confluence\_parent\_page\_title: "Project Alpha"  
        confluence\_page\_title: "Project Kickoff Notes"  
        confluence\_page\_content: "\<h1\>Meeting Notes\</h1\>\<p\>Meeting held on {{ now().strftime('%Y-%m-%d') }}.\</p\>"  
        \# Add connection/auth vars

### **Update an Existing Page**

This updates the content of a page with the ID 12345678\.

\- name: Update a Confluence Page  
  hosts: localhost  
  gather\_facts: false  
  roles:  
    \- role: ansible-confluence  
      vars:  
        confluence\_action: "update"  
        confluence\_page\_id: "12345678"  
        confluence\_page\_content: "\<p\>This content was updated by Ansible on {{ now(utc=False) | strftime('%A, %B %d, %Y at %I:%M %p') }}.\</p\>"  
        \# Add connection/auth vars

### **Delete a Page**

This deletes a page with the ID 12345678\. **Use with caution\!**

\- name: Delete a Confluence Page  
  hosts: localhost  
  gather\_facts: false  
  roles:  
    \- role: ansible-confluence  
      vars:  
        confluence\_action: "delete"  
        confluence\_page\_id: "12345678"  
        \# Add connection/auth vars  
