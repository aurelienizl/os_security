# System Hardening Scripts

This project contains a collection of shell scripts designed to harden a Linux system by applying various security configurations on ~900 shell lines.
This project targets Ubuntu 22.04 LTS and Debian 12 systems, but it can be adapted to other distributions.

## Project Structure

## Scripts Overview

- **hard_authid.sh**: Hardens authentication and identification settings.
- **hard_diskpart.sh**: Hardens disk partition settings.
- **hard_file.sh**: Hardens file permissions and settings.
- **hard_hardware.sh**: Hardens hardware-related settings.
- **hard_kernel_memory.sh**: Hardens kernel memory settings.
- **hard_kernel.sh**: Hardens general kernel settings.
- **hard_network.sh**: Hardens network settings.
- **hard_sysctl.sh**: Hardens sysctl settings.
- **hard_yama.sh**: Hardens Yama security module settings.
- **log.sh**: Contains logging functions used by other scripts.
- **main.sh**: Main script that runs all the hardening scripts in the correct order.

## Usage

1. Clone the repository:
    ```sh
    git clone <repository-url>
    cd <repository-directory>
    ```

2. Ensure all scripts have execute permissions:
    ```sh
    chmod +x src/verify/*.sh
    ```

3. Run the main script as root:
    ```sh
    sudo ./src/verify/main.sh
    ```

## Configuration Files

The `config` directory contains configuration files used by the hardening scripts:
- **audit.rules**: Rules for the audit daemon.
- **common-auth**: Common authentication settings.
- **common-password**: Common password settings.
- **sshd_config**: SSH daemon configuration.
- **su**: Configuration for the `su` command.

All configuration files can be updated to match the system's requirements.

## Logging

The scripts use the logging functions defined in [`log.sh`](src/verify/log.sh) to log messages with different severity levels (INFO, ERROR).

## License

This project is licensed under the terms of the [LICENSE](LICENSE) file.
