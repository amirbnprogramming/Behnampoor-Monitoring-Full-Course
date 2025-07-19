# آموزش مانیتورینگ : قسمت یازدهم Nginx Exporter و Blackbox Exporter برای Prometheus و Grafana

## مقدمه
در دنیای مانیتورینگ، **Prometheus** به عنوان یک ابزار متن‌باز قدرتمند برای جمع‌آوری و ذخیره‌سازی معیارهای سری زمانی شناخته می‌شود.
برای مانیتورینگ سرویس‌های خاص مانند وب‌سرور **Nginx** یا بررسی دسترسی‌پذیری endpoint‌ها، از ابزارهای تخصصی به نام **Exporter** استفاده می‌شود.
در این آموزش، به دو Exporter مهم، یعنی **Nginx Exporter** و **Blackbox Exporter**، می‌پردازیم و نحوه پیکربندی آن‌ها را برای یکپارچه‌سازی با Prometheus و Grafana توضیح می‌دهیم.

**هدف این آموزش:**
- درک مفهومی و کاربردی Nginx Exporter و Blackbox Exporter
- آموزش نصب و پیکربندی دقیق
- مدیریت دسترسی‌ها، دایرکتوری‌ها و کاربران
- یکپارچه‌سازی با Prometheus و Grafana
- ارائه نکات عملی و مثال‌های واقعی

---

## بخش اول: Nginx Exporter چیست؟
**اکسپورترNginx** ابزاری است که معیارهای عملکرد وب‌سرور Nginx (مانند تعداد درخواست‌ها، زمان پاسخ، خطاها و ...) را به فرمت قابل‌فهم برای Prometheus استخراج می‌کند.
این ابزار با استفاده از ماژول **stub_status** در Nginx کار می‌کند که اطلاعات پایه‌ای در مورد وضعیت سرور را ارائه می‌دهد.

### چرا به Nginx Exporter نیاز داریم؟
- **مانیتورینگ دقیق**: اطلاعاتی مانند تعداد درخواست‌های فعال، نرخ درخواست‌ها در ثانیه، و خطاهای HTTP را فراهم می‌کند.
- **یکپارچگی با Prometheus**: داده‌ها به صورت سری زمانی (time-series) جمع‌آوری شده و برای تحلیل در Grafana استفاده می‌شوند.
- **تشخیص سریع مشکلات**: می‌توانید مشکلات عملکرد یا قطعی‌های احتمالی را سریعاً شناسایی کنید.

### پیش‌نیازها
- نصب Nginx با ماژول `http_stub_status_module`
- سرور Prometheus فعال
- سرور Grafana برای تجسم داده‌ها
- دسترسی کاربر با امتیازات `sudo` برای نصب و پیکربندی
- آشنایی اولیه با مفاهیم Prometheus و YAML

---

## بخش دوم: نصب و پیکربندی Nginx Exporter

### ابتدا باید خود nginx رو نصب داشته باشیم.

#### پیش‌نیازها
قبل از شروع نصب، مطمئن شوید که شرایط زیر را دارید:
- یک سرور لینوکس (ترجیحاً Ubuntu 20.04 یا بالاتر)
- دسترسی کاربر با امتیازات `sudo`
- اتصال به اینترنت برای دانلود بسته‌ها
- دانش پایه در مورد خط فرمان لینوکس
- (اختیاری) فایروال فعال (مانند `ufw`) برای مدیریت دسترسی‌ها

---

#### نصب Nginx

### قدم ۱: به‌روزرسانی سیستم
قبل از نصب، بسته‌های سیستم را به‌روز کنید تا از آخرین نسخه‌ها استفاده کنید:
```bash
sudo apt update && sudo apt upgrade -y
```

#### نصب بسته Nginx
وب سرور Nginx در مخازن پیش‌فرض Ubuntu موجود است. برای نصب آن، دستور زیر را اجرا کنید:
```bash
sudo apt install nginx -y
```

این دستور نسخه پایدار Nginx را همراه با وابستگی‌های لازم نصب می‌کند.

#### بررسی وضعیت نصب
پس از نصب، بررسی کنید که Nginx به درستی نصب شده و در حال اجراست:
```bash
sudo systemctl status nginx
```

