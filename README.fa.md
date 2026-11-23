# Mirava — راهنمای فارسی

Mirava مجموعه‌ای از mirrorهای نرم‌افزاری و مخازن بسته است که برای دسترسی سریع و پایدار، به‌خصوص از داخل ایران، نگهداری می‌شود. نسخهٔ انگلیسی `README.md` سند اصلی پروژه است و این فایل راهنمای فارسی قابلیت‌ها و Usage جدید را پوشش می‌دهد.

## 🌐 Languages

[**English (Primary)**](README.md) · [**فارسی**](README.fa.md) · [**العربية**](README.ar.md) · [**Русский**](README.ru.md) · [**简体中文**](README.zh-CN.md)

---

## معرفی

Mirava مجموعه‌ای از mirrorهای نرم‌افزاری و مخازن بسته است که برای دسترسی سریع و پایدار، به‌خصوص از داخل ایران، نگهداری می‌شود. نسخهٔ انگلیسی `README.md` سند اصلی پروژه است و این فایل راهنمای فارسی قابلیت‌ها و Usage جدید را پوشش می‌دهد.

## قابلیت‌های اصلی

- تشخیص خودکار توزیع لینوکس و package manager
- اعتبارسنجی واقعی metadata مخزن قبل از benchmark
- رتبه‌بندی بر اساس سرعت انتقال و TTFB با workerهای موازی
- benchmark و مدیریت DNSهای Local و Global
- backup و rollback برای تغییرات پشتیبانی‌شده
- Doctor، نمایش backend، نمای سرور/شبکه و CLI غیرتعاملی
- بدون وابستگی runtime به `yq` یا PyYAML

## فهرست Mirror و DNS

دادهٔ اصلی mirrorها و DNSها در [`mirrors_list.yaml`](mirrors_list.yaml) نگهداری می‌شود. برای جلوگیری از اختلاف بین ترجمه‌ها، جدول کامل mirrorها در README انگلیسی و فایل YAML مرجع باقی می‌ماند.

## 🚀 نحوهٔ استفاده

### اجرای پیشنهادی

```bash
git clone https://github.com/MiravaOrg/Mirava.git
cd Mirava
chmod +x check_mirrors.sh
./check_mirrors.sh
```

اجرای `./check_mirrors.sh` بدون آرگومان در ترمینال، منوی تعاملی را باز می‌کند. در حالت non-interactive بدون آرگومان، اسکریپت به `--check-all` می‌رود.

### منوی تعاملی

| Key | Action | Description |
| ---: | --- | --- |
| `1` | بهینه‌سازی Repository سیستم | توزیع و package manager را تشخیص می‌دهد، mirrorهای سازگار را validate و benchmark می‌کند، رتبه‌بندی می‌کند و پس از تأیید می‌تواند سریع‌ترین گزینهٔ سازگار را اعمال کند. |
| `2` | پیدا کردن سریع‌ترین mirror/package | نوع package را از لیست انتخاب می‌کنید؛ Mirava candidateها را validate و benchmark می‌کند. اگر همان خانوادهٔ repository سیستم باشد، امکان Apply اختیاری هم ارائه می‌شود. |
| `3` | بررسی همهٔ mirror/packageها | همهٔ endpointهای ثبت‌شده را موازی بررسی می‌کند و نتیجهٔ reachable/unreachable را همراه progress نشان می‌دهد. |
| `4` | Benchmark و مدیریت DNS | زیرمنوی Local/Global/All، نمایش DNS فعلی، Apply اختیاری سریع‌ترین pair و Reset تغییرات DNS را باز می‌کند. |
| `5` | نمایش DNS فعلی | DNSهای فعلی سیستم را فقط نمایش می‌دهد. |
| `6` | نمای سرور / شبکه | Hostname، RAM/Uptime، OS/Arch، Public IP/Location در صورت دسترسی، DNS، repository فعال و Docker repo را نمایش می‌دهد. |
| `7` | نمایش Backend تشخیص‌داده‌شده | OS، نسخه، codename، package manager، خانوادهٔ repository و پشتیبانی Auto-Apply را نشان می‌دهد. |
| `8` | لیست نوع packageها | package/repository typeهای موجود در YAML را فهرست می‌کند. |
| `9` | Doctor / Data Validation | runtime، Python، backend، دادهٔ YAML و privilege path را بررسی می‌کند. |
| `0` | خروج | از منو خارج می‌شود. |

### زیرمنوی DNS

| Key | Action |
| ---: | --- |
| `1` | سریع‌ترین DNS ایرانی/Local |
| `2` | سریع‌ترین DNS Global |
| `3` | سریع‌ترین DNS از همهٔ entryها |
| `4` | نمایش DNS فعلی |
| `5` | Reset تغییرات DNS مدیریت‌شده توسط Mirava |
| `0` | بازگشت |

### CLI مستقیم

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

## Backendهای پشتیبانی‌شده

Auto-Apply برای Ubuntu/Debian (APT)، Fedora/Rocky/AlmaLinux/CentOS (DNF/YUM)، Arch/Manjaro (Pacman)، Alpine (APK) و openSUSE (Zypper) پیاده‌سازی شده است. روی derivativeهای ناشناخته benchmark ممکن است انجام شود، اما Mirava از بازنویسی خودکار config جلوگیری می‌کند.

## ایمنی

قبل از تغییرات پشتیبانی‌شده backup ساخته می‌شود. اعمال تعاملی نیاز به تأیید دارد و Apply غیرتعاملی repository فقط با `--apply-system-repo --yes` مجاز است. backupها زیر `/var/backups/mirava` ذخیره می‌شوند.

## ✨ تغییرات این نسخه

- منوی تعاملی کامل و اجرای خودکار آن روی TTY
- Bootstrap وابستگی‌های پایه و حذف نیاز runtime به `yq`/PyYAML
- Benchmark و validation واقعی repository با speed/TTFB
- مدیریت و benchmark DNS با Apply/Reset
- تشخیص چندتوزیعی و backendهای Auto-Apply ایمن
- System Overview، Doctor و CLI کامل
- مستندات ۵ زبانه؛ انگلیسی زبان اصلی است

## مشارکت

برای افزودن mirror جدید، `mirrors_list.yaml` را با ساختار فعلی به‌روزرسانی کنید، روی سیستم خود تست بگیرید و Pull Request را به شاخهٔ `main` بفرستید. راهنمای کامل در [`CONTRIBUTING.md`](CONTRIBUTING.md) است.

## 🔗 Project

- Main repository: https://github.com/MiravaOrg/Mirava
- Website: https://miravaorg.ir
- X: https://x.com/miravaorg
- Telegram: https://t.me/miravaorg

---

بهبودهای optimizer چندتوزیعی Repository/DNS، منوی تعاملی و مستندات چندزبانه توسط [**Farshid Sar**](https://github.com/farshidsar).
