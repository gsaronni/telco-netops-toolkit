# Changelog

Changes per tool, taken from the version notes in each script's header.

## Repository

### Unreleased
- Added the MIT LICENSE file.
- Removed the Dockerfile, Compose file and .dockerignore: the backup tool needs a desktop session for its PyQt5 window and writes to a hard-coded Windows path, so the container could not run it.
- README, changelog and code comments rewritten to match the code.

## Network Backup Orchestrator

### [5.0] - 2023-09-08
- Fixed ISE timing issues with a wait after each command, for slow CLI responses.

### [4.9] - 2023-07-14
- Added password validation.

### [4.8] - 2023-06-26
- Added Ctrl+C exception handling.
- Fixed devices with slow CLI response.

### [4.7] - 2023-01-20
- User name taken from the environment.
- Fixed ASR900 timing issues with `send_command_timing`.

Versions between 1.0 and 4.7 were not recorded.

### [1.0] - 2022-04-05
- Initial release.

## F5 BigIP Patching Automation

### [1.6] - 2025-10-22
- Non-interactive mode: scenario and action as two arguments, for cron.

### [1.5] - 2025-09-30
- Comments and formatting.

### [1.4] - 2022-08-01
- Completed the T71, T72 and T73 workflows.

### [1.3] - 2022-08-01
- Support for all three patching scenarios.

### [0.1.2] - 2022-07-28
- Refactored the list and disable command logic.

### [0.1.1] - 2022-07-28
- Loops instead of repeated commands.

### [0.1.0] - 2022-07-26
- Initial creation.