خروجی باید نشان دهد که سرویس `active (running)` است. اگر سرویس اجرا نشده، آن را فعال کنید:
```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

- ` دستور start`: سرویس را اجرا می‌کند.
- `دستور enable`: سرویس را تنظیم می‌کند تا در زمان بوت سیستم به صورت خودکار اجرا شود.

#### بررسی دسترسی به وب‌سرور
برای اطمینان از نصب صحیح، مرورگر خود را باز کنید و آدرس IP سرور یا `localhost` را وارد کنید (مثلاً `http://<server-ip>` یا `http://localhost`). باید صفحه پیش‌فرض Nginx را ببینید که معمولاً پیامی مانند "Welcome to nginx!" نمایش می‌دهد.

اگر از خط فرمان هستید، می‌توانید از `curl` استفاده کنید:
```bash
curl http://localhost
```


<!DOCTYPE html>
<html>
<head>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
- خروجی باید شامل HTML صفحه پیش‌فرض Nginx باشد.
---
### فعال‌سازی ماژول stub_status در Nginx
- برای استفاده از Nginx Exporter، باید ماژول `http_stub_status_module` در Nginx فعال باشد.
- این ماژول به طور پیش‌فرض در بسیاری از نسخه‌های Nginx وجود دارد، اما باید آن را در فایل پیکربندی فعال کنید.
---

 فایل پیکربندی Nginx را باز کنید (معمولاً در `/etc/nginx/nginx.conf` یا `/etc/nginx/conf.d/`):
   ```bash
   sudo nano /etc/nginx/conf.d/stub_status.conf
   ```

 یک بلوک `server` برای stub_status اضافه کنید:
   ```nginx
   server {
       listen 8080;
       server_name localhost;
       location /stub_status {
           stub_status on;
           allow 127.0.0.1;  # فقط دسترسی از localhost
           deny all;         # جلوگیری از دسترسی خارجی
       }
   }
   ```

 بررسی کنید که فایل پیکربندی درست باشد:
   ```bash
   sudo nginx -t
   ```

 سرویس Nginx را ری‌استارت کنید:
   ```bash
   sudo systemctl restart nginx
   ```

 بررسی کنید که stub_status کار می‌کند:
   ```bash
   curl http://localhost:8080/stub_status
   ```
 خروجی باید چیزی شبیه این باشد:
   ```
   Active connections: 1
   server accepts handled requests
    1234 1234 5678
   Reading: 0 Writing: 1 Waiting: 0
   ```

### قدم ۲: نصب Nginx Exporter

 ابتدا دایرکتوری موقت برای دانلود فایل فشرده ی مدنظر ایجاد میکنیم و به آن مسیر میرویم:

   ```bash
   mkdir -p /tmp/nginx_exporter_tmp && cd /tmp/nginx_exporter_tmp
   ```
 فایل باینری Nginx Exporter را از مخزن رسمی دانلود کنید
   ```bash
   wget https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v1.2.0/nginx-prometheus-exporter_1.2.0_linux_amd64.tar.gz
   ```

 فایل را از حالت فشرده خارج کنید:
   ```bash
   tar -xzf nginx-prometheus-exporter_0.11.0_linux_amd64.tar.gz
   ```

 فایل باینری را به دایرکتوری مناسب منتقل کنید:
   ```bash
   sudo mv nginx-prometheus-exporter /usr/bin/
   ```

### قدم ۳: ایجاد کاربر و دایرکتوری برای Nginx Exporter
برای امنیت بیشتر، Nginx Exporter را با یک کاربر غیر روت اجرا می‌کنیم:
 کاربر جدید ایجاد کنید:
   ```bash
   sudo useradd -rs /bin/false nginx_exporter
   ```

 دایرکتوری برای ذخیره لاگ‌ها و فایل‌های پیکربندی:
   ```bash
   sudo mkdir /etc/nginx_exporter
   sudo chown nginx_exporter:nginx_exporter /etc/nginx_exporter
   ```

