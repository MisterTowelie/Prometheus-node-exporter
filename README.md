# Auto install Prometheus Node Exporter system on Linux
[![Download](https://img.shields.io/badge/download-Bash-brightgreen.svg)](https://raw.githubusercontent.com/MisterTowelie/Prometheus-node-exporter-install/prometheus-node-exporter.sh)
[![License](https://img.shields.io/github/license/Shabinder/SpotiFlyer?style=flat-square)](https://www.gnu.org/licenses/gpl-3.0.html)

## System Required:
* Can work on armv*, mips, ppc64, riscv64, s390x.
* Can work on Debian, Ubuntu, CentOS(AlmaLinux), ArchLinux.
 (Tested on Debian11+(amd64 and Aaarch64), Ubuntu20+, Trisquel10+, not tested on other operating systems and platforms)
* Curl
* Sudo

## Prometheus Node Exporter installer
The Node Exporter is designed to monitor the host system.

[Prometheus Node Exporter GitHub](https://github.com/prometheus/node_exporter)

The auto-installation script for the Prometheus Node Exporter the purpose of quick and easy installation on your host

## Installing
It will install Prometheus Node Exporter, configure it, create a systemd service.
```bash
curl -O https://raw.githubusercontent.com/MisterTowelie/Prometheus-node-exporter-install/prometheus-node-exporter.sh && sudo chmod +x prometheus-node-exporter.sh
sudo ./prometheus-node-exporter.sh
```
Run the script again to update Node Exporter








