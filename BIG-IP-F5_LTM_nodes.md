# F5 BIG-IP Patching Automation

**Node switch-off and switch-on for a patching window: from about 50 minutes by hand to under 1 minute**

Background for `f5-patching-automation.sh`. How to run it is in the [README](README.md#f5-patching-automation).

## The problem

In a telco data-centre network run as a managed service, servers behind F5 BIG-IP LTM load balancers were patched in three patch groups (T71, T72, T73). Before a group was patched, its LTM nodes had to be taken out of service; after patching, they had to be put back.

The nodes sit in four administrative partitions (`F5_BE-PRO`, `F5_BE-OMT`, `F5_FE-DMZ`, `F5_FE-DMZ-ext`). The three groups together cover 45 partition and node entries (37 distinct nodes, some of which appear in more than one partition).

**The manual process, per window:**
- **22:00**: disable the group's nodes, one tmsh command per node and partition (about 50 minutes)
- **22:00 to 02:00**: patching window
- **02:00**: enable the nodes again (about 50 minutes more)

Each node meant typing a partition and a node name by hand, late at night, on a production load balancer.

## The solution

A Bash script that runs on the BIG-IP and calls tmsh for every node of the chosen patch group:
- Interactive menu, or two command-line arguments for non-interactive use (for example from cron)
- List, disable or enable all nodes of one group in one step
- All four partitions handled in the same run

**Time: about 50 minutes by hand, under 1 minute with the script.**

What it changes in practice:
- The node lists are written once, in the script, instead of being typed at every window.
- Every group is handled with the same commands in the same order.
- Anyone with tmsh access on the BIG-IP can run it from the menu.

## Technical details

### Partitions

```
F5_BE-PRO       Backend production nodes
F5_BE-OMT       Backend OMT nodes
F5_FE-DMZ       Frontend DMZ nodes
F5_FE-DMZ-ext   External DMZ nodes
```

### Actions

- **List** (`l`): prints the node and session lines of each node in the group
- **Disable** (`d`): sets each node to `session user-disabled` (no new sessions; existing connections continue)
- **Enable** (`e`): sets each node to `session user-enabled` (back in service)

### Patch groups

Each patch group (T71, T72, T73) has its own function with its own hard-coded node lists, one list per partition:

| Group | Function | Node entries |
|-------|----------|--------------|
| T71 | `t71-switcher` | 16 |
| T72 | `t72-switcher` | 16 (one node listed twice in `F5_FE-DMZ-ext`) |
| T73 | `t73-switcher` | 14 |

The script does not read the result of each tmsh command. To confirm a change, run the list action on the group afterwards.

## Usage

### Prerequisites

- A BIG-IP with Bash and tmsh access
- Permission to modify LTM nodes in the four partitions

### Running the script

```bash
chmod +x f5-patching-automation.sh
./f5-patching-automation.sh          # interactive menu
./f5-patching-automation.sh 1 d      # T71, disable, no prompts
```

### Interactive session

```
Which patching scenario? [1/2/3/Q to quit] >> 1
Action: [L]ist / [D]isable / [E]enable / [Q]uit >> l
=== Processing T71 Patching Scenario ===
[node and session lines]

Action: [L]ist / [D]isable / [E]enable / [Q]uit >> d
=== Processing T71 Patching Scenario ===

Action: [L]ist / [D]isable / [E]enable / [Q]uit >> q
```

## Code notes

### One function per patch group

```bash
t71-switcher()  # T71 nodes
t72-switcher()  # T72 nodes
t73-switcher()  # T73 nodes
```

### Input checks

- Interactive mode accepts only 1, 2, 3 or Q for the group and L, D, E or Q for the action.
- Non-interactive mode accepts exactly two arguments, a group (1 to 3) and an action (l, d, e), and exits with status 1 otherwise.
- The list action shows the current state before a change; it is a separate step, not a dry run of disable or enable.

### Readability

- Variable names follow the partition (`f5BePro`, `f5BeOmt`, and so on).
- A comment block before each function and a version history in the script header.

## Lessons learned

1. **Simple was enough**: Bash and tmsh on the device itself, nothing to install.
2. **A menu lowers the bar**: the person on shift picks a number and a letter instead of typing node names.
3. **Incremental development**: the first versions did not cover all three groups; v1.3 added the rest.

### Version history

From the script header:

- **v0.1.0** (2022-07-26): initial creation
- **v0.1.1** (2022-07-28): for loops to reduce repetition
- **v0.1.2** (2022-07-28): list and disable logic refactored
- **v1.3** (2022-08-01): support for all three patching scenarios
- **v1.4** (2022-08-01): T71, T72 and T73 workflows completed
- **v1.5** (2025-09-30): code and comments tidied
- **v1.6** (2025-10-22): non-interactive mode for cron

In the companion runbook ([docs-as-code-showcase](https://github.com/gsaronni/docs-as-code-showcase)) the script appears under its earlier name, `t7_all-main_v01.3.sh`.

## Possible improvements

- [ ] Pre-flight check: compare the node count with the expected one before disabling
- [ ] Check the result of each tmsh command and stop or roll back on a partial failure
- [ ] Execution log for an audit trail (today: redirect the output to a file)
- [x] Scheduled runs (non-interactive mode, v1.6)
- [ ] Node lists in a data file instead of the script

## Licence

MIT, see [LICENSE](LICENSE).

## Author

**Gabriele Saronni**, network engineer.
[LinkedIn](https://linkedin.com/in/gabriele-s-54514173) | [GitHub](https://github.com/gsaronni)