### قدم ۴: پیکربندی سرویس سیستم برای Nginx Exporter
 فایل سرویس سیستم را ایجاد کنید:
   ```bash
   sudo nano /etc/systemd/system/nginx-exporter.service
   ```

 محتوای زیر را اضافه کنید:
   ```ini
   [Unit]
   Description=Nginx Prometheus Exporter
   After=network.target

   [Service]
   User=nginx_exporter
   Group=nginx_exporter
   ExecStart=/usr/bin/nginx-prometheus-exporter -nginx.scrape-uri=http://localhost:8080/stub_status
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```

 سرویس را فعال کنید و اجرا کنید:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable nginx-exporter
   sudo systemctl start nginx-exporter
   ```

 بررسی کنید که سرویس در حال اجراست:
   ```bash
   sudo systemctl status nginx-exporter
   ```

 در مرورگر یا ترمینال چک میکنیم ببینم endpoint این اکسپورتر درست کار میکند یا نه :
   ```bash
   sudo curl 127.0.0.1:9113
   ```
 خروجی باید چیزی شبیه به زیر باشد :
 
   > <img width="1274" height="436" alt="image" src="https://github.com/user-attachments/assets/a4ea5c68-b0f0-4037-b30e-3296a4eb53f9" />


  


### قدم ۵: اضافه کردن Nginx Exporter به Prometheus
 فایل پیکربندی Prometheus را باز کنید (معمولاً در `/etc/prometheus/prometheus.yml`):
   ```bash
   sudo nano /etc/prometheus/prometheus.yml
   ```

 یک job جدید برای Nginx Exporter اضافه کنید:
   ```yaml
   scrape_configs:
     - job_name: 'nginx'
       static_configs:
         - targets: ['localhost:9113']  # پورت پیش‌فرض Nginx Exporter
   ```

 سرویس Prometheus را ری‌استارت کنید:
   ```bash
   sudo systemctl restart prometheus
   ```

 بررسی کنید که معیارها از Nginx Exporter جمع‌آوری می‌شوند:
   
- به رابط کاربری Prometheus (معمولاً `http://<prometheus-server>:9090`) بروید 
- در بخش `Status > Targets` بررسی کنید که job مربوط به Nginx در حالت `UP` باشد.

  > <img width="1262" height="154" alt="image" src="https://github.com/user-attachments/assets/621131a3-f90c-4085-8bfc-da9dae5a213f" />


### نکات کلیدی برای Nginx Exporter
- **امنیت**: حتماً دسترسی به endpoint `stub_status` را محدود کنید (مثلاً فقط از localhost).
- **پورت‌ها**: Nginx Exporter به طور پیش‌فرض روی پورت 9113 اجرا می‌شود. اگر پورت دیگری استفاده می‌کنید، در پیکربندی Prometheus آن را تنظیم کنید.
- **لاگ‌ها**: لاگ‌های Nginx Exporter را در `/etc/nginx_exporter` بررسی کنید تا از عملکرد صحیح مطمئن شوید.
- **مقیاس‌پذیری**: اگر چندین سرور Nginx دارید، برای هر سرور یک instance از Nginx Exporter اجرا کنید و در Prometheus به صورت جداگانه تعریف کنید.
---

## بخش سوم: Blackbox Exporter چیست؟
**اکسپورتر Blackbox** ابزاری است که برای مانیتورینگ دسترسی‌پذیری و سلامت endpoint‌های HTTP، HTTPS، DNS، TCP و ICMP استفاده می‌شود.
برخلاف Nginx Exporter که مخصوص یک سرویس (Nginx) است، Blackbox Exporter برای بررسی عمومی endpoint‌ها طراحی شده و می‌تواند پاسخ‌های HTTP، کدهای وضعیت، زمان پاسخ و گواهینامه‌های SSL را بررسی کند.

### چرا به Blackbox Exporter نیاز داریم؟
- **مانیتورینگ سلامت endpointها**: بررسی می‌کند که آیا یک URL یا سرویس خاص در دسترس است یا خیر.
- **بررسی SSL**: می‌تواند تاریخ انقضای گواهینامه‌های SSL را مانیتور کند.
- **انعطاف‌پذیری**: برای پروتکل‌های مختلف (HTTP، TCP، DNS) قابل استفاده است.

### پیش‌نیازها
- سرور Prometheus فعال
- دسترسی به endpointهایی که می‌خواهید مانیتور کنید
- دانش اولیه در مورد YAML و مفاهیم شبکه

---

## بخش چهارم: نصب و پیکربندی Blackbox Exporter

### قدم ۱: دانلود و نصب Blackbox Exporter
 فایل باینری Blackbox Exporter را دانلود کنید:
   ```bash
   wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.24.0/blackbox_exporter-0.27.0.linux-amd64.tar.gz
   ```

 فایل را از حالت فشرده خارج کنید:
   ```bash
   tar -xzf blackbox_exporter-0.27.0.linux-amd64.tar.gz
   ```

 فایل باینری را به دایرکتوری مناسب منتقل کنید:
   ```bash
   sudo mv blackbox_exporter-0.27.0.linux-amd64/blackbox_exporter /usr/bin/
   ```

