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
| [shatel.ir](https://mirror.shatel.ir) | Ubuntu mirror | Ubuntu, Debian, Kali repositories and installers |
| [kubarcloud.com](https://mirrors.kubarcloud.com) | Kubar internal mirror with support | Linux kernel sources and various open-source archives |
| [repo-portal.ito.gov.ir](https://repo-portal.ito.gov.ir/repo) | Maintained by Iran Information Technology Organization | CentOS, Fedora, Rocky, Python, npm, Yarn, and more |
| [jamko.ir](https://jamko.ir) | Documentation and config examples | Maven, Gradle, Android SDK, APT, RPM, NuGet, Yarn, Composer, pip |
| [runflare.com](https://runflare.com/mirrors) | Daily auto-updated with simple guides | Composer/Packagist, PyPI, npm, Node.js |
| [hub.hamdocker.ir](https://hub.hamdocker.ir) | Docker registry | Docker Registry |
| [repo.iut.ac.ir](https://repo.iut.ac.ir) | Comprehensive mirror by Isfahan University of Technology | Debian, Ubuntu, Mint, Arch, Manjaro, Alpine, Rocky, Fedora, OpenSUSE, OpenBSD, CTAN |
| [maven.myket.ir](https://maven.myket.ir) | Android-focused Maven mirror | Maven Central, Google Maven, JitPack |
| [arvancloud.ir](https://www.arvancloud.ir/en/dev/linux-repository) | High-speed mirrors hosted on ArvanCloud | Debian, Ubuntu, CentOS, Alpine, Arch, OpenSUSE, Manjaro |
| [iranserver.com](https://mirror.iranserver.com) | High-speed mirrors by IranServer | Debian, Ubuntu, CentOS |
| [docker.mobinhost.com](https://docker.mobinhost.com) | Docker registry | Docker Registry |
| [mobinhost.com](https://mirror.mobinhost.com) | Comprehensive GNU/Linux mirrors | FreeBSD, AlmaLinux, Alpine, Arch, Debian, EPEL, Manjaro, MariaDB, MongoDB, Ubuntu, Zabbix |
| [arvancloud.ir](https://www.arvancloud.ir/fa/dev/docker) | Docker mirror | Docker Registry |
| [focker.ir](https://focker.ir) | Docker mirror | Docker Registry |
| [en-mirror.ir](https://en-mirror.ir) | Gradle and Android libraries mirror | Google, Maven Central, JitPack |
| [docker.kernel.ir](https://docker.kernel.ir) | Docker registry | Docker Registry |
| [terraform.peaker.info](https://terraform.peaker.info) | Official Terraform proxy | Terraform |
| [afranet.com](http://mirror.afranet.com) | GNU/Linux distributions mirror | Debian, Ubuntu, CentOS |
| [ubuntu.pishgaman.net](https://ubuntu.pishgaman.net) | Ubuntu mirror | Ubuntu |
| [pardisco.co](https://mirrors.pardisco.co) | GNU/Linux & programming package mirrors | Ubuntu, Debian, Alpine, PyPI, NPM, Go, NuGet, Docker, OmniOS |
| [cran.um.ac.ir](https://cran.um.ac.ir) | R packages mirror | CRAN |
| [ir.archive.ubuntu.com](https://ir.archive.ubuntu.com/ubuntu) | Official Ubuntu mirror | Ubuntu |
| [0-1.cloud](https://mirror.0-1.cloud) | Multi-distribution mirror | AlmaLinux, Alpine, Arch, Debian, Fedora, FreeBSD, Ubuntu, Windows |
| [manageit.ir](http://mirror.manageit.ir/ubuntu) | Ubuntu mirror | Ubuntu |
| [aminidc.com](http://mirror.aminidc.com) | GNU/Linux & Windows Server mirrors | Debian, RHEL, Rocky, Ubuntu, Windows Server |
| [kimiahost.com](https://ubuntu-mirror.kimiahost.com) | Ubuntu mirror | Ubuntu |
| [digitalvps.ir](https://mirror.digitalvps.ir/ubuntu) | Ubuntu mirror | Ubuntu |
| [ir.ubuntu.sindad.cloud](https://ir.ubuntu.sindad.cloud) | Ubuntu mirror | Ubuntu |
| [ir.centos.sindad.cloud](https://ir.centos.sindad.cloud) | CentOS mirror | CentOS |
| [ir.epel.sindad.cloud](https://ir.epel.sindad.cloud) | EPEL mirror | EPEL |
| [faraso.org](http://mirror.faraso.org) | CentOS, EPEL, Java & Chrome packages | CentOS, EPEL, Java Runtime, Java Dev |
| [chat.shhh.ir](https://chat.shhh.ir/dl) | DeltaChat mirror | DeltaChat |
| [atlantiscloud.ir](https://mirror.atlantiscloud.ir/) | Docker, Ubuntu, and NPM mirrors | Ubuntu, Docker Registry, NPM |
| [iran.chabokan.net](https://iran.chabokan.net/) | Programming package services | NPM, Python, PHP, Docker, NuGet |
| [repo.abrha.net](https://repo.abrha.net/) | GNU/Linux OS mirrors | Ubuntu, AlmaLinux, Debian, EPEL, Proxmox |
| [parsdev.com](https://mirror.parsdev.com/) | GNU/Linux distributions mirror | Ubuntu, AlmaLinux, Debian |
| [linuxmirrors.ir](https://linuxmirrors.ir/) | GNU/Linux distributions mirror | Debian, Ubuntu, Fedora, Rocky, Oracle Linux |
| [kargadan.ir](https://mirror.kargadan.ir/) | High-Speed Package Mirror for Iranian Developers | NuGet, PyPI, Yarn, Docker Registry, MCR, Maven/Gradle, Go Proxy, Composer,
| [hyperclouds.ir](https://mirrors.hyperclouds.ir/) | Hyperclouds Mirrors | Cargo, Ubuntu, Alpine, Debian, RubyGems, Go Proxy, PyPI, Docker Registry |
| [gitdl.theazizi.ir](https://gitdl.theazizi.ir) | A tool designed to bypass GitHub download restrictions for releases and source code | Simple GitHub release proxy  |
---

## 🌍 Global & Official Mirrors

This project also includes selected high-quality global mirrors from other countries and official upstream sources.  
These mirrors provide redundancy, higher availability, and alternative routing paths in case of regional network instability.

The following mirrors are well-known, actively maintained, and widely used within the open-source community.

| Mirror / Country | URL | Description | Covered Packages |
| ---------------- | --- | ----------- | ---------------- |
| NYIST Mirror (China) | [nyist.edu.cn](https://mirror.nyist.edu.cn/) | University-operated open-source mirror providing a wide range of Linux distributions and language package repositories | Debian, Ubuntu, CentOS, Fedora, Arch Linux, Alpine, openSUSE, Kali, Linux Mint, PyPI, CRAN, CPAN, RubyGems and more |
| NJU Mirror (China) | [nju.edu.cn](https://mirror.nju.edu.cn/) | Nanjing University official mirror site serving major Linux distributions and development ecosystems | Debian, Ubuntu, CentOS, Fedora, Arch Linux, Alpine, openSUSE, Manjaro, Gentoo, PyPI and more |
| Huawei Cloud  Mirror (China) | [huaweicloud.com](https://mirrors.huaweicloud.com/home) | Enterprise-grade mirror service operated by Huawei Cloud with CDN acceleration and global accessibility. | Debian, Ubuntu, CentOS Stream, Fedora, Arch Linux, Alpine, openEuler, PyPI, Maven, Docker, Kubernetes and more |
| USTC Mirror (China) | [ustc.edu.cn](https://mirrors.ustc.edu.cn/) | University of Science and Technology of China (USTC) mirror | Debian, Ubuntu, CentOS, Fedora, Arch Linux, Alpine, openSUSE, Kali, Manjaro, PyPI, CRAN, Homebrew and more |
| Yandex Mirror (Russia) | [yandex.ru](https://mirror.yandex.ru/) | High-speed Russian mirror operated by Yandex providing major Linux distributions and open-source repositories | Debian, Ubuntu, CentOS, Fedora, Arch Linux and more |
| Tsinghua University Mirror (China) | [tuna.tsinghua.edu.cn](https://mirrors.tuna.tsinghua.edu.cn/) | TUNA (Tsinghua University Network Association) mirror | Debian, Ubuntu, CentOS, Fedora, Arch Linux, Alpine, openSUSE, Kali, Manjaro, PyPI, Homebrew, Docker and more |

---

## 🧪 About `check_mirrors.sh`

This script verifies whether the mirrors defined in `mirrors_list.yaml` are actually reachable, especially under Iranian network conditions.

### Quick Run

You can run the script directly without cloning the repository:

```bash
curl -fsSL https://raw.githubusercontent.com/MiravaOrg/Mirava/refs/heads/main/check_mirrors.sh | bash
```

### Features

- Parallel execution for faster checks
- Resolves IPs using `dig` or `getent`
- Handles SSL issues using `--insecure`
- Terminal-friendly text output
- Works on Linux systems and domestic VPS servers

---

## How to Contribute to Mirava

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

Special thanks to **Arman Taheri**  
[ArmanTaheriGhaleTaki](https://github.com/ArmanTaheriGhaleTaki)  
for contributing multiple mirror links.

