# آموزش پرومتئوس - قسمت هشتم: مانیتورینگ سیستم‌های لینوکس با Node Exporter

در این قسمت از سری آموزش‌های پرومتئوس، به شما نشان می‌دهیم که چگونه می‌توانید سیستم‌های لینوکس (یا سایر سیستم‌های یونیکسی) خود را با استفاده از **Node Exporter** مانیتور کنید.
سرویس Node Exporter یک ابزار سبک و قدرتمند است که توسط تیم پرومتئوس توسعه داده شده و متریک‌های سیستم (مانند CPU، حافظه، شبکه و دیسک) را جمع‌آوری کرده و در قالب فرمت پرومتئوس ارائه می‌دهد.
این آموزش به‌صورت گام‌به‌گام، نصب، پیکربندی، تنظیم دسترسی‌ها، ایجاد کاربران و ساخت داشبورد گرافانا را پوشش می‌دهد و با مثال‌های عملی و عمیق همراه است.

## چرا Node Exporter؟
لینوکس به‌صورت پیش‌فرض متریک‌های سازگار با پرومتئوس ارائه نمی‌دهد.آمدند این ابزار Node Exporter را طراحی کردند تا این مشکل را حل کنند:
- یک فایل باینری مستقل است که بدون نیاز به وابستگی‌های اضافی اجرا می‌شود.
- متریک‌های متنوعی از سیستم (مانند استفاده از CPU، حافظه، دیسک، شبکه و غیره) جمع‌آوری می‌کند.
- به پرومتئوس امکان می‌دهد این متریک‌ها را از طریق اسکرپ (scrape) جمع‌آوری کند.

## گام ۱: دانلود و نصب Node Exporter

