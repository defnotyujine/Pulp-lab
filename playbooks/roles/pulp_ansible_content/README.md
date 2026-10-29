# Pulp Ansible Content Role

This role mirrors Ansible collections from Galaxy into Pulp from a YAML list. For each repository it creates the remote with a requirements list, the repository, syncs it, and creates its distributions: channels that follow the latest version, and channels pinned to a specific repository version. Bumping a pinned channel's `version` and re-running promotes it, lowering it rolls back.

It runs on the control node against the Pulp API using `pulp.squeezer`.

---

## Requirements

- A running Pulp server (see the `pulp_setup` role), with `ANSIBLE_API_HOSTNAME` set so download links point at Pulp
- `pulp.squeezer` 0.4.0 (`ansible-galaxy collection install -r requirements.yml`)
- `pulp-glue` >=0.29.2,<0.40 in the Python that runs the modules (the playbook uses the `~/.venvs/pulp` venv)

---

## Role Variables

### Connection

| Name | Type | Default | Description |
|---|---|---|---|
| `pulp_ansible_content_url` | string | `"http://localhost:8080"` | Pulp API URL. The playbook sets it from the inventory. |
| `pulp_ansible_content_username` | string | `"admin"` | Pulp user. |
| `pulp_ansible_content_password` | string | `"changeme"` | Pulp password. Lab value. |

### Collection repositories

| Name | Type | Default | Description |
|---|---|---|---|
| `pulp_ansible_content_collections` | list | `[]` | Collection repositories to manage. See below. |

Each entry:

| Key | Required | Default | Description |
|---|---|---|---|
| `name` | ✓ | | Name of the remote and repository. |
| `url` | ✓ | | Galaxy API URL, e.g. `https://galaxy.ansible.com/api/`. |
| `requirements` | ✓ | | Collections to sync: `name` and optional `version` range. |
| `sync_dependencies` | | `true` | Also sync each collection's dependencies. Set to `false` and list them in `requirements` to keep their versions in range. |
| `channels` | ✓ | | List of `base_path` (and optional `version`). Without `version` the channel follows every sync. |

---

## Example

```yaml
pulp_ansible_content_collections:
  - name: galaxy
    url: https://galaxy.ansible.com/api/
    requirements:
      - name: ansible.posix
        version: ">=2.0.0,<3.0.0"
    channels:
      - base_path: collections/latest
      - base_path: collections/approved
        version: 1
```

Clients install from a channel with this `ansible.cfg`:

```ini
[galaxy]
server_list = pulp

[galaxy_server.pulp]
url = http://<pulp>:8080/pulp_ansible/galaxy/collections/approved/
```

---

## Maintainer Information

* Eugene Garces
