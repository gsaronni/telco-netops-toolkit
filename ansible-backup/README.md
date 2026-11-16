# ansible-backup (learning port, incomplete)

A port of the Python backup orchestrator (`../network-backup-orchestrator.py`) to Ansible, written as practice: Ansible syntax, network modules, and an inventory file in place of addresses hard-coded in the script.

## Files

- `inventory.ini`: device groups (Nexus switches, ASR routers, ISE nodes, ASA firewalls, backup server). Names and addresses are fictional and match the docs-as-code-showcase runbook.
- `backup-configs.yml`: fetches the running configuration of the Nexus switches and ASR routers into `<backup_path>/<date>/`; on IOS devices it first copies the running configuration to startup.
- `test-connectivity.yml`: gathers minimal facts from every device except the backup server and reports which ones answered.

## Status

Incomplete, and it does not run as committed:

- The inventory sets no `ansible_connection` or `ansible_network_os`, which the `cisco.ios` modules need.
- `backup_path` is not defined anywhere; it must be passed on the command line.
- ASA, ISE and the SFTP upload are not implemented. The upload play is a placeholder that only prints a message.

## Run

```bash
pip install ansible
ansible-galaxy collection install cisco.ios
ansible-playbook -i inventory.ini backup-configs.yml --ask-pass -e backup_path=./backups
```

## Compared with the Python tool

The Python tool is 354 lines with hard-coded addresses, its own error handling and a PyQt5 password window. The playbook is 48 lines, takes devices from the inventory, uses the collection's modules and asks for the password with `--ask-pass`.
