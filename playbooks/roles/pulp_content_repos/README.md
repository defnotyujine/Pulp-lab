# Pulp Content Repos Role

This role manages Pulp RPM repositories from a YAML list. For each repository it creates the remote and the repository, syncs it, and creates its distributions: channels that follow the latest version, and channels pinned to a specific repository version. Bumping a pinned channel's `version` and re-running promotes it, lowering it rolls back.

It runs on the control node against the Pulp API using `pulp.squeezer`.

---

## Requirements

- A running Pulp server (see the `pulp_setup` role)
- `pulp.squeezer` 0.4.0 (`ansible-galaxy collection install -r requirements.yml`)
- `pulp-glue` >=0.29.2,<0.40 in the Python that runs the modules (the playbook uses the `~/.venvs/pulp` venv)

---

## Role Variables

### Connection

| Name | Type | Default | Description |
|---|---|---|---|
| `pulp_content_repos_url` | string | `"http://localhost:8080"` | Pulp API URL. The playbook sets it from the inventory. |
| `pulp_content_repos_username` | string | `"admin"` | Pulp user. |
| `pulp_content_repos_password` | string | `"changeme"` | Pulp password. Lab value. |

### Repositories

| Name | Type | Default | Description |
|---|---|---|---|
| `pulp_content_repos_rpm` | list | `[]` | RPM repositories to manage. See below. |

Each entry:

| Key | Required | Default | Description |
|---|---|---|---|
| `name` | ✓ | | Name of the remote and repository. |
| `url` | ✓ | | Upstream yum repository URL. |
| `policy` | | `on_demand` | `immediate`, `on_demand` or `streamed`. |
| `sync_policy` | | `additive` | `additive`, `mirror_content_only` or `mirror_complete`. |
| `retain_package_versions` | | | Keep only the newest N versions of each package. |
| `ca_cert` / `client_cert` / `client_key` | | | Paths on the control node to TLS files for the remote, e.g. Red Hat CDN subscription certificates. Read by the role and stored by Pulp. |
| `channels` | ✓ | | List of `base_path` (and optional `version`). Without `version` the channel follows every sync. |

---

## Example

```yaml
pulp_content_repos_rpm:
  - name: wazuh-4
    url: https://packages.wazuh.com/4.x/yum/
    channels:
      - base_path: wazuh/4/latest
      - base_path: wazuh/4/approved
        version: 1
```

Clients use `http://<pulp>:8080/pulp/content/<base_path>/`, with a ready-made `config.repo` in each.

---

## Maintainer Information

* Eugene Garces
