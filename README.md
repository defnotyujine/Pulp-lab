# Pulp-lab

Deploy and manage [Pulp 3](https://pulpproject.org/) with Ansible: a multi-container Podman setup, plus declarative content management for RPM repositories, Ansible collections and container images, with versioning and promotion.

Pulp sits between the internet and your machines. It mirrors upstream content (Red Hat CDN, Wazuh, Galaxy, container registries), keeps every sync as an immutable repository version, and serves it on stable URLs. Clients only talk to Pulp, never to the internet.

---

## What's in here

| Role | Does |
|---|---|
| [`pulp_setup`](playbooks/roles/pulp_setup/README.md) | Deploys the Pulp server on RHEL as Podman quadlets under systemd: pulp-web (nginx), pulp-api, pulp-content, pulp-worker, PostgreSQL and Redis. |
| [`pulp_content_repos`](playbooks/roles/pulp_content_repos/README.md) | RPM repositories: remote, repository, sync and distributions. Supports Red Hat CDN subscription certificates. |
| [`pulp_ansible_content`](playbooks/roles/pulp_ansible_content/README.md) | Ansible collections mirrored from Galaxy, limited to a requirements list. |
| [`pulp_container_content`](playbooks/roles/pulp_container_content/README.md) | Container images mirrored from upstream registries, so Pulp serves them as a registry. |

The content roles run on the control node and talk to the Pulp API with [`pulp.squeezer`](https://galaxy.ansible.com/ui/repo/published/pulp/squeezer/). Nothing in them is specific to one repository, everything comes from the YAML in `playbooks/vars/`.

### Channels and promotion

Every repository gets a list of **channels**, each one a URL clients point at:

- A channel **without** `version` follows every sync (e.g. `wazuh/4/latest`).
- A channel **with** `version` stays on that repository version (e.g. `wazuh/4/approved`, `version: 1`). Bump the number and re-run to promote, lower it to roll back.

```yaml
pulp_content_repos_rpm:
  - name: wazuh-4
    url: https://packages.wazuh.com/4.x/yum/
    channels:
      - base_path: wazuh/4/latest
      - base_path: wazuh/4/approved
        version: 1
```

---

## Layout

```
playbooks/
  pulp_setup_playbook.yml      deploys the Pulp server (pre-checks + pulp_setup)
  pulp_content_playbook.yml    manages all content (the three content roles)
  vars/                        the desired content: RPM repos, collections, container images
  roles/                       pulp_setup, pulp_content_repos, pulp_ansible_content, pulp_container_content
sysconfig/
  inventory.yml                the pulp_servers group
  group_vars/pulp_servers/     server overrides (credentials, ideally from a vault)
requirements.yml               Ansible collections for the control node
```

---

## Requirements

**Pulp server**

- RHEL 9.5+ or RHEL 10 (the quadlets need Podman 5.2+), registered so it can install Podman from AppStream
- Internet access to `quay.io` and `docker.io` for the images, and to every upstream it syncs from

**Control node**

- `ansible-core` 2.16.1+
- `rhel-system-roles` RPM (firewall)
- The collections in `requirements.yml`
- `pulp-glue` >=0.29.2,<0.40 for `pulp.squeezer`, in a Python 3.10+ venv. Installing `pulp-cli` 0.39.x brings it along, and gives you the `pulp` command:

```bash
ansible-galaxy collection install -r requirements.yml
python3.12 -m venv ~/.venvs/pulp
~/.venvs/pulp/bin/pip install "pulp-cli<0.40"
ln -s ~/.venvs/pulp/bin/pulp ~/.local/bin/pulp
```

The content playbook runs its modules with `~/.venvs/pulp/bin/python`.

---

## Usage

**1. Point the inventory at your Pulp server** in `sysconfig/inventory.yml`.

**2. Deploy Pulp:**

```bash
ansible-playbook -i sysconfig/inventory.yml playbooks/pulp_setup_playbook.yml -K
```

A second run should report `changed=0`.

**3. Configure `pulp-cli`** (optional, for looking around):

```bash
pulp config create --base-url http://<pulp>:8080 --username admin --password changeme
pulp status
```

**4. Sync and publish content** from `playbooks/vars/`:

```bash
ansible-playbook -i sysconfig/inventory.yml playbooks/pulp_content_playbook.yml
```

Run one content type only with `--tags pulp_content_repos`, `pulp_ansible_content` or `pulp_container_content`.

---

## Using the content

**RPM repositories.** Every channel has a ready-made `config.repo`:

```bash
curl -o /etc/yum.repos.d/wazuh.repo http://<pulp>:8080/pulp/content/wazuh/4/approved/config.repo
```

**Ansible collections** with this `ansible.cfg`:

```ini
[galaxy]
server_list = pulp

[galaxy_server.pulp]
url = http://<pulp>:8080/pulp_ansible/galaxy/collections/approved/
```

**Container images.** The registry is plain HTTP, so podman needs `--tls-verify=false`:

```bash
podman pull --tls-verify=false <pulp>:8080/containers/almalinux/approved:9
```

---

## Lab notes

- The role defaults hold lab credentials (`admin` / `changeme`). Outside a lab, override them from an Ansible Vault.
- Pulp is served over plain HTTP on port 8080.
- RPM and container remotes default to `on_demand`: a sync only fetches metadata, and packages and layers are downloaded on the first client request. Pulp must be able to reach the upstream at that moment.
- Ansible collection remotes are always `immediate`, so keep the version ranges tight.
- Scheduled syncs (nightly, monthly) are meant to run from a Jenkins pipeline calling the content playbook, not from the roles.

---

## CI

Every push and pull request runs [ansible-lint](.github/workflows/ansible-lint.yml). Locally, [pre-commit](.pre-commit-config.yaml) checks whitespace, end of files, YAML and large files on commit.

---

## Maintainer

* Eugene Garces
