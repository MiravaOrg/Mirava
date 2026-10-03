# Mirava — 简体中文指南

Mirava 是一个软件镜像与软件包仓库目录，目标是提供快速、稳定的访问，尤其适用于伊朗网络环境。英文 `README.md` 是项目主文档；本文件用简体中文说明新版用法和交互菜单。

## 🌐 Languages

[**English (Primary)**](README.md) · [**فارسی**](README.fa.md) · [**العربية**](README.ar.md) · [**Русский**](README.ru.md) · [**简体中文**](README.zh-CN.md)

---

## 项目概览

Mirava 是一个软件镜像与软件包仓库目录，目标是提供快速、稳定的访问，尤其适用于伊朗网络环境。英文 `README.md` 是项目主文档；本文件用简体中文说明新版用法和交互菜单。

## 主要功能

- 自动识别 Linux 发行版与包管理器
- benchmark 前验证真实仓库元数据
- 并行测速并按下载速度与 TTFB 排名
- 本地/全球 DNS benchmark 与管理
- 对受支持的配置变更进行备份和回滚
- 提供 Doctor、后端信息、系统/网络概览及非交互 CLI
- 运行时不再依赖 `yq` 或 PyYAML

## 镜像与 DNS 数据

镜像与 DNS 的权威数据源是 [`mirrors_list.yaml`](mirrors_list.yaml)。为避免各语言版本发生数据漂移，完整镜像表保留在英文 README 与 YAML 数据文件中。

## 🚀 使用方法

### 推荐运行方式

```bash
git clone https://github.com/MiravaOrg/Mirava.git
cd Mirava
chmod +x check_mirrors.sh
./check_mirrors.sh
```

在交互式终端中无参数运行 `./check_mirrors.sh` 会自动打开菜单；在非交互环境中无参数运行会执行全部镜像检查。

### 交互菜单

| Key | Action | Description |
| ---: | --- | --- |
| `1` | 优化当前 Linux 系统的软件源 | 识别发行版和包管理器，验证兼容仓库，进行测速和排名，并在确认后可应用最快的兼容镜像。 |
| `2` | 查找最快的软件源/包镜像 | 选择任意 package/repository 类型后验证并 benchmark 候选镜像；如果与当前系统仓库家族匹配，还可选择应用。 |
| `3` | 检查所有已注册镜像/包 | 并行检查全部 endpoint，并显示进度与可达/不可达结果。 |
| `4` | DNS benchmark 与管理 | 打开 Local/Global/All 测试、显示当前 DNS、可选应用最快的两个 DNS，并可重置 Mirava 管理的 DNS 变更。 |
| `5` | 显示当前 DNS | 只读取并显示当前 DNS，不修改系统。 |
| `6` | 显示服务器/网络概览 | 显示主机名、内存/运行时间、OS/架构、可用时的公网 IP/位置、DNS、Linux 仓库与 Docker 软件源。 |
| `7` | 显示检测到的后端 | 显示 OS、版本、codename、包管理器、仓库家族以及是否支持自动应用。 |
| `8` | 列出支持的 package 类型 | 从 YAML 数据中输出 package/repository 类型。 |
| `9` | Doctor / 数据验证 | 检查运行命令、Python、后端识别、YAML 数据以及 root/sudo/doas 权限路径。 |
| `0` | 退出 | 退出交互菜单。 |

### DNS 子菜单

| Key | Action |
| ---: | --- |
| `1` | 查找最快的伊朗/本地 DNS |
| `2` | 查找最快的全球 DNS |
| `3` | 在全部导入 DNS 中测速 |
| `4` | 显示当前 DNS |
| `5` | 重置 Mirava 管理的 DNS 变更 |
| `0` | 返回 |

### 命令行选项

```bash
./check_mirrors.sh --menu
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
./check_mirrors.sh --help
```

## 支持的后端

自动应用支持 Ubuntu/Debian（APT）、Fedora/Rocky/AlmaLinux/CentOS（DNF/YUM）、Arch/Manjaro（Pacman）、Alpine（APK）以及 openSUSE（Zypper）。对于可识别家族但布局不完全确定的衍生发行版，可以 benchmark，但 Mirava 会避免自动重写仓库配置。

## 安全机制

对受支持的配置变更会先创建备份。交互式应用需要确认；非交互式仓库应用必须显式使用 `--apply-system-repo --yes`。备份存放于 `/var/backups/mirava`。

## ✨ 本次更新

- 新增完整交互菜单，并在 TTY 中自动打开
- 可 bootstrap 基础依赖，并移除 `yq`/PyYAML 运行时依赖
- 基于真实仓库元数据进行验证和 speed/TTFB benchmark
- 新增 DNS benchmark、应用与重置
- 新增跨发行版识别与安全的自动应用后端
- 新增 System Overview、Doctor 与完整 CLI
- 文档扩展为 5 种语言，英文仍为主文档

## 参与贡献

新增镜像时，请按现有结构修改 `mirrors_list.yaml`，在本地测试后向 `main` 分支提交 Pull Request。完整说明见 [`CONTRIBUTING.md`](CONTRIBUTING.md)。

## 🔗 Project

- Main repository: https://github.com/MiravaOrg/Mirava
- Website: https://miravaorg.ir
- X: https://x.com/miravaorg
- Telegram: https://t.me/miravaorg

---

跨发行版 Repository/DNS 优化器、交互菜单和多语言文档改进由 [**Farshid Sar**](https://github.com/farshidsar) 完成。
