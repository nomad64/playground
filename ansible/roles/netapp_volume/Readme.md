# NetApp ONTAP Volume Management Role

---

This Ansible role provides a comprehensive solution for managing NetApp ONTAP volumes, allowing you to **create**, **modify** (including **resizing**), **disable** (take offline or destroy), and perform other **custom actions** like **creating snapshots**. It's designed to be idempotent, ensuring that your desired state is maintained with each execution.

## Features

* **Create Volumes**: Provision new volumes with specified size, aggregate, Vserver, junction path, space guarantee, snapshot policy, and security style.
* **Modify Volumes**: Adjust existing volume parameters, including **resizing** (increasing size) and updating comments or other properties.
* **Manage Volume State**: Take volumes `online` or `offline`.
* **Destroy Volumes**: Remove volumes completely by setting their state to `absent`.
* **Custom Actions**: Extensible framework to add unique operations, such as **creating snapshots**.

## Requirements

* Ansible 2.10 or newer.
* The `netapp.ontap` Ansible collection. Install it using:
    ```bash
    ansible-galaxy collection install netapp.ontap
    ```
* Network connectivity from your Ansible control node to the NetApp ONTAP cluster management LIF.
* A NetApp ONTAP user with appropriate API privileges to manage volumes and snapshots.

## Role Variables

This role uses variables defined in `defaults/main.yml`. You can override these in your playbook, inventory, or `vars/main.yml`.