### قدم ۲: ایجاد کاربر و دایرکتوری
 کاربر جدید ایجاد کنید:
   ```bash
   sudo useradd -rs /bin/false blackbox_exporter
   ```

 دایرکتوری برای ذخیره فایل‌های پیکربندی:
   ```bash
   sudo mkdir /etc/blackbox_exporter
   sudo chown blackbox_exporter:blackbox_exporter /etc/blackbox_exporter
   ```

 فایل پیکربندی پیش‌فرض Blackbox Exporter را کپی کنید:
   ```bash
   sudo mv blackbox_exporter-0.27.0.linux-amd64/config.yml /etc/blackbox_exporter/blackbox.yml
   ```

### قدم ۳: پیکربندی Blackbox Exporter
 فایل پیکربندی Blackbox Exporter را باز کنید:
   ```bash
   sudo nano /etc/blackbox_exporter/blackbox.yml
   ```

 یک نمونه پیکربندی برای مانیتورینگ HTTP اضافه کنید:
   ```yaml
   modules:
     http_2xx:
       prober: http
       timeout: 5s
       http:
         valid_http_versions: ["HTTP/1.1", "HTTP/2"]
         valid_status_codes: [200]
         method: GET
     ssl_check:
       prober: http
       timeout: 5s
       http:
         method: GET
         tls_config:
           insecure_skip_verify: false
   ```

   توضیحات:
   - `قسمت http_2xx`: بررسی می‌کند که آیا پاسخ HTTP کد 200 را برمی‌گرداند.
   - `قسمت ssl_check`: بررسی وضعیت گواهینامه SSL.

 فایل را ذخیره کنید و دسترسی‌ها را تنظیم کنید:
   ```bash
   sudo chown blackbox_exporter:blackbox_exporter /etc/blackbox_exporter/blackbox.yml
   ```

### قدم ۴: ایجاد سرویس سیستم برای Blackbox Exporter
 فایل سرویس را ایجاد کنید:
   ```bash
   sudo nano /etc/systemd/system/blackbox-exporter.service
   ```

 محتوای زیر را اضافه کنید:
   ```ini
   [Unit]
   Description=Blackbox Exporter
   After=network.target

   [Service]
   User=blackbox_exporter
   Group=blackbox_exporter
   ExecStart=/usr/bin/blackbox_exporter --config.file=/etc/blackbox_exporter/blackbox.yml
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```

 سرویس را فعال کنید و اجرا کنید:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable blackbox-exporter
   sudo systemctl start blackbox-exporter
   ```

 بررسی کنید که سرویس در حال اجراست:
   ```bash
   sudo systemctl status blackbox-exporter
   ```

### قدم ۵: اضافه کردن Blackbox Exporter به Prometheus
 فایل پیکربندی Prometheus را باز کنید:
   ```bash
   sudo nano /etc/prometheus/prometheus.yml
   ```

 یک job جدید برای Blackbox Exporter اضافه کنید:
   ```yaml
   scrape_configs:
     - job_name: 'blackbox'
       metrics_path: /probe
       params:
         module: [http_2xx]  # استفاده از ماژول http_2xx
       static_configs:
         - targets:
             - https://example.com
             - http://your-domain.com
       relabel_configs:
         - source_labels: [__address__]
           target_label: __param_target
         - source_labels: [__param_target]
           target_label: instance
         - target_label: __address__
           replacement: localhost:9115  # آدرس Blackbox Exporter
   ```

 مرحله بعدی Prometheus را ری‌استارت کنید:
   ```bash
   sudo systemctl restart prometheus
   ```

 بررسی کنید که معیارها جمع‌آوری می‌شوند:
   - به رابط کاربری Prometheus بروید و در بخش `Status > Targets` بررسی کنید که job مربوط به Blackbox در حالت `UP` باشد.
     
   <img width="1260" alt="image" src="https://github.com/user-attachments/assets/654ca598-3464-4436-865d-d380c09e2b3f" />

   <img width="1260" alt="image" src="https://github.com/user-attachments/assets/b5551f4b-5823-450d-8b9f-846edb69e024" />

   <img width="1260" alt="image" src="https://github.com/user-attachments/assets/a9424f35-7406-44ea-b9cd-9be1f70f7fe6" />





### نکات کلیدی برای Blackbox Exporter
- **ماژول‌های مختلف**: می‌توانید ماژول‌های مختلفی برای HTTP، TCP، DNS و غیره تعریف کنید.
- **امنیت SSL**: برای بررسی گواهینامه‌های SSL، حتماً `insecure_skip_verify` را روی `false` تنظیم کنید تا از اعتبار گواهینامه مطمئن شوید.
- **لاگ‌ها**: لاگ‌های Blackbox Exporter را در `/var/log` یا دایرکتوری دلخواه بررسی کنید.
- **مقیاس‌پذیری**: Blackbox Exporter می‌تواند چندین endpoint را به صورت همزمان مانیتور کند.

---

## بخش پنجم: یکپارچه‌سازی با Grafana
برای تجسم داده‌های جمع‌آوری‌شده توسط Nginx Exporter و Blackbox Exporter، از **Grafana** استفاده می‌کنیم.

### قدم ۱: اضافه کردن Prometheus به عنوان منبع داده در Grafana
1. به رابط کاربری Grafana بروید (معمولاً `http://<grafana-server>:3000`).
2. در منوی سمت چپ، به **Configuration > Data Sources** بروید.
3. روی **Add data source** کلیک کنید و **Prometheus** را انتخاب کنید.
4. تنظیمات زیر را وارد کنید:
   - **URL**: `http://<prometheus-server>:9090`
   - **Access**: Server (default)
