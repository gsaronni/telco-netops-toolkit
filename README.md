# Network Automation Tools

Scripts written while operating a production network (Cisco, F5 BIG-IP, Linux) for one customer environment. Device names and addresses in this repository are fictional; they follow the same naming scheme as the [docs-as-code-showcase](https://github.com/gsaronni/docs-as-code-showcase) runbook, so a device has the same name in both repositories.

[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Contents

| Path | What it does | Runs on |
|------|--------------|---------|
| `f5-patching-automation.sh` | Lists, disables or enables the F5 LTM nodes of one patch group (T71, T72, T73) with tmsh, across four partitions | Bash on the BIG-IP itself |
| `network-backup-orchestrator.py`, `credential_manager_gui.py` | Backs up Cisco device configurations and uploads them by SFTP to a Linux backup server | Windows, Python 3.10+, a desktop session (PyQt5 window) |
| `mail_template.ps1` | Opens Outlook drafts announcing the start and end of a patching window | Windows with Outlook |
| `searchOnExcel.ps1` | Looks up IP addresses in every sheet of an Excel workbook | Windows with Excel |
| `ansible-backup/` | Learning port of the backup tool to Ansible; incomplete | Ansible control node |

Clone:

```bash
git clone https://github.com/gsaronni/network-automation.git
cd network-automation
```

## F5 patching automation

`f5-patching-automation.sh`, v1.6. In the runbook it is the node switch-off and switch-on step of [Patching Activity](https://gsaronni.github.io/docs-as-code-showcase/fastdelivery/f5-big-ip.html#_patching_activity), where it appears under its earlier name `t7_all-main_v01.3.sh`.

During a patching window, the LTM nodes of the servers being patched must be taken out of service and put back afterwards. Done by hand with tmsh this took about 50 minutes; the script does it in under 1 minute.

The script calls the tmsh CLI directly (`tmsh -c "cd /<partition>; modify /ltm node <node> session user-disabled"`), so it runs in a Bash shell on the BIG-IP. It works on four administrative partitions: `F5_BE-PRO`, `F5_BE-OMT`, `F5_FE-DMZ` and `F5_FE-DMZ-ext`. The node list of each patch group is hard-coded in its function (`t71-switcher`, `t72-switcher`, `t73-switcher`).

Actions:

- `l` list: prints the node and session lines of each node in the group.
- `d` disable: sets each node to `session user-disabled`.
- `e` enable: sets each node to `session user-enabled`.

Interactive use, a menu asks for the patch group (1, 2, 3) and then the action:

```bash
chmod +x f5-patching-automation.sh
./f5-patching-automation.sh
```

Non-interactive use, for example from cron:

```bash
./f5-patching-automation.sh 1 d    # patch group T71, disable
./f5-patching-automation.sh 1 e    # patch group T71, enable
```

The script validates its input but does not check the result of each tmsh command; list the group after a change to confirm it.

Background: [BIG-IP-F5_LTM_nodes.md](BIG-IP-F5_LTM_nodes.md).

## Network backup orchestrator

`network-backup-orchestrator.py` with `credential_manager_gui.py`, v5.0. Requires Python 3.10 or newer: the code itself needs 3.7 (`subprocess.run(capture_output=...)`), and current Netmiko releases need 3.10.

```bash
pip install -r requirements.txt
python network-backup-orchestrator.py
```

A run does the following, in order:

1. Creates `logs`, `todayBackup` and `backupArchive` under `C:\Users\<USERNAME>\Documents\NetworkBackups`. The path is hard-coded and built from the Windows `USERNAME` variable.
2. Opens a PyQt5 window that asks for three passwords: the personal account (user name taken from `USERNAME`, lower-cased), the ISE `admin` account and the backup server account. There is no headless mode; the window is required. The "Validate & Start Backup" button pings the backup server (Windows `ping -n` syntax), then logs in to one switch, one ISE node and the backup server. On a failure it clears the fields; on success it closes the window. Closing the window with its title bar button skips these checks and the run continues.
3. Backs up, one device at a time: IOS routers, Nexus switches (NX-OS), ISE nodes (with a 10-second wait after each command, for their slow CLI), then ASA firewalls. For each ASA it first writes a system-context file, which holds only the output of `terminal pager 0` and `write memory`, then saves the running configuration of each security context (`SYSTEM`, `MGMT`, `DMZ`, `BACKEND`, `FRONTEND`) to its own file. It runs `write memory` in the system context and in every security context, so a backup also saves each running configuration.
4. Uploads every file in `todayBackup` by SFTP (Paramiko) to the backup server's login directory, prints the remote listing, and writes the Paramiko log to `logs`.
5. Moves the files from `todayBackup` to `backupArchive\YYYYMMDD_backup`.

Files are named `<hostname>_YYYYMMDD_HHMMSS.cfg`, and `<hostname>_<context>_YYYYMMDD_HHMMSS.cfg` for ASA contexts.

A device that fails is reported and the run moves on to the next one. A failed upload ends the run, and the files stay in `todayBackup`.

The device inventory, device groups, contexts and the backup server are hard-coded in `main()` (fictional `10.0.0.x` addresses); edit them there.

Background: [network-backup.md](network-backup.md).

## PowerShell helpers

### mail_template.ps1

Creates two Outlook drafts for a patching window, "Start" (22:00) and "End" (02:00), each listing the nodes of the chosen patch group. The drafts are displayed, not sent. Set `$recipients` and `$cc` at the bottom of the script first.

```powershell
.\mail_template.ps1 2 2710    # patch group 2, date 27/10 of the current year
.\mail_template.ps1 2         # patch group 2, today's date
.\mail_template.ps1           # prompts for the patch group
```

### searchOnExcel.ps1

Set `$excelPath` to the full path of the workbook (and `$excelFileName`, used only in messages), then run the script and paste IP addresses one per line, ending with a blank line. For each address it reports every cell whose whole content matches, with sheet, cell and row, across all sheets. Excel must be installed; the script drives it through COM.

## ansible-backup (learning port, incomplete)

A port of the backup tool to Ansible playbooks, written as practice. It is not finished: ASA, ISE and the SFTP upload are not implemented, and it does not run as committed. See [ansible-backup/README.md](ansible-backup/README.md).

## Known limitations

- Node lists, device inventory and paths are hard-coded in the scripts.
- The backup tool runs on Windows only and needs a desktop session for its window.
- Passwords are typed at every run; there is no secrets store.
- The ASA backup also runs `write memory`, which changes the device's startup configuration.
- The ASA system context's running configuration is not captured; the per-context files are.
- No automated tests.

## Licence

MIT, see [LICENSE](LICENSE).

## Author

Gabriele Saronni, network engineer. [LinkedIn](https://linkedin.com/in/gabriele-s-54514173) | [GitHub](https://github.com/gsaronni)
