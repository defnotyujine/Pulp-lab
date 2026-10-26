# Pulp Setup Role

This role deploys a Pulp server on RHEL using Podman quadlets. Each Pulp component runs in its own container under systemd: pulp-web (nginx), pulp-api, pulp-content, pulp-worker, PostgreSQL and Redis. A one-shot pulp-migrate unit runs the database migrations before the Pulp services start.

---

## Requirements

- RHEL 9.5+ or RHEL 10 host with repository access (AppStream) for Podman. The quadlets need Podman 5.2+, which RHEL 9.4 and older don't have.
- Access to `quay.io` and `docker.io` to pull images
- `redhat.rhel_system_roles` on the control node (`rhel-system-roles` RPM), used for the firewall

---

## Role Variables

### Images

| Name | Type | Default | Description |
|---|---|---|---|
| `pulp_setup_image_tag` | string | `"3.123.1"` | Pulp version for `pulp-minimal` and `pulp-web`. Bump it and re-run to upgrade. |
| `pulp_setup_postgres_image` | string | `"docker.io/library/postgres:16"` | PostgreSQL image. |
| `pulp_setup_redis_image` | string | `"docker.io/library/redis:7"` | Redis image. |

### Network

| Name | Type | Default | Description |
|---|---|---|---|
| `pulp_setup_web_port` | int | `8080` | Port pulp-web listens on, opened in firewalld. |
| `pulp_setup_url` | string | `http://<ansible_host>:8080` | URL clients use to reach Pulp. |

### Credentials

| Name | Type | Default | Description |
|---|---|---|---|
| `pulp_setup_admin_password` | string | `"changeme"` | Password of the Pulp `admin` user. |
| `pulp_setup_db_password` | string | `"pulp"` | PostgreSQL password. Letters and digits only. |
| `pulp_setup_secret_key` | string | `"lab-secret-key-change-me"` | Django `SECRET_KEY`. |

> **Note:** The defaults are lab values. Outside a lab, override them from an Ansible Vault.

---

## Tags

| Tag | Description |
|---|---|
| `pulp_packages` | Install Podman |
| `pulp_config` | `settings.py`, DB encryption key, nginx files |
| `pulp_containers` | Quadlet units, start services |
| `pulp_firewall` | Open `pulp_setup_web_port` |
| `pulp_admin` | Set the admin password |

---

## Example Playbook

```yaml
- name: Deploy the Pulp server
  hosts: pulp_servers
  become: true
  roles:
    - pulp_setup
```

---

## Notes

- Check the services with `systemctl status pulp-api` and the logs with `journalctl -u pulp-api`.
- The DB encryption key `/etc/pulp/certs/database_fields.symmetric.key` is created once and never replaced. Back it up together with the database.

---

## Maintainer Information

* Eugene Garces
