# Ansible Role: NetApp NFS Volume Creator

This role creates (or ensures the existence of) an NFS volume on a NetApp ONTAP storage array. It also creates and manages an associated export policy and its rules for the volume. Automating this process with Ansible ensures consistency, repeatability, and reduces the potential for manual errors, especially in environments with multiple volumes or frequent provisioning needs. This role is designed to be idempotent, meaning it can be run multiple times with the same parameters and will only make changes if the desired state is not met.

## Requirements

* **Ansible 2.9 or later:** Ensure your Ansible control node meets this minimum version requirement for compatibility with the modules used.
* **NetApp ONTAP Ansible Collection: `netapp.ontap`**: This collection provides the necessary Ansible modules (like `na_ontap_volume`, `na_ontap_export_policy`, etc.) to interact with the NetApp ONTAP API. You can install it using:
    ```bash
    ansible-galaxy collection install netapp.ontap
    ```
* **Python `netapp-lib` library**: This underlying Python library is used by the `netapp.ontap` collection to facilitate communication and operations with the NetApp storage array. Install it on your Ansible control node:
    ```bash
    pip install netapp-lib
    ```
* **Credentials and Connectivity**:
    * The Ansible control node must have network connectivity to the NetApp ONTAP cluster management LIF.
    * The provided NetApp credentials must have sufficient privileges on the target SVM and cluster to perform actions such as volume creation, modification, deletion, export policy management, and SVM interaction. Typically, a role with `vsadmin` capabilities or a more granular custom role is recommended.

## Role Variables

The following variables can be defined by the user to customize the NFS volume creation and its export policy. Default values are specified in `defaults/main.yml` and can be overridden in your playbook or inventory.

| Variable                        | Required | Default                               | Description                                                                                                                            |
| ------------------------------- | -------- | ------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `netapp_hostname`               | Yes      | `""`                                  | Hostname (FQDN) or IP address of the NetApp ONTAP cluster management LIF. All API calls from the role will be directed to this endpoint. |
| `netapp_username`               | Yes      | `"admin"`                             | Username for authenticating to the NetApp ONTAP array. Consider using a dedicated service account with least privilege.               |
| `netapp_password`               | Yes      | `""`                                  | Password for the `netapp_username`. **It is strongly recommended to use Ansible Vault for managing this sensitive value** to avoid plain text exposure. |
| `netapp_svm_name`               | Yes      | `""`                                  | Name of the Storage Virtual Machine (SVM, formerly Vserver) where the volume and export policy will be created. The SVM provides a distinct set of resources and network configurations. |
| `netapp_use_https`              | No       | `true`                                | Specifies whether to use HTTPS (secure) or HTTP for the API connection. HTTPS is highly recommended for all environments.           |
| `netapp_validate_certs`         | No       | `false`                               | Whether to validate SSL certificates when `netapp_use_https` is `true`. For production, set to `true` to ensure secure communication by validating the NetApp array's SSL certificate against a trusted CA. For lab/dev environments with self-signed certificates, you might temporarily set this to `false`, acknowledging the security risk. |
| **Volume Parameters** |          |                                       |                                                                                                                                        |
| `netapp_volume_name`            | Yes      | `"my_nfs_volume"`                     | Name of the NFS volume to create. Choose a descriptive name that reflects the volume's purpose, e.g., `project_x_data` or `db_logs_archive`. |
| `netapp_volume_aggregate`       | Yes      | `""`                                  | Name of the aggregate on which to create the volume. Aggregates are collections of physical disks; the choice can impact performance, tiering, and available capacity. |
| `netapp_volume_size`            | No       | `"1"`                                 | Size of the volume. This value is combined with `netapp_volume_size_unit`.                                                              |
| `netapp_volume_size_unit`       | No       | `"gb"`                                | Unit for the volume size (e.g., `kb`, `mb`, `gb`, `tb`). For example, `size: "100"` and `size_unit: "gb"` creates a 100GB volume.     |
| `netapp_volume_junction_path`   | No       | `"/{{ netapp_volume_name }}"`          | The path within the SVM's namespace where the volume will be mounted, making it accessible to NFS clients. E.g., `/exports/data/{{ netapp_volume_name }}`. If not specified, ONTAP might assign a default or it might not be mounted automatically via this parameter. |
| `netapp_volume_security_style`  | No       | `"unix"`                              | Security style for the volume (`unix`, `ntfs`, `mixed`). For NFS, `unix` is typical. `mixed` or `ntfs` might be used in environments with both NFS and CIFS access to the same data, with careful consideration of permission handling. |
| `netapp_volume_state`           | No       | `"present"`                           | Desired state of the volume. `present` ensures the volume exists (creates or updates). `absent` will delete the volume (use with caution). |
| `netapp_volume_space_guarantee` | No       | `"none"`                              | Space guarantee setting for the volume (`none`, `volume`, `file`). `volume` fully provisions the space from the aggregate immediately. `none` (thin provisioning) allocates space as needed. |
| **Export Policy Parameters** |          |                                       |                                                                                                                                        |
| `netapp_volume_export_policy`   | No       | `"{{ netapp_volume_name }}_policy"`    | Name of the export policy to create/manage and associate with the volume. Defaults to a name derived from the volume name (e.g., `my_nfs_volume_policy`) for a dedicated policy. You can specify an existing policy name if you intend to share policies across multiple volumes. |
| `netapp_export_policy_state`    | No       | `"present"`                           | Desired state of the export policy and its rules. `present` ensures they exist. `absent` will attempt to remove them.                |
| `netapp_export_policy_rules`    | No       | See `defaults/main.yml` for example   | A list of rule objects to apply to the export policy. Each rule is a dictionary defining client access. An empty list means no rules are explicitly managed by this role for the policy; this might be useful if rules are managed externally or if a very open (or very restricted, depending on ONTAP defaults and existing rules if the policy is pre-existing) policy is intended initially. |