### ۱.۱. دانلود Node Exporter
1. به وب‌سایت رسمی پرومتئوس ([prometheus.io](https://prometheus.io)) بروید.
2. در بخش **Downloads**، به قسمت **Node Exporter** بروید.
3. لینک دانلود مناسب برای سیستم‌عامل و معماری سیستم خود (مثلاً Linux AMD64) را انتخاب کنید. برای معماری‌های دیگر، به یادداشت‌های انتشار (release notes) در GitHub پروژه Node Exporter مراجعه کنید.
   - مثال: برای لینوکس AMD64، فایل tarball را دانلود کنید (مثل `node_exporter-1.8.2.linux-amd64.tar.gz`).

**دستور دانلود (مثال):**
```bash
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
```

### ۱.۲. استخراج فایل
1. فایل دانلودشده را استخراج کنید:
```bash
tar -zxvf node_exporter-1.8.2.linux-amd64.tar.gz
cd node_exporter-1.8.2.linux-amd64
```
2. فایل باینری `node_exporter` را مشاهده خواهید کرد. این فایل به زبان Go نوشته شده و نیازی به نصب وابستگی ندارد.

### ۱.۳. انتقال به دایرکتوری مناسب
برای مدیریت بهتر، باینری را به دایرکتوری استاندارد منتقل کنید:
```bash
sudo mv node_exporter /usr/bin/
```

## گام ۲: ایجاد کاربر و تنظیم دسترسی‌ها

برای امنیت بیشتر، Node Exporter را با یک کاربر غیرروت (non-root) اجرا می‌کنیم.

1. **ایجاد کاربر اختصاصی:**
```bash
sudo useradd -rs /bin/false node_exporter
```
   - این دستور یک کاربر سیستمی به نام `node_exporter` ایجاد می‌کند که نمی‌تواند وارد شل شود.

2. **تنظیم مالکیت فایل:**
```bash
sudo chown node_exporter:node_exporter /usr/bin/node_exporter
```

3. **ایجاد دایرکتوری برای لاگ‌ها و تنظیمات (اختیاری):**
```bash
sudo mkdir /var/log/node_exporter
sudo chown node_exporter:node_exporter /var/log/node_exporter
```

## گام ۳: اجرای Node Exporter

### ۳.۱. اجرای دستی برای تست
برای تست اولیه، Node Exporter را بدون پرچم اجرا کنید:
```bash
/usr/bin/node_exporter
```
- به‌صورت پیش‌فرض، Node Exporter روی پورت **9100** گوش می‌دهد و متریک‌ها را در آدرس `http://localhost:9100/metrics` ارائه می‌دهد.

**تست در مرورگر:**
1. به آدرس `http://localhost:9100/metrics` بروید.
2. متریک‌های با پیشوند `node_` (مانند `node_cpu_seconds_total` یا `node_memory_MemAvailable_bytes`) را مشاهده خواهید کرد.

### ۳.۲. پیکربندی پرچم‌های Node Exporter
Node Exporter از **کلکتورها (Collectors)** برای جمع‌آوری متریک‌ها استفاده می‌کند. برخی کلکتورها به‌صورت پیش‌فرض فعال و برخی غیرفعال هستند.

**بررسی پرچم‌ها:**
- برای مشاهده کلکتورهای موجود، مستندات Node Exporter (فایل `README.md` در مخزن GitHub) را بررسی کنید.
- مثال پرچم‌ها:
  - فعال‌سازی کلکتور غیرفعال: `--collector.<name>`
  - غیرفعال‌سازی کلکتور فعال: `--no-collector.<name>`
  - فیلتر سیستم‌های فایل: `--collector.filesystem.fs-types-exclude=^(tmpfs|sysfs|proc)$`

**مثال: غیرفعال‌سازی کلکتور `diskstats`:**
```bash
/usr/bin/node_exporter --no-collector.diskstats
```

**مثال: محدود کردن سیستم‌های فایل:**
```bash
/usr/bin/node_exporter --collector.filesystem.fs-types-exclude=^(tmpfs|sysfs|proc|devtmpfs)$
```

### ۳.۳. اجرای دائمی با Systemd
برای اجرای Node Exporter به‌صورت سرویس سیستمی:

1. فایل سرویس Systemd را ایجاد کنید:
```bash
sudo nano /etc/systemd/system/node_exporter.service
```

2. محتوای زیر را اضافه کنید:
```ini
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/bin/node_exporter \
--collector.filesystem.fs-types-exclude=^(tmpfs|sysfs|proc|devtmpfs)$
Restart=always

[Install]
WantedBy=multi-user.target
```

3. سرویس را فعال و اجرا کنید:
```bash
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
```

4. وضعیت سرویس را بررسی کنید:
```bash
sudo systemctl status node_exporter
```

## گام ۴: پیکربندی پرومتئوس برای اسکرپ Node Exporter

برای جمع‌آوری متریک‌ها، باید پرومتئوس را تنظیم کنید تا Node Exporter را اسکرپ کند.

1. فایل پیکربندی پرومتئوس را ویرایش کنید (معمولاً در `/etc/prometheus/prometheus.yml`):
```bash
sudo nano /etc/prometheus/prometheus.yml
```

2. یک job جدید برای Node Exporter اضافه کنید:
```yaml
scrape_configs:
  - job_name: 'node_exporter'
    scrape_interval: 15s
    static_configs:
      - targets: ['localhost:9100']
```

3. پرومتئوس را ری‌استارت کنید:
```bash
sudo systemctl restart prometheus
```

4. در رابط وب پرومتئوس (`http://<prometheus-server>:9090/targets`) بررسی کنید که هدف `node_exporter` به‌درستی اسکرپ می‌شود.
<img width="1265" height="700" alt="image" src="https://github.com/user-attachments/assets/dff460c2-a4cd-4647-8622-c0febfd7f93e" />


## گام ۵: بررسی متریک‌ها در پرومتئوس

1. به رابط وب پرومتئوس (`http://<prometheus-server>:9090/graph`) بروید.
2. متریک‌های با پیشوند `node_` را جستجو کنید:
```promql
node_
```
   - این دستور تمام متریک‌های Node Exporter را نشان می‌دهد.

### مثال ۱: مانیتورینگ استفاده از CPU
متریک `node_cpu_seconds_total` زمان صرف‌شده توسط CPU در حالت‌های مختلف (مثل `user`, `system`, `idle`) را نشان می‌دهد.
این یک کانتر است، بنابراین باید از تابع `rate` استفاده کنیم.

**کوئری:**
```promql
rate(node_cpu_seconds_total{mode="user"}[5m])
```

<img width="1262" height="467" alt="image" src="https://github.com/user-attachments/assets/9fcdfff6-0b7b-47e0-88f3-38bd0e5f79dd" />

- **توضیح:** نرخ استفاده از CPU در حالت کاربر (user mode) را برای هر هسته در ۵ دقیقه نشان می‌دهد.
- **کاربرد:** می‌توانید این کوئری را در یک نمودار سری زمانی استفاده کنید تا بار CPU را بررسی کنید.

### مثال ۲: مانیتورینگ شبکه
متریک `node_network_receive_bytes_total` تعداد بایت‌های دریافتی توسط رابط‌های شبکه را نشان می‌دهد.

**کوئری:**
```promql
rate(node_network_receive_bytes_total{device='ens33'}[5m])
```
- **توضیح:** نرخ دریافت داده (بایت بر ثانیه) برای رابط `ens33` را نشان می‌دهد.
- **کاربرد:** برای شناسایی ترافیک غیرعادی شبکه یا نظارت بر پهنای باند.

## گام ۶: ایجاد داشبورد گرافانا

برای بصری‌سازی متریک‌ها، می‌توانید از داشبورد آماده **Node Exporter Full** (ID: 1860) در گرافانا استفاده کنید.

1. **اتصال گرافانا به پرومتئوس:** (مراجعه به قسمت هفتم آموزش)
   - منبع داده پرومتئوس را در گرافانا اضافه کنید (مثلاً `http://<prometheus-server>:9090`).

2. **وارد کردن داشبورد:**
   - در گرافانا، به منوی **Dashboards > Import** بروید.
   - وارد کردن ID داشبورد (`1860`).
   - منبع داده پرومتئوس را انتخاب کنید و داشبورد را ایمپورت کنید.

3. **بررسی داشبورد:**
   - داشبورد شامل ردیف‌هایی برای مرور کلی سیستم، CPU، حافظه، شبکه و دیسک است.
   - مثال: ردیف CPU نشان می‌دهد که کدام هسته‌ها تحت فشار هستند.

**مثال عملی:**
فرض کنید سرور شما به دلیل بار زیاد CPU کند شده است. 
در داشبورد، ردیف **CPU Usage** نشان می‌دهد که هسته‌های خاصی بیش از ۸۰٪ استفاده دارند.
با بررسی متریک `node_cpu_seconds_total{mode="user"}`، می‌توانید فرآیندهای پرمصرف را شناسایی کنید (مثلاً با ابزار `top` یا `htop`).

2. **امنیت:**
   - مهم است که Node Exporter را پشت فایروال قرار دهید و فقط به پرومتئوس اجازه دسترسی به پورت 9100 بدهید:
```bash
sudo ufw allow from <prometheus-ip> to any port 9100
```
   - برای احراز هویت، می‌توانید از پراکسی معکوس (مثل Nginx) با احراز هویت پایه استفاده کنید.

3. **مانیتورینگ چند سرور:**
   - برای چندین سرور، هر Node Exporter را با برچسب‌های مختلف (مثل `instance`) پیکربندی کنید:
```yaml
- job_name: 'node_exporter'
  static_configs:
  - targets: ['server1:9100', 'server2:9100']
     labels:
       env: 'production'
```

4. **رفع اشکال:**
   - اگر متریک‌ها در پرومتئوس ظاهر نشدند، لاگ‌های Node Exporter را بررسی کنید:
```bash
journalctl -u node_exporter
```
   - مطمئن شوید پورت 9100 باز است:
```bash
sudo netstat -tuln | grep 9100
```

## مثال جامع: مانیتورینگ یک وب‌سرور
فرض کنید یک وب‌سرور لینوکسی دارید و می‌خواهید CPU، حافظه و ترافیک شبکه را مانیتور کنید:
1. **نصب Node Exporter:** طبق مراحل بالا.
2. **پیکربندی پرومتئوس:**
   ```yaml
   scrape_configs:
     - job_name: 'web_server'
       scrape_interval: 10s
       static_configs:
         - targets: ['webserver:9100']
   ```

## جمع‌بندی
Node Exporter ابزاری قدرتمند برای مانیتورینگ سیستم‌های لینوکس با پرومتئوس است. با نصب و پیکربندی آن، تنظیم دسترسی‌ها و ایجاد داشبورد گرافانا، می‌توانید دید عمیقی به عملکرد سیستم خود داشته باشید. متریک‌های CPU، شبکه، حافظه و دیسک به شما کمک می‌کنند تا مشکلات را سریعاً شناسایی و برطرف کنید. برای یادگیری بیشتر، به مستندات Node Exporter در GitHub یا دوره‌های آموزشی پرومتئوس مراجعه کنید.
