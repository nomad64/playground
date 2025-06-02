# Ansible Role: infinibox_support_tunnel

## Description

This Ansible role manages the remote support tunnel for an Infinibox Support Appliance. It allows you to check the status of the tunnel, start (ensure it's present), stop (ensure it's absent), and restart the tunnel. [cite: 1, 39] The role interacts with the Infinibox Support Appliance API.

## Requirements

- Ansible 2.9 or later.
- Python `requests` library on the Ansible controller (implicitly used by `ansible.builtin.uri` for certain features, though usually bundled or handled by Ansible's Python interpreter).
- Access to the Infinibox Support Appliance API from the Ansible controller or the machine where `connection: local` tasks are executed.

## Role Variables

The role uses several variables to define its behavior. Sensitive values like passwords should be encrypted using Ansible Vault.

| Variable                  | Default Value                            | Required | Description                                                                                                                               |
|---------------------------|------------------------------------------|----------|-------------------------------------------------------------------------------------------------------------------------------------------|
| `sa_url`                  | `"https://<your_sa_hostname_or_ip>"`     | Yes      | The base URL for the Infinibox Support Appliance API (e.g., `https://ibox123-sa`).                                                        |
| `sa_username`             | `"your_api_username"`                    | Yes      | Username for authenticating to the Support Appliance API. [cite: 2]                                                                         |
| `sa_password`             | `"your_api_password"`                    | Yes      | Password for authenticating to the Support Appliance API. **Use Ansible Vault.** [cite: 2]                                                |
| `state`                   | `"status"`                               | No       | The desired state of the support tunnel. Options: `status`, `present`, `absent`, `restarted`.                                             |
| `tunnel_address`          | `"rss.infinidat.com"`                    | No       | Target RSS address for the tunnel. Used when `state` is `present` or `restarted`. [cite: 25]                                              |
| `tunnel_rss_secret`       | `"your_rss_secret"`                      | No       | Secret/password for the RSS connection. Used when `state` is `present` or `restarted`. **Use Ansible Vault.** [cite: 25]                   |
| `tunnel_connection_timeout`| `0`                                      | No       | Optional: Connection timeout for the tunnel in seconds. If `0` or undefined, the appliance default is used. [cite: 29]                    |
| `use_proxy`               | `false`                                  | No       | Whether to use a proxy for the tunnel connection. [cite: 27]                                                                              |
| `proxy_url`               | `"http://your_proxy_server:port"`        | No       | The URL of the proxy server if `use_proxy` is `true`.                                                                                     |
| `proxy_protocol`          | `"http"`                                 | No       | Protocol for `proxy_address` (e.g., `http`, `https`) if `use_proxy` is `true`.                                                          |
| `enable_proxy_auth`       | `false`                                  | No       | Whether to enable proxy authentication if `use_proxy` is `true`. [cite: 28]                                                               |
| `proxy_auth_username`     | `""`                                     | No       | Username for proxy authentication if `enable_proxy_auth` is `true`. **Use Ansible Vault.** [cite: 28]                                       |
| `proxy_auth_password`     | `""`                                     | No       | Password for proxy authentication if `enable_proxy_auth` is `true`. **Use Ansible Vault.** [cite: 28]                                       |
| `validate_certs`          | `false`                                  | No       | Whether to validate SSL certificates for API calls. Set to `true` in production if the SA has a trusted certificate. [cite: 2, 3, 6] |

### State Definitions

-   **`status`**: Checks the current status of the support tunnel and displays information including connection state and connected technicians. [cite: 5, 14]
-   **`present`**: Ensures the support tunnel is active. If the tunnel is `idle` (disconnected)[cite: 15], it will attempt to start it. [cite: 8, 10] This includes configuring the tunnel with address, secret, and optional proxy/timeout settings. [cite: 25, 27, 28, 29] It polls for a successful connection. [cite: 10, 11]
-   **`absent`**: Ensures the support tunnel is inactive. If the tunnel is `connected`, `reconnecting`, or `starting`[cite: 37], it will attempt to stop it. [cite: 12, 13] It polls to confirm the tunnel is `idle`.
-   **`restarted`**: Stops the tunnel (if active) and then starts it. [cite: 23] This is useful for resetting the tunnel connection. It first ensures the tunnel is `absent` and then makes it `present`.

## Dependencies

None.

## Example Playbook

```yaml
---
- name: Manage Infinibox Support Tunnel
  hosts: localhost
  connection: local # Or your management host
  gather_facts: false

  vars_files:
    - secrets.vault.yml # Contains vaulted sa_password, tunnel_rss_secret, etc.

  roles:
    - role: infinibox_support_tunnel
      vars:
        sa_url: "[https://my-infinibox-sa.example.com](https://my-infinibox-sa.example.com)"
        sa_username: "admin_user"
        sa_password: "{{ vaulted_sa_password }}" # From secrets.vault.yml
        state: "present" # Ensure the tunnel is active
        tunnel_address: "rss-emea.infinidat.com"
        tunnel_rss_secret: "{{ vaulted_tunnel_rss_secret }}" # From secrets.vault.yml
        tunnel_connection_timeout: 3600 # Auto-close after 1 hour
        # Example proxy configuration (optional)
        # use_proxy: true
        # proxy_url: "[http://proxy.example.com:8080](http://proxy.example.com:8080)"
        # enable_proxy_auth: true
        # proxy_auth_username: "{{ vaulted_proxy_user }}"
        # proxy_auth_password: "{{ vaulted_proxy_pass }}"
        validate_certs: true # Recommended for production