### Export Policy Rule Structure

Each item in the `netapp_export_policy_rules` list is a dictionary that defines an access rule. These rules control which clients can access the NFS share and what level of permissions they have. Key parameters include:

* `clientmatch` (string, required): Specifies the client(s) this rule applies to. This can be a single IP address (e.g., `"192.168.1.10"`), a CIDR block (e.g., `"10.0.0.0/8"` for a subnet), a hostname (e.g., `"client.example.com"`), a netgroup (e.g., `"@engineering_hosts"` if configured on the SVM/LDAP), or `"0.0.0.0/0"` to match all clients (use with extreme caution as it allows universal access).
* `protocols` (list of strings, required): Defines the list of access protocols allowed by this rule (e.g., `["nfs3"]`, `["nfs4"]`, `["nfs4.1"]`, or a combination like `["nfs3", "nfs4"]`).
* `rorule` (list of strings, optional): Security flavors that grant read-only access (e.g., `["sys"]`, `["krb5"]`, `["any"]`). `sys` is common for basic NFS security based on UID/GID. Using Kerberos (`krb5`, `krb5i`, `krb5p`) provides stronger, cryptographic authentication.
* `rwrule` (list of strings, optional): Security flavors that grant read-write access. Similar options as `rorule`. If both `rorule` and `rwrule` are specified for the same security flavor, `rwrule` typically takes precedence.
* `superuser` (list of strings, optional): Security flavors that grant root-level (superuser) privileges to the client. Often set to `["sys"]` for trusted clients or restricted further (e.g., `["none"]` or not specified) for enhanced security. Granting superuser access should be done cautiously.
* `rule_index` (integer, optional): Specifies the index (order) of the rule within the export policy. Rules are evaluated in ascending order of their index. Explicitly setting this can help manage complex policies where rule order is critical, though ONTAP often handles ordering adequately based on rule specificity if indices are not provided or are the same.
* `anon` (string, optional): Defines the effective user ID (UID) for anonymous users accessing the share under this rule. A common default in ONTAP is `65534` (often the `nobody` user). Setting it to `"0"` maps anonymous users to root, which can be a significant security risk and should be avoided unless absolutely necessary and understood.

Example `netapp_export_policy_rules`:
```yaml
netapp_export_policy_rules:
  # Rule for primary application servers with read-write access
  - clientmatch: "192.168.100.0/24"
    protocols: ["nfs3", "nfs4.1"]
    rwrule: ["sys", "krb5i"] # Allow read-write via system auth or Kerberos integrity
    rorule: ["sys", "krb5i"] # Also allow read-only
    superuser: ["sys"]       # Allow root access for system auth from these clients
    rule_index: 10
  # Rule for a specific backup server with read-only access
  - clientmatch: "backupserver.corp.example.com"
    protocols: ["nfs3"]
    rorule: ["sys"]
    anon: "65534" # Ensure anonymous access is mapped to 'nobody'
    rule_index: 20
  # A more restrictive rule for guest access from a specific IP
  - clientmatch: "10.50.1.23"
    protocols: ["nfs4"]
    rorule: ["any"] # Allow read-only for any security flavor from this specific IP
    anon: "65534"
    rule_index: 30
