# Mirava

>  Mirava is a curated list of Iranian package mirrors, providing reliable and fast access to essential software resources within Iran. 
<div align="left">

## 🌐 Languages / زبان‌ها

[**فارسی / Persian**](README.fa.md)

</div>

---

## Project Overview

Mirava is a comprehensive and fast collection of public software mirrors and package repositories hosted inside Iran.

The goal of this project is to provide **easy, fast, and reliable access** to up-to-date software packages for Iranian developers, companies, and users.  
Especially under conditions such as international internet restrictions, national network mode, or foreign connectivity outages, Mirava helps ensure continuity, stability, and high-speed access to essential resources.

This repository maintains an up-to-date list of trusted domestic mirrors for widely used open-source projects and package managers.

---

## Project Features

- A curated and frequently updated list of trusted mirrors inside Iran
- Bash script to check availability and health of each mirror
- Compatible with synchronization tools such as `rsync` and `wget`
- Lightweight and extensible data structure using YAML
- Automated nightly checks (CI-friendly)
- Reusable in other projects, operating systems, and internal servers

---

## Official Mirrors in Iran

| Mirror (Link) | Description | Covered Packages |
|--------------|-------------|------------------|
| [mirror.shatel.ir](https://mirror.shatel.ir) | Ubuntu mirror | Ubuntu, Debian, Kali repositories and installers |
| [mirrors.kubarcloud.com](https://mirrors.kubarcloud.com) | Kubar internal mirror with support | Linux kernel sources and various open-source archives |
| [repo-portal.ito.gov.ir](https://repo-portal.ito.gov.ir/repo) | Maintained by Iran Information Technology Organization | YUM/DNF (CentOS, Fedora, Rocky), Python, npm, Yarn, and more |
| [jamko.ir](https://jamko.ir) | Documentation and config examples | Maven, Gradle, Android SDK, APT, RPM, NuGet, Yarn, Composer, pip |
| [runflare.com/mirrors](https://runflare.com/mirrors) | Daily auto-updated with simple guides | Composer/Packagist, PyPI, npm, Node.js |
| [hub.hamdocker.ir](https://hub.hamdocker.ir) | Docker registry | Docker Registry |
| [repo.iut.ac.ir](https://repo.iut.ac.ir) | Comprehensive mirror by Isfahan University of Technology | Debian, Ubuntu, Mint, Arch, Manjaro, Alpine, Rocky, Fedora, OpenSUSE, OpenBSD, CTAN |
| [maven.myket.ir](https://maven.myket.ir) | Android-focused Maven mirror | Maven Central, Google Maven, JitPack |
| [arvancloud.ir/dev/linux-repository](https://www.arvancloud.ir/en/dev/linux-repository) | High-speed mirrors hosted on ArvanCloud | Debian, Ubuntu, CentOS, Alpine, Arch, OpenSUSE, Manjaro |
| [mirror.iranserver.com](https://mirror.iranserver.com) | High-speed mirrors by IranServer | Debian, Ubuntu, CentOS |
| [docker.mobinhost.com](https://docker.mobinhost.com) | Docker registry | Docker Registry |
| [mirror.mobinhost.com](https://mirror.mobinhost.com) | Comprehensive GNU/Linux mirrors | FreeBSD, AlmaLinux, Alpine, Arch, Debian, EPEL, Manjaro, MariaDB, MongoDB, Ubuntu, Zabbix |
| [arvancloud.ir/fa/dev/docker](https://www.arvancloud.ir/fa/dev/docker) | Docker mirror | Docker Registry |
| [focker.ir](https://focker.ir) | Docker mirror | Docker Registry |
| [en-mirror.ir](https://en-mirror.ir) | Gradle and Android libraries mirror | Google, Maven Central, JitPack |
| [docker.kernel.ir](https://docker.kernel.ir) | Docker registry | Docker Registry |
| [terraform.peaker.info](https://terraform.peaker.info) | Official Terraform proxy | Terraform |
| [mirror.afranet.com](http://mirror.afranet.com) | GNU/Linux distributions mirror | Debian, Ubuntu, CentOS |
| [ubuntu.pishgaman.net](https://ubuntu.pishgaman.net) | Ubuntu mirror | Ubuntu |
| [mirrors.pardisco.co](https://mirrors.pardisco.co) | GNU/Linux & programming package mirrors | Ubuntu, Debian, Alpine, PyPI, NPM, Go, NuGet, Docker, OmniOS |
| [cran.um.ac.ir](https://cran.um.ac.ir) | R packages mirror | CRAN |
| [ir.archive.ubuntu.com](https://ir.archive.ubuntu.com/ubuntu) | Official Ubuntu mirror | Ubuntu |
| [mirror.0-1.cloud](https://mirror.0-1.cloud) | Multi-distribution mirror | AlmaLinux, Alpine, Arch, Debian, Fedora, FreeBSD, Ubuntu, Windows |
| [mirror.manageit.ir](http://mirror.manageit.ir/ubuntu) | Ubuntu mirror | Ubuntu |
| [mirror.aminidc.com](http://mirror.aminidc.com) | GNU/Linux & Windows Server mirrors | Debian, RHEL, Rocky, Ubuntu, Windows Server |
| [ubuntu-mirror.kimiahost.com](https://ubuntu-mirror.kimiahost.com) | Ubuntu mirror | Ubuntu |
| [mirror.digitalvps.ir](https://mirror.digitalvps.ir/ubuntu) | Ubuntu mirror | Ubuntu |
| [ir.ubuntu.sindad.cloud](https://ir.ubuntu.sindad.cloud) | Ubuntu mirror | Ubuntu |
| [ir.centos.sindad.cloud](https://ir.centos.sindad.cloud) | CentOS mirror | CentOS |
| [ir.epel.sindad.cloud](https://ir.epel.sindad.cloud) | EPEL mirror | EPEL |
| [mirror.faraso.org](http://mirror.faraso.org) | CentOS, EPEL, Java & Chrome packages | CentOS, EPEL, Java Runtime, Java Dev |
| [chat.shhh.ir](https://chat.shhh.ir/dl) | DeltaChat mirror | DeltaChat |
| [mirror.atlantiscloud.ir](https://mirror.atlantiscloud.ir/) | Docker, Ubuntu, and NPM mirrors | Ubuntu, Docker Registry, NPM |
| [iran.chabokan.net](https://iran.chabokan.net/) | Programming package services | NPM, Python, PHP, Docker, NuGet |
| [repo.abrha.net](https://repo.abrha.net/) | GNU/Linux OS mirrors | Ubuntu, AlmaLinux, Debian, EPEL, Proxmox |
| [mirror.parsdev.com](https://mirror.parsdev.com/) | GNU/Linux distributions mirror | Ubuntu, AlmaLinux, Debian |
| [linuxmirrors.ir](https://linuxmirrors.ir/) | GNU/Linux distributions mirror | Debian, Ubuntu, Fedora, Rocky, Oracle Linux |

---

## 🧪 About `check_mirrors.sh`

This script verifies whether the mirrors defined in `mirrors_list.yaml` are actually reachable, especially under Iranian network conditions.

### Features

- Parallel execution for faster checks
- Resolves IPs using `dig` or `getent`
- Handles SSL issues using `--insecure`
- Terminal-friendly text output
- Works on Linux systems and domestic VPS servers

---

## How to Contributing to Mirava

If you know a reliable mirror (especially one located inside Iran and accessible without a VPN), we’d love to include it.

Before getting started, please read our contribution guidelines:

See [Contributing](https://github.com/MiravaOrg/Mirava/blob/main/CONTRIBUTING.md)

Thanks for helping improve the project!

---

### What Mirrors Are Useful?

- Hosted inside Iran and accessible without filtering
- Linux repositories (Debian, Ubuntu, Arch, etc.)
- Package registries: PyPI, npm, Docker, GitHub Releases
- Any service that helps during national network mode or sanctions

---

## 📢 Contact Info 

- 🔗 [X (twitter)](https://x.com/miravaorg)
- 📣 [Telegram Channel](https://t.me/miravaorg)
- 🔗 [Email](Miravaorg@proton.me)

---

## ☕ Support the Project

If you find this project useful and would like to support it:

[Buy me a coffee](https://www.coffeete.ir/geedook)

---

Special thanks to **Arman Taheri**  
[ArmanTaheriGhaleTaki](https://github.com/ArmanTaheriGhaleTaki)  
for contributing multiple mirror links.

