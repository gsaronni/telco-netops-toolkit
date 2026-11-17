# Network Backup Orchestrator

**Configuration backup for a Cisco estate (NX-OS, IOS, ISE, multi-context ASA) with SFTP upload to a Linux server**

[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Background for `network-backup-orchestrator.py` and `credential_manager_gui.py`. How to install and run them is in the [README](README.md#network-backup-orchestrator).

## Overview

One script that logs in to each device in turn, saves its configuration to a file, uploads the files by SFTP to a Linux backup server and archives them locally. The inventory in this repository is fictional: nine devices to back up (three Nexus switches, two IOS routers, two ISE nodes, two ASA firewalls) plus the backup server.

**Features:**
- Cisco NX-OS, IOS, ISE and ASA, each with its own Netmiko device type
- ASA backup per security context
- SFTP upload to a central backup server
- Date-stamped local archive folders
- PyQt5 password window with login checks before the backup starts
- A 10-second wait after each ISE command, for their slow CLI

## The problem

Backing up configurations by hand across several Cisco platforms means:
- **Time**: one SSH session per device, plus one per ASA context
- **Typing**: the same commands on every device, by hand
- **Inconsistency**: file names and storage depend on who did it

## The solution

A Python script that:
1. **Checks the passwords first**: logs in to one switch, one ISE node and the backup server before starting
2. **Connects to each device** in turn, with the Netmiko device type for its platform
3. **Waits for slow devices**: 10 seconds after each command on ISE nodes
4. **Saves each ASA context** to its own file
5. **Uploads the files** to the backup server by SFTP
6. **Archives the files** locally in a folder named after the date
7. **Prints the outcome** of each device; a failed device is reported and the run moves on

## Architecture

```
  credential_manager_gui.py        network-backup-orchestrator.py
 +--------------------------+     +-----------------------+     +---------------+
 | password window          | --> | backup, one device at | --> | SFTP upload,  |
 | ping + three test logins |     | a time (Netmiko)      |     | then archive  |
 +--------------------------+     +-----------------------+     +---------------+
                                     |      |      |      |            |
                                    IOS  Nexus   ISE    ASA      Linux backup
                                  routers switches nodes firewalls   server
```

## Technical notes

### Platforms

- **Cisco NX-OS**: Nexus switches (`cisco_nxos`)
- **Cisco IOS**: routers (`cisco_ios`)
- **Cisco ISE**: logged in to as `cisco_nxos`, with the 10-second wait
- **Cisco ASA**: `cisco_asa`, per context
- **Linux**: the backup server, reached with Paramiko for SFTP

Routers, switches and ISE nodes run `terminal length 0`, `show running-config` and `exit`, read with `send_command_timing`.

### ASA contexts

For each ASA the script:
1. Runs `terminal pager 0` and `write memory` in the context it logs in to, and saves their output to `<hostname>_YYYYMMDD_HHMMSS.cfg`
2. For each of the five context names (`SYSTEM`, `MGMT`, `DMZ`, `BACKEND`, `FRONTEND`): runs `changeto context <name>`, then `write memory`, then `show running-config`
3. Saves each context's running configuration to `<hostname>_<context>_YYYYMMDD_HHMMSS.cfg`

```python
for context in contexts:
    conn.send_command(f"changeto context {context}")
    conn.send_command("write memory")
    output = conn.send_command_timing("show running-config")
    write_file(output, context_filename, path)
```

Because of the `write memory` calls, a backup also saves each running configuration to startup.

### Version history

From the script header:

- **v1.0** (2022-04-05): initial release
- **v4.7** (2023-01-20): user name taken from the Windows environment; ASR900 timing fixed with `send_command_timing`
- **v4.8** (2023-06-26): Ctrl+C handled (the run stops with a message); devices with slow CLI response fixed
- **v4.9** (2023-07-14): password validation
- **v5.0** (2023-09-08): ISE timing fixed with sleep delays

```python
# ISE appliances have slower CLI response times
if hostname.startswith("ISE-"):
    time.sleep(10)
```

Versions between 1.0 and 4.7 were not recorded.

### Login checks before the backup

The PyQt5 window (`credential_manager_gui.py`) runs these checks when "Validate & Start Backup" is pressed:
1. **Empty fields**: all three passwords are required
2. **Reachability**: one ping to the backup server (Windows `ping -n` syntax)
3. **Logins**: one switch with the personal account, one ISE node with `admin`, the backup server with its account
4. **On failure**: shows each failed device with the first 50 characters of the error and clears the fields
5. **On success**: closes the window and the backup starts

A wrong password is caught before any device is backed up, not halfway through the run. Closing the window with its title bar button skips the checks, and the run continues with whatever was typed.

## Installation

### Prerequisites

- Python 3.10 or newer
- Windows, with a desktop session for the password window (the backup path is built under `C:\Users\<USERNAME>`)
- Network reach to the devices and the backup server (the ping check assumes a VPN)
- SSH accounts on the devices

### Libraries

```bash
pip install -r requirements.txt
```

### Setup

Everything is hard-coded in `main()` of `network-backup-orchestrator.py`. Edit:

```python
device_names = {
    "10.0.0.10": "CORE-SW-01",
    "10.0.0.20": "ISE-PRIMARY",
    "10.0.0.30": "ASA-FW-01",
    # one entry per device: IP to hostname
}

nexus_switches = ["10.0.0.10", "10.0.0.12", "10.0.0.13"]
asr_routers = ["10.0.0.40", "10.0.0.11"]
ise_appliances = ["10.0.0.20", "10.0.0.21"]
asa_firewalls = ["10.0.0.30", "10.0.0.31"]

backup_server_ip = "10.0.0.50"
backup_server_user = "backupuser"
```

The ASA context names are in `asa_connection_handler()`:

```python
contexts = ["SYSTEM", "MGMT", "DMZ", "BACKEND", "FRONTEND"]
```

The test devices of the password window are in `credential_manager_gui.py`.

## Usage

```bash
python network-backup-orchestrator.py
```

### Workflow

1. **Folders**: creates `logs`, `todayBackup` and `backupArchive` if missing
2. **Passwords**: the PyQt5 window asks for the personal, ISE admin and backup server passwords and checks them
3. **Backup**: IOS routers, Nexus switches, ISE nodes, then ASA firewalls, one at a time, into `todayBackup`
4. **Upload**: every file in `todayBackup` goes by SFTP to the backup server's login directory; the remote `ls -l` is printed
5. **Archive**: the files move from `todayBackup` to `backupArchive\YYYYMMDD_backup`

### Output structure

```
C:\Users\<USERNAME>\Documents\NetworkBackups\
+-- todayBackup\        files of the current run (empty after a successful run)
+-- backupArchive\
|   +-- 20240310_backup\
|       +-- CORE-SW-01_20240310_143022.cfg
|       +-- ASA-FW-01_20240310_143022.cfg
|       +-- ASA-FW-01_MGMT_20240310_143022.cfg
+-- logs\               Paramiko SFTP log of each run
    +-- 20240310_143022_paramiko_SFTP.log
```

All files of a run share the run's start time in their names.

## Troubleshooting

**Backup server not reachable**
- Connect the VPN before starting
- Check by hand: `ping 10.0.0.50`

**Authentication failed**
- Check the password is current and the account is not locked
- ISE uses its own `admin` password

**ISE output cut short**
- The script waits 10 seconds after each ISE command
- The Netmiko connect timeout is `timeout=90` in `connection_handler()`; raise it if needed

**Some devices missing from the backup**
- Device errors are printed to the console only; the `logs` folder holds the SFTP log, not device errors
- Try the device by hand over SSH

**Upload failed**
- The run stops; the files stay in `todayBackup` and are not archived

## Lessons learned

1. **Check logins first**: a wrong password found before the run costs one retry, not a half-finished backup.
2. **Timing matters**: ISE needed a fixed wait after each command (v5.0).
3. **ASA contexts**: backing up only the system context misses the configuration of each security context.

### Known limitations

- **Hard-coded inventory**: device IPs, groups and contexts live in the code
- **Sequential**: one device at a time
- **No retry**: a failed device is skipped
- **No notification**: the outcome is printed only
- **Windows only**: hard-coded path, Windows `ping` syntax, and a desktop session for the window
- **`write memory` on ASA**: a backup changes each context's startup configuration
- **Title bar close**: closing the password window skips the checks

## Possible improvements

- [ ] Inventory in a YAML or JSON file
- [ ] Parallel connections
- [ ] E-mail on success or failure
- [ ] Headless mode (passwords from a secrets store), then scheduled runs
- [ ] Diff against the previous backup
- [ ] Configuration compliance checks
- [ ] Other vendors (Juniper, Arista, Palo Alto)
- [ ] Back up without `write memory`

## Licence

MIT, see [LICENSE](LICENSE).

## Author

**Gabriele Saronni**, network engineer.
[LinkedIn](https://linkedin.com/in/gabriele-s-54514173) | [GitHub](https://github.com/gsaronni)
