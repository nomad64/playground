# NetApp SVM-DR SnapMirror Ansible Role

This Ansible role automates various NetApp SVM-DR SnapMirror operations, including:

- Setting up a new SVM-DR SnapMirror relationship.
- Synchronizing an existing SVM-DR SnapMirror relationship.
- Quiescing an SVM-DR SnapMirror relationship.
- Breaking an SVM-DR SnapMirror relationship.

## Requirements

- Ansible 2.9 or higher
- `netapp.ontap` collection installed (`ansible-galaxy collection install netapp.ontap`)
- Access to your NetApp ONTAP cluster with appropriate credentials (cluster management LIF).

## Role Variables

See `defaults/main.yml` for a list of variables and their default values.

## Usage

To use this role, include it in your playbook and define the necessary variables.
You can control the operation type using the `snapmirror_operation` variable.

Example playbook:

```yaml
---
- name: Manage NetApp SVM-DR SnapMirror
  hosts: localhost
  connection: local
  gather_facts: no

  vars:
    netapp_hostname: your_ontap_cluster_ip_or_hostname # Cluster management LIF
    netapp_username: your_ontap_username
    netapp_password: your_ontap_password

    # SVM-DR SnapMirror variables
    snapmirror_source_svm: your_source_svm_name
    snapmirror_source_cluster: your_source_cluster_name
    snapmirror_destination_svm: your_destination_svm_name
    snapmirror_destination_cluster: your_destination_cluster_name
    snapmirror_policy: MirrorAllVolumes # Example policy for SVM-DR

    # Choose the operation (setup, sync, quiesce, break)
    snapmirror_operation: setup # Change this for desired operation

  roles:
    - netapp_snapmirror
```

## Operations

### Setup (`snapmirror_operation: setup`)

Creates a new SVM-DR SnapMirror relationship.

### Sync (`snapmirror_operation: sync`)

Synchronizes an existing SVM-DR SnapMirror relationship.

### Quiesce (`snapmirror_operation: quiesce`)

Quiesces an SVM-DR SnapMirror relationship, stopping future transfers.

### Break (`snapmirror_operation: break`)

Breaks an SVM-DR SnapMirror relationship, making the destination SVM's volumes writable.
