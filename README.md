# Mirava

>  Mirava is a curated list of Iranian package mirrors, providing reliable and fast access to essential software resources within Iran. 
<div align="left">

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Project Features](#project-features)
- [Official Mirrors in Iran](#official-mirrors-in-iran)
- [Global & Official Mirrors](#-global--official-mirrors)
- [Usage](#-usage)
- [What Mirava Does Now](#-what-mirava-does-now)
- [Changes in This Update](#-changes-in-this-update)
- [How to Contribute](#how-to-contribute-to-mirava)
- [Contact Info](#-contact-info)

## 🌐 Languages

[**English (Primary)**](README.md) · [**فارسی**](README.fa.md) · [**العربية**](README.ar.md) · [**Русский**](README.ru.md) · [**简体中文**](README.zh-CN.md)

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
| [liara.ir](https://liara.ir/mirrors) | Mirrors with documentation and config examples | Fedora, Alpine, OpenSUSE, Arch, Manjaro, CentOS, Ubuntu, Debian, Rocky, PyPI, NPM, Go, Composer, NuGet, Docker images Registry, Quay, Github, Microsoft, K8S  |
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
| [alldriver.ir](https://www.alldriver.ir) | A large repository for downloading hardware drivers (printers, GPUs, modems, and more) | Driver archive / mirror |
| [llm.targoman.ir](https://llm.targoman.ir/shares) | A multi-purpose mirror hosting datasets, LLM resources, software packages, ISO files, security tools, and development resources | Data & software mirror hub |
| [IranGit](https://scorpian.ir/) | A fast, modern, and powerful platform for searching, viewing, and downloading GitHub repositories with a professional, fully Persian user interface | GitHub Mirror |
| [Asiatech](https://mirror.10.ir.cdn.ir/) | Repository docker-images-group | Docker Registry |
| [Parmin](https://parmin.cloud/mirrors.html) | Maintained by Parmin | GitHub Mirror, Quay Registry, Docker Registry, GitLab Registry, NVIDIA Container Registry, Kubernetes Registry, Microsoft Registry, NPM, Go Proxy, Nuget, Composer, PyPI, Hugging Face |



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
| Tsinghua University TUNA Association (China) | [bfsu.edu.cn](https://mirrors.bfsu.edu.cn/) | TUNA (Tsinghua University Network Association) mirror | Slackware, Gentoo, Garuda, Deepin, Arch Linuxcn, NetBSD, Blackarch, MX Linux, Prometheus, PuTTY, QEMU, Zabbix and more |
| Tsinghua University TUNA Association (China) | [bfsu.edu.cn](https://mirrors.bfsu.edu.cn/) | TUNA (Tsinghua University Network Association) mirror | Slackware, Gentoo, Garuda, Deepin, Arch Linuxcn, NetBSD, Blackarch, MX Linux, Prometheus, PuTTY, QEMU, Zabbix and more |


---

## 🚀 Usage

Mirava v3.4.1 can be used interactively or through direct CLI options. When it is started in an interactive terminal without arguments, it opens the menu automatically. In non-interactive input/output, running without arguments falls back to checking all registered mirrors.

### Recommended interactive run

```bash
git clone https://github.com/MiravaOrg/Mirava.git
cd Mirava
chmod +x check_mirrors.sh
./check_mirrors.sh
```

To use only the script, download it first and then execute it. This lets the portable launcher install missing bootstrap dependencies and restart itself with Bash when necessary:

```bash
curl -fsSL https://raw.githubusercontent.com/MiravaOrg/Mirava/refs/heads/main/check_mirrors.sh -o check_mirrors.sh
chmod +x check_mirrors.sh
./check_mirrors.sh
```

### Interactive menu

| Key | Menu action | What it does |
| ---: | --- | --- |
| `1` | Optimize repository for this Linux system | Detects the distro/package manager, validates compatible repository layouts, benchmarks candidates, ranks them by measured speed and TTFB, and optionally applies the fastest compatible mirror after confirmation. |
| `2` | Find fastest repository/package mirror | Lets you choose any package/repository type from `mirrors_list.yaml`, validates and benchmarks matching mirrors, and shows a ranked result. If the selected type matches the detected system repository family, Mirava can also offer to apply it. |
| `3` | Check all registered mirrors/packages | Checks all registered mirror/package endpoints in parallel and reports reachable/unreachable results with adaptive progress output. |
| `4` | DNS benchmark & management | Opens the DNS submenu for local, global, or combined resolver benchmarks, current DNS display, optional application of the fastest pair, and reset of Mirava-managed DNS changes. |
| `5` | Show current DNS | Reads the system's currently configured DNS servers and prints them without changing anything. |
| `6` | Show server / network overview | Shows hostname, RAM/uptime, OS/architecture, public IP/location when available, current DNS, active Linux repository, and Docker package repository. |
| `7` | Show detected backend | Displays the detected OS ID/version/codename, native package manager, repository family, and whether automatic repository application is supported. |
| `8` | List supported package types | Prints package/repository types discovered from the YAML data file. |
| `9` | Doctor / data validation | Validates runtime commands, Python availability, distro/backend detection, YAML data, DNS/mirror statistics, and the available privilege path (`root`, `sudo`, or `doas`). |
| `0` | Exit | Leaves the interactive menu. |

#### DNS submenu

| Key | Action |
| ---: | --- |
| `1` | Benchmark Iranian/local DNS resolvers. |
| `2` | Benchmark global DNS resolvers. |
| `3` | Benchmark all imported DNS entries. |
| `4` | Show the current DNS configuration. |
| `5` | Reset DNS changes managed by Mirava back to automatic/default behavior where supported. |
| `0` | Return to the main menu. |

DNS ranking requires stable replies and measures real query latency with `dig`. After a successful benchmark, the interactive flow can offer to apply the two fastest measured resolvers.

### Direct CLI options

| Command | Purpose |
| --- | --- |
| `./check_mirrors.sh --menu` | Open the interactive menu explicitly. |
| `./check_mirrors.sh --system-repo` | Detect and benchmark the current system repository family; on a TTY it can optionally apply the selected mirror. |
| `./check_mirrors.sh --apply-system-repo --yes` | Detect, benchmark, and apply the fastest compatible system mirror non-interactively. The explicit `--yes` is required. |
| `./check_mirrors.sh --check-all` | Check every registered mirror/package endpoint. |
| `./check_mirrors.sh --fastest PACKAGE` | Benchmark mirrors for a package type such as `Ubuntu`, `Debian`, `PyPI`, or `npm`. Quote package names that contain spaces. |
| `./check_mirrors.sh --fastest-ubuntu` | Shortcut for benchmarking Ubuntu mirrors. |
| `./check_mirrors.sh --dns local` | Benchmark local DNS resolvers. |
| `./check_mirrors.sh --dns global` | Benchmark global DNS resolvers. |
| `./check_mirrors.sh --dns all` | Benchmark all DNS resolvers. |
| `./check_mirrors.sh --current-dns` | Show the current DNS servers. |
| `./check_mirrors.sh --system-info` | Show the server/network overview. |
| `./check_mirrors.sh --backend-info` | Show distro/package-manager detection results. |
| `./check_mirrors.sh --doctor` | Validate runtime dependencies, backend detection, and Mirava data. |
| `./check_mirrors.sh --list-packages` | List package types known by `mirrors_list.yaml`. |
| `./check_mirrors.sh --help` | Show built-in help. |

Useful environment variables include `MIRAVA_MIRROR_FILE`, `MIRAVA_JOBS`, `MIRAVA_BENCH_RUNS`, `MIRAVA_OS_RELEASE_FILE`, `MIRAVA_PACKAGE_MANAGER`, and `MIRAVA_SKIP_NETINFO`.

---

## 🧪 What Mirava does now

Mirava uses `check_mirrors.sh` for execution and `mirrors_list.yaml` for repository and DNS data.

### Server and network overview

The interactive menu starts with the official project link first, followed by the FarshidSar repository:

- Official: `https://github.com/MiravaOrg/Mirava`
- FarshidSar: `https://github.com/farshidsar/Mirava`

Before the menu options, Mirava renders a short system table with only the useful at-a-glance fields: server name with RAM/uptime, operating system with architecture, public IP/location, current DNS servers, the active Linux package repository, and the Docker package repository. DNS/repository/Docker values are re-read from the current system configuration when the menu is drawn.

Public IP/location lookup uses short timeouts and does not block the tool when unavailable. Set `MIRAVA_SKIP_NETINFO=1` to disable the external public-IP/location lookup. The same overview can be printed directly with `./check_mirrors.sh --system-info`.

### Automatic dependency bootstrap

Run from a clone:

```bash
chmod +x check_mirrors.sh
./check_mirrors.sh
```

On supported Linux families, Mirava detects the native package manager and installs missing runtime requirements when possible:

- bootstrap: `bash`, `curl`, `ca-certificates`
- data parsing: Python 3, only when it is missing
- DNS benchmark: the package that provides `dig` (`dnsutils`, `bind-utils`, `bind`, or `bind-tools`, depending on the distribution)

Mirava does not require `yq` or PyYAML at runtime.

### Repository detection, validation, and ranking

Mirava can detect the current Linux family, find compatible repository candidates, validate real repository metadata, benchmark valid endpoints, and rank them by measured transfer speed and TTFB. Duplicate repository URLs are removed from the data and candidates are de-duplicated before benchmarking.

During repository, DNS, and full mirror checks, Mirava redraws a single adaptive progress row in interactive terminals instead of printing a new line for every spinner tick. The row shows checked/total, percentage, successful/failed checks, active workers and remaining items; on wide terminals it can also show the current endpoint. The progress line automatically shortens to the terminal width so it does not wrap. Redirected/CI output uses plain log-friendly progress lines.

| Family | Supported systems | Backend / behavior |
| --- | --- | --- |
| APT | Ubuntu, Debian | validates `Release`, backs up APT configuration, applies the selected mirror, refreshes indexes, and rolls back when validation/application fails |
| DNF/YUM | Fedora, Rocky Linux, AlmaLinux, CentOS/Stream | validates `repomd.xml`, adds the selected repository while keeping existing repositories as fallback |
| Pacman | Arch Linux, Manjaro | validates repository databases, prioritizes the selected server, and preserves fallback mirrors |
| APK | Alpine Linux | validates `APKINDEX.tar.gz`, backs up `/etc/apk/repositories`, applies the selected mirror, and rolls back on failure |
| Zypper | openSUSE Leap/Tumbleweed | validates `repomd.xml`, adds the selected repository with higher priority, and preserves existing repositories |

Known derivatives can still be benchmarked by repository family, but Mirava avoids automatic configuration rewrites when the exact distro layout is not known.

### DNS benchmark and management

Mirava contains local and global DNS candidates in `mirrors_list.yaml`. It measures real DNS query latency with `dig`, removes duplicate IPs, ranks responsive resolvers, and can optionally apply the fastest pair.

DNS application supports NetworkManager, `systemd-resolved`, `resolvconf/openresolv`, `dhcpcd`, and a backed-up `/etc/resolv.conf` fallback. Mirava can also display the current DNS configuration or reset Mirava-managed DNS changes.

### Safety

Before changing repository or DNS configuration, Mirava creates backups where applicable. Interactive system changes require confirmation, and non-interactive repository application requires the explicit `--yes` flag. Backups are stored under `/var/backups/mirava`.

### Interactive menu and CLI

Running `./check_mirrors.sh` in a terminal opens the menu. Available CLI operations include:

```bash
./check_mirrors.sh --system-repo
./check_mirrors.sh --apply-system-repo --yes
./check_mirrors.sh --check-all
./check_mirrors.sh --fastest Ubuntu
./check_mirrors.sh --fastest-ubuntu
./check_mirrors.sh --dns local
./check_mirrors.sh --dns global
./check_mirrors.sh --dns all
./check_mirrors.sh --current-dns
./check_mirrors.sh --system-info
./check_mirrors.sh --backend-info
./check_mirrors.sh --doctor
./check_mirrors.sh --list-packages
```

For a one-file download, save the script first and then run it so the bootstrap stage can restart itself with Bash if necessary:

```bash
curl -fsSL https://raw.githubusercontent.com/MiravaOrg/Mirava/refs/heads/main/check_mirrors.sh -o check_mirrors.sh
chmod +x check_mirrors.sh
./check_mirrors.sh
```

The "fastest" result is specific to the current machine and network at test time and may change with routing, filtering, congestion, and mirror load.

Cross-distribution repository/DNS optimizer and menu enhancements: **FarshidSar**.

---

## ✨ Changes in This Update

This update turns `check_mirrors.sh` from a basic mirror reachability checker into a portable cross-distribution repository and DNS optimizer while keeping mirror discovery and validation in one project.

- Added a portable POSIX launcher that can bootstrap `bash`, `curl`, and CA certificates with supported native package managers.
- Removed the runtime `yq`/PyYAML requirement; Mirava now uses its embedded data reader and installs Python 3 only when it is missing.
- Added Linux distribution and package-manager detection plus safe repository workflows for APT, DNF/YUM, Pacman, APK, and Zypper families.
- Added real repository metadata validation, parallel benchmarking, average transfer-speed/TTFB ranking, candidate de-duplication, and adaptive terminal progress.
- Added automatic backup/rollback safeguards for supported repository changes and backups under `/var/backups/mirava`.
- Added DNS benchmarking for local/global resolvers plus optional DNS apply/reset support through NetworkManager, `systemd-resolved`, `resolvconf/openresolv`, `dhcpcd`, or a guarded `/etc/resolv.conf` fallback.
- Added system/network overview, backend information, package listing, doctor/data validation, and non-interactive CLI modes.
- Added multilingual documentation in English, Persian, Arabic, Russian, and Simplified Chinese. English remains the primary README.

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

Enhancements to the cross-distribution repository/DNS optimizer, interactive menu, and multilingual documentation by [**Farshid Sar**](https://github.com/farshidsar).