5. روی **Save & Test** کلیک کنید.

### قدم ۲: ایجاد داشبورد برای Nginx Exporter
1. در Grafana، به **Create > Dashboard** بروید.
2. یک پنل جدید اضافه کنید.
3. در بخش Query، Prometheus را انتخاب کنید و یک کوئری نمونه وارد کنید، مثلاً:
   ```promql
   nginx_requests_total
   ```
   این کوئری تعداد کل درخواست‌های Nginx را نمایش می‌دهد.
4. برای داشبوردهای آماده، می‌توانید داشبورد رسمی Nginx Exporter را از [Grafana Labs](https://grafana.com/grafana/dashboards/14900-nginx) (ID: 14900) وارد کنید.

### قدم ۳: ایجاد داشبورد برای Blackbox Exporter
1. یک پنل جدید اضافه کنید.
2. یک کوئری نمونه وارد کنید، مثلاً:
   ```promql
   probe_success
   ```
   این کوئری نشان می‌دهد که آیا endpointها در دسترس هستند یا خیر.
3. برای داشبوردهای آماده، داشبورد رسمی Blackbox Exporter (ID: 7587) را از [Grafana Labs](https://grafana.com/grafana/dashboards/7587) وارد کنید.


### تصاویر نهایی داشبورد های nginx و blackbox:

   - <img width="1263" height="847" alt="image" src="https://github.com/user-attachments/assets/231c96ee-a5cd-4476-8e6a-ca3502663c97" />

   - <img width="1268" height="830" alt="image" src="https://github.com/user-attachments/assets/4bcf7f88-6159-466a-9990-72cb8939391a" />

### نکات برای Grafana
- **شخصی‌سازی داشبورد**: از متغیرها (Variables) در Grafana برای فیلتر کردن داده‌ها بر اساس instance یا job استفاده کنید.
- **هشدارها**: می‌توانید هشدارهایی برای معیارهای خاص (مانند قطعی endpoint یا افزایش خطاهای Nginx) تنظیم کنید.
- **دسترسی‌ها**: اطمینان حاصل کنید که فقط کاربران مجاز به داشبوردهای Grafana دسترسی دارند.

---

## بخش ششم: مثال‌های کاربردی
### مثال ۱: مانیتورینگ وب‌سایت با Blackbox Exporter
فرض کنید می‌خواهید دسترسی‌پذیری وب‌سایت `https://example.com` را مانیتور کنید:
1. در فایل `blackbox.yml`، ماژول زیر را اضافه کنید:
   ```yaml
   modules:
     http_example:
       prober: http
       http:
         valid_status_codes: [200, 301]
         method: GET
   ```
2. در Prometheus، job زیر را اضافه کنید:
   ```yaml
   scrape_configs:
     - job_name: 'example_website'
       metrics_path: /probe
       params:
         module: [http_example]
       static_configs:
         - targets: ['https://example.com']
       relabel_configs:
         - source_labels: [__address__]
           target_label: __param_target
         - source_labels: [__param_target]
           target_label: instance
         - target_label: __address__
           replacement: localhost:9115
   ```
3. در Grafana، یک پنل با کوئری `probe_success{instance="https://example.com"}` ایجاد کنید.

### مثال ۲: مانیتورینگ خطاهای 5xx در Nginx
برای نمایش تعداد خطاهای 5xx در Nginx:
1. در Grafana، یک پنل جدید بسازید.
2. کوئری زیر را وارد کنید:
   ```promql
   sum(rate(nginx_http_requests_total{status=~"5.."}[5m])) by (status)
   ```
   این کوئری نرخ خطاهای 5xx را در بازه ۵ دقیقه‌ای نمایش می‌دهد.

---

## بخش هفتم: دسترسی‌ها و امنیت
- **کاربران**:
  - از کاربران غیرروت (`nginx_exporter` و `blackbox_exporter`) برای اجرای سرویس‌ها استفاده کنید.
  - دسترسی‌های فایل‌ها و دایرکتوری‌ها را با `chown` و `chmod` محدود کنید.
- **فایروال**:
  - پورت‌های 9113 (Nginx Exporter) و 9115 (Blackbox Exporter) را فقط برای Prometheus باز کنید:
    ```bash
    sudo ufw allow from <prometheus-ip> to any port 9113
    sudo ufw allow from <prometheus-ip> to any port 9115
    ```
- **شبکه**:
  - endpoint `stub_status` را فقط برای localhost باز کنید.
  - از HTTPS برای Grafana استفاده کنید تا امنیت داشبورد تضمین شود.

---

## بخش هشتم: دایرکتوری‌ها و ساختار پیشنهادی
- **Nginx Exporter**:
  - باینری: `/usr/bin/nginx-prometheus-exporter`
  - دایرکتوری پیکربندی: `/etc/nginx_exporter`
  - لاگ‌ها: `/var/log/nginx_exporter`
- **Blackbox Exporter**:
  - باینری: `/usr/bin/blackbox_exporter`
  - دایرکتوری پیکربندی: `/etc/blackbox_exporter`
  - لاگ‌ها: `/var/log/blackbox_exporter`
- **Prometheus**:
  - پیکربندی: `/etc/prometheus/prometheus.yml`
  - داده‌ها: `/var/lib/prometheus`
- **Grafana**:
  - پیکربندی: `/etc/grafana/grafana.ini`
  - داده‌ها: `/var/lib/grafana`

---

## بخش نهم: نکات پیشرفته و عیب‌یابی
- **عیب‌یابی Nginx Exporter**:
  - اگر معیارها جمع‌آوری نمی‌شوند، بررسی کنید که endpoint `stub_status` در دسترس است:
    ```bash
    curl http://localhost:8080/stub_status
    ```
  - لاگ‌های Nginx Exporter را بررسی کنید: `/var/log/nginx_exporter`.
- **عیب‌یابی Blackbox Exporter**:
  - بررسی کنید که endpointهای هدف در دسترس هستند:
    ```bash
    curl http://localhost:9115/probe?module=http_2xx&target=https://example.com
    ```
  - اطمینان حاصل کنید که ماژول‌ها در فایل `blackbox.yml` به درستی تعریف شده‌اند.
- **بهینه‌سازی**:
  - برای کاهش بار روی سرور، بازه‌های scrape در Prometheus را بهینه کنید (مثلاً 15 ثانیه برای Nginx و 30 ثانیه برای Blackbox).
  - از قابلیت relabeling در Prometheus برای فیلتر کردن معیارهای غیرضروری استفاده کنید.

---

## نتیجه‌گیری
با استفاده از **Nginx Exporter** و **Blackbox Exporter**، می‌توانید یک سیستم مانیتورینگ جامع برای وب‌سرورهای Nginx و endpointهای مختلف ایجاد کنید. این ابزارها به شما امکان می‌دهند تا عملکرد سرویس‌های خود را به صورت دقیق رصد کرده و با استفاده از Grafana، داشبوردهای بصری و جذابی بسازید. با رعایت نکات امنیتی، مدیریت صحیح دسترسی‌ها و استفاده از ساختار دایرکتوری مناسب، می‌توانید سیستمی پایدار و مقیاس‌پذیر داشته باشید.

برای مطالعه بیشتر:
- مستندات رسمی Prometheus: [prometheus.io](https://prometheus.io)
- مستندات Nginx Exporter: [github.com/nginxinc/nginx-prometheus-exporter](https://github.com/nginxinc/nginx-prometheus-exporter)
- مستندات Blackbox Exporter: [github.com/prometheus/blackbox_exporter](https://github.com/prometheus/blackbox_exporter)
- داشبوردهای آماده Grafana: [grafana.com/grafana/dashboards](https://grafana.com/grafana/dashboards)