| Variable                      | Default Value                                     | Description                                                                                                                                                                                                                                                          |
| :---------------------------- | :------------------------------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `netapp_hostname`             | `"your_netapp_cluster_mgmt_ip_or_fqdn"`           | The IP address or FQDN of your NetApp ONTAP cluster's management LIF.                                                                                                                                                                                                |
| `netapp_username`             | `"your_netapp_api_username"`                      | The username for API access to the NetApp cluster.                                                                                                                                                                                                                   |
| `netapp_password`             | `"your_netapp_api_password"`                      | **Sensitive!** The password for the API user. **Strongly recommended to use Ansible Vault for this variable.** |
| `netapp_validate_certs`       | `false`                                           | Set to `true` to validate SSL certificates. Ensure your NetApp cluster has valid certificates if enabling.                                                                                                                                                             |
| `netapp_volume_name`          | `"ansible_test_volume"`                           | The name of the NetApp volume to manage.                                                                                                                                                                                                                             |
| `netapp_volume_vserver`       | `"your_vserver_name"`                             | The name of the storage virtual machine (Vserver) where the volume resides or will be created.                                                                                                                                                                       |
| `netapp_volume_aggregate`     | `"your_aggregate_name"`                           | The aggregate where the volume will be created. Required when `netapp_volume_state` is `present` for a new volume.                                                                                                                                                   |
| `netapp_volume_size`          | `"100g"`                                          | The desired size of the volume (e.g., "10g", "1t"). Used for creation and resizing.                                                                                                                                                                                  |
| `netapp_volume_state`         | `"present"`                                       | Defines the desired state of the volume. Options: <br> `present`: Ensures volume exists and matches parameters (creates or modifies/resizes). <br> `online`: Ensures volume exists and is online. <br> `offline`: Ensures volume exists and is offline. <br> `absent`: Ensures volume does not exist (destroys it). <br> `snapshot`: Creates a snapshot of the volume. |
| `netapp_volume_junction_path` | `"/vol/{{ netapp_volume_name }}"`                 | The junction path for the volume (where it's mounted in the namespace).                                                                                                                                                                                              |
| `netapp_volume_space_guarantee` | `"none"`                                          | The space guarantee type for the volume. Options: `"volume"`, `"none"`.                                                                                                                                                                                              |
| `netapp_volume_snapshot_policy` | `"default"`                                       | The snapshot policy to apply to the volume. Options: `"default"`, `"none"`, or a custom policy name.                                                                                                                                                                 |
| `netapp_volume_security_style` | `"unix"`                                          | The security style for the volume. Options: `"unix"`, `"ntfs"`, `"mixed"`.                                                                                                                                                                                           |
| `netapp_volume_tiering_policy` | `"none"`                                          | The FabricPool tiering policy. Options: `"none"`, `"auto"`, `"snapshot-only"`, `"all"`.                                                                                                                                                                             |
| `netapp_volume_comment`       | `"Managed by Ansible"`                            | A comment to associate with the volume.                                                                                                                                                                                                                              |
| `netapp_snapshot_name`        | `"ansible_snapshot_{{ ansible_date_time.iso8601_basic_short }}"` | The name for the snapshot when `netapp_volume_state` is `snapshot`. Defaults to a timestamped name.                                                                                                                                                                  |

## Role Structure

```
netapp_volume/
├── tasks/
│   ├── main.yml          # Main entry point for the role, includes other task files based on state.
│   ├── _create_volume.yml  # Handles volume creation and modification/resizing when state is 'present'.
│   ├── _manage_state.yml   # Manages volume online/offline state and destruction ('absent').
│   └── _create_snapshot.yml # Custom task for creating a volume snapshot.
├── defaults/
│   └── main.yml          # Default variables for the role.
├── vars/
│   └── main.yml          # Placeholder for environment-specific variables (consider Ansible Vault).
├── handlers/
│   └── main.yml          # Placeholder for handlers (not used by default in this role).
└── meta/
    └── main.yml          # Role metadata.
```

## Usage Example

Here's how to use this role in an Ansible playbook to demonstrate creating, resizing, taking offline, bringing online, snapshotting, and destroying volumes.

**`manage_volumes.yml`**

```yaml
---
- name: "Manage NetApp ONTAP Volumes"
  hosts: localhost # Run locally, as the NetApp modules connect directly to the array
  connection: local
  gather_facts: false # No need to gather facts from localhost for this role

  vars:
    # IMPORTANT: Override these variables for your environment.
    # For production, use Ansible Vault for 'netapp_password'!
    netapp_hostname: "192.168.1.100" # Your NetApp cluster management IP/FQDN
    netapp_username: "admin"
    netapp_password: "YourSecurePassword" # Use ansible-vault!
    netapp_validate_certs: false # Set to true if using valid SSL certificates

  roles:
    - role: netapp_volume
      vars:
        netapp_volume_name: "my_ansible_vol_1"
        netapp_volume_vserver: "vs1"
        netapp_volume_aggregate: "aggr1"
        netapp_volume_size: "50g"
        netapp_volume_state: "present" # ACTION: Create or ensure present

    - name: "--- RESIZE EXAMPLE: Increasing Volume Size ---"
      ansible.builtin.debug:
        msg: "Attempting to resize 'my_ansible_vol_1' from 50g to 75g"

    - role: netapp_volume
      vars:
        netapp_volume_name: "my_ansible_vol_1"
        netapp_volume_vserver: "vs1"
        netapp_volume_size: "75g" # ACTION: Modify/Resize - This will trigger a resize if current size is different
        netapp_volume_comment: "Resized by Ansible"
        netapp_volume_state: "present" # Ensures it's present and at the new size

    - name: "--- END RESIZE EXAMPLE ---"
      ansible.builtin.debug:
        msg: "Resize attempt complete for 'my_ansible_vol_1'"

    - role: netapp_volume
      vars:
        netapp_volume_name: "my_ansible_vol_2"
        netapp_volume_vserver: "vs1"
        netapp_volume_aggregate: "aggr1"
        netapp_volume_size: "20g"
        netapp_volume_junction_path: "/data/vol2"
        netapp_volume_space_guarantee: "volume"
        netapp_volume_state: "present" # ACTION: Create or ensure present

    - role: netapp_volume
      vars:
        netapp_volume_name: "my_ansible_vol_1"
        netapp_volume_vserver: "vs1"
        netapp_volume_state: "offline" # ACTION: Take volume offline

    - role: netapp_volume
      vars:
        netapp_volume_name: "my_ansible_vol_1"
        netapp_volume_vserver: "vs1"
        netapp_volume_state: "online" # ACTION: Bring volume online

    - role: netapp_volume
      vars:
        netapp_volume_name: "my_ansible_vol_1"
        netapp_volume_vserver: "vs1"
        netapp_volume_state: "snapshot" # ACTION: Create a snapshot
        netapp_snapshot_name: "daily_backup_vol1" # Custom snapshot name

    - role: netapp_volume
      vars:
        netapp_volume_name: "my_ansible_vol_2"
        netapp_volume_vserver: "vs1"
        netapp_volume_state: "absent" # ACTION: Destroy volume
```

## Running the Playbook

To execute the playbook, navigate to the directory containing your `manage_volumes.yml` file and run:

```bash
ansible-playbook -i localhost, manage_volumes.yml
```

If you're using Ansible Vault for your `netapp_password`, remember to include the `--ask-vault-pass` flag:

```bash
ansible-playbook -i localhost, manage_volumes.yml --ask-vault-pass
```

## Extending with More Custom Actions

To add more specific, user-defined actions (like reverting a snapshot, modifying qtrees, etc.):

1.  **Define a new `netapp_volume_state` value** (e.g., `'revert_snapshot'`) in `defaults/main.yml` or use a new variable to trigger the action.
2.  **Add a conditional `ansible.builtin.include_tasks`** in `tasks/main.yml` that checks for your new state.
    ```yaml
    - name: "Include task for custom action: revert snapshot"
      ansible.builtin.include_tasks: _revert_snapshot.yml
      when: netapp_volume_state == 'revert_snapshot'
    ```
3.  **Create a new task file** (e.g., `_revert_snapshot.yml`) in the `tasks/` directory containing the specific Ansible tasks for that action, utilizing the appropriate `netapp.ontap` module (e.g., `netapp.ontap.na_ontap_snapshot_revert`).

This modular design makes the role highly extensible for all your NetApp ONTAP automation needs.
```