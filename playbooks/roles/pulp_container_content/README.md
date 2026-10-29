# Pulp Container Content Role

This role mirrors container images into Pulp from a YAML list, so Pulp serves them as a container registry. For each image it creates the remote with the tags to sync, the repository, syncs it, and creates its distributions: channels that follow the latest version, and channels pinned to a specific repository version. Bumping a pinned channel's `version` and re-running promotes it, lowering it rolls back.

It runs on the control node against the Pulp API using `pulp.squeezer`.

---

## Requirements

- A running Pulp server (see the `pulp_setup` role), which ships the container plugin and the `/v2/` registry API
- `pulp.squeezer` 0.4.0 (`ansible-galaxy collection install -r requirements.yml`)
- `pulp-glue` >=0.29.2,<0.40 in the Python that runs the modules (the playbook uses the `~/.venvs/pulp` venv)

---

## Role Variables

### Connection

| Name | Type | Default | Description |
|---|---|---|---|
| `pulp_container_content_url` | string | `"http://localhost:8080"` | Pulp API URL. The playbook sets it from the inventory. |
| `pulp_container_content_username` | string | `"admin"` | Pulp user. |
| `pulp_container_content_password` | string | `"changeme"` | Pulp password. Lab value. |

### Images

| Name | Type | Default | Description |
|---|---|---|---|
| `pulp_container_content_images` | list | `[]` | Container images to manage. See below. |

Each entry:

| Key | Required | Default | Description |
|---|---|---|---|
| `name` | ✓ | | Name of the remote and repository. |
| `url` | ✓ | | Upstream registry, e.g. `https://registry.access.redhat.com`. |
| `upstream_name` | ✓ | | Image path on the registry, e.g. `ubi9/ubi-minimal`. |
| `include_tags` | ✓ | | Tags to sync. Wildcards like `9.*` work. |
| `policy` | | `on_demand` | `on_demand` downloads layers on the first pull (upstream must be reachable then), `immediate` downloads every layer and architecture at sync. |
| `channels` | ✓ | | List of `base_path` (and optional `version` and `private`). Without `version` the channel follows every sync. `private: true` requires a login to pull. |

---

## Example

```yaml
pulp_container_content_images:
  - name: ubi9-minimal
    url: https://registry.access.redhat.com
    upstream_name: ubi9/ubi-minimal
    include_tags:
      - latest
    channels:
      - base_path: containers/ubi9-minimal/latest
      - base_path: containers/ubi9-minimal/approved
        version: 1
```

Clients pull `<pulp>:8080/<base_path>:<tag>`. The registry is plain HTTP in the lab, so Podman needs `--tls-verify=false` or the registry marked insecure in `/etc/containers/registries.conf`:

```
podman pull --tls-verify=false <pulp>:8080/containers/ubi9-minimal/approved:latest
```

Images built in house don't need this role: `podman login` to Pulp and `podman push <pulp>:8080/<name>:<tag>` creates a push repository on the first push.

---

## Maintainer Information

* Eugene Garces
