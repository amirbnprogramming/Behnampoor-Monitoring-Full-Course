# آموزش مانیتورینگ: قسمت دوازدهم - ساخت اکسپورتر شخصی‌سازی شده با پایتون برای مانیتورینگ وضعیت کارت شبکه

در این آموزش، به صورت کامل و قدم به قدم نحوه ساخت یک اکسپورتر شخصی‌سازی شده ساده با زبان پایتون برای جمع‌آوری متریک‌های مرتبط با کارت شبکه (مانند سرعت اینترنت، حجم ارسال و دریافت داده، سرعت ارسال و دریافت)و نمایش آن‌ها در گرافانا را توضیح می‌دهیم.
این آموزش شامل تمامی مراحل از کانفیگ اولیه تا نمایش داده‌ها در گرافانا است. هدف این است که شما بتوانید یک اکسپورتر کاربردی و حرفه‌ای بسازید و داده‌ها را به بهترین شکل در گرافانا نمایش دهید.
در این آموزش از کتابخانه‌های استاندارد پایتون و ماژول `prometheus_client` استفاده می‌کنیم.

## پیش‌نیازها

برای پیاده‌سازی این اکسپورتر، به موارد زیر نیاز دارید:
- **سیستم‌عامل**: لینوکس (ترجیحاً اوبونتو یا دبیان) به دلیل سازگاری بهتر با ابزارهای مانیتورینگ.
- **نصب پایتون**: نسخه 3.8 یا بالاتر.
- **نصب پرومتئوس و گرافانا**: پرومتئوس برای جمع‌آوری متریک‌ها و گرافانا برای نمایش داده‌ها.
- **کتابخانه‌های پایتون**: کتابخانه‌های `prometheus_client` برای اکسپورتر و `psutil` برای دسترسی به اطلاعات کارت شبکه.
- **دسترسی‌های سیستمی**: دسترسی root یا کاربر با دسترسی‌های کافی برای خواندن اطلاعات کارت شبکه.
- **دانش اولیه**: آشنایی با مفاهیم اولیه شبکه، پایتون، و سیستم‌های مانیتورینگ.

## مرحله ۱: آماده‌سازی محیط

### نصب پکیج‌های مورد نیاز
ابتدا پایتون و کتابخانه‌های مورد نیاز را نصب کنید. در ترمینال دستورات زیر را اجرا کنید:

```bash
sudo apt update
sudo apt install python3 python3-pip
```
ساخت محیط مجازی و فعال سازی pip :
```bash
python3 -m venv /path/to/venv
source /path/to/venv/bin/activate
pip install prometheus_client psutil netifaces
```
- ` کتابخانه prometheus_client`: برای ایجاد اکسپورتر و ارائه متریک‌ها به پرومتئوس.
- ` کتابخانه psutil`: برای دسترسی به اطلاعات کارت شبکه مانند حجم داده و سرعت.

### تنظیم دسترسی‌ها
برای خواندن اطلاعات کارت شبکه، نیاز به دسترسی به `/proc/net/dev` دارید.
این فایل اطلاعات مربوط به کارت‌های شبکه را ارائه می‌دهد. 
معمولاً کاربر معمولی می‌تواند به این فایل دسترسی داشته باشد، اما اگر با خطای دسترسی مواجه شدید، اسکریپت را با `sudo` اجرا کنید یا کاربر را به گروه مناسب (مانند `adm`) اضافه کنید:

```bash
sudo usermod -aG adm $USER
```

### دایرکتوری‌های مورد نیاز
یک دایرکتوری برای پروژه خود ایجاد کنید:

```bash
mkdir ~/network_exporter
cd ~/network_exporter
```

فایل‌های زیر را در این دایرکتوری قرار می‌دهیم:
- `network_exporter.py`: اسکریپت اصلی اکسپورتر.
- `prometheus.yml`: فایل تنظیمات پرومتئوس (در صورت نیاز به ویرایش).
- `requirements.txt`: برای نصب وابستگی‌ها.
  ساخت یوزر خاص جدید و دسترسی به دایرکتوری :
```bash
sudo useradd --system --no-create-home --shell /usr/sbin/nologin networkuser
sudo chown networkuser:networkuser [Python Files]
```

## مرحله ۲: نوشتن اسکریپت اکسپورتر

اسکریپت زیر یک اکسپورتر پایتون برای جمع‌آوری متریک‌های کارت شبکه ایجاد می‌کند. این اسکریپت از `psutil` برای خواندن اطلاعات کارت شبکه و از `prometheus_client` برای ارائه متریک‌ها استفاده می‌کند.

```python
import time
import psutil
from prometheus_client import start_http_server, Gauge
import netifaces

# تعریف متریک‌ها
NETWORK_BYTES_SENT = Gauge('network_bytes_sent_total', 'Total bytes sent by network interface', ['interface'])
NETWORK_BYTES_RECEIVED = Gauge('network_bytes_received_total', 'Total bytes received by network interface', ['interface'])
NETWORK_SPEED_SENT = Gauge('network_speed_sent_bytes_per_second', 'Network send speed in bytes per second', ['interface'])
NETWORK_SPEED_RECEIVED = Gauge('network_speed_received_bytes_per_second', 'Network receive speed in bytes per second', ['interface'])

def get_network_interfaces():
    """دریافت لیست کارت‌های شبکه فعال"""
    return netifaces.interfaces()

def collect_network_metrics():
    """جمع‌آوری متریک‌های کارت شبکه"""
    interfaces = get_network_interfaces()
    
    # ذخیره مقادیر قبلی برای محاسبه سرعت
    prev_sent = {}
    prev_recv = {}
    prev_time = time.time()

    while True:
        current_time = time.time()
        delta_time = current_time - prev_time
        
        for interface in interfaces:
            # دریافت اطلاعات کارت شبکه
            stats = psutil.net_io_counters(pernic=True).get(interface)
            if not stats:
                continue
                
            # مقداردهی متریک‌های حجم داده
            NETWORK_BYTES_SENT.labels(interface=interface).set(stats.bytes_sent)
            NETWORK_BYTES_RECEIVED.labels(interface=interface).set(stats.bytes_recv)
            
            # محاسبه سرعت (تفاوت داده‌ها در واحد زمان)
            if interface in prev_sent and delta_time > 0:
                speed_sent = (stats.bytes_sent - prev_sent[interface]) / delta_time
                speed_recv = (stats.bytes_recv - prev_recv[interface]) / delta_time
                NETWORK_SPEED_SENT.labels(interface=interface).set(speed_sent)
                NETWORK_SPEED_RECEIVED.labels(interface=interface).set(speed_recv)
            
            # به‌روزرسانی مقادیر قبلی
            prev_sent[interface] = stats.bytes_sent
            prev_recv[interface] = stats.bytes_recv
        
        prev_time = current_time
        time.sleep(1)  # فاصله زمانی برای جمع‌آوری متریک‌ها

if __name__ == '__main__':
    # شروع سرور HTTP برای ارائه متریک‌ها
    start_http_server(8000)
    print("Network Exporter started on port 8000")
    collect_network_metrics()
```

### توضیحات کد:
 **وارد کردن کتابخانه‌ها**:
   - `کتابخانه psutil`: برای دسترسی به اطلاعات کارت شبکه.
   - `کتابخانه prometheus_client`: برای تعریف متریک‌ها و ارائه آن‌ها به پرومتئوس.
   - `کتابخانه netifaces`: برای دریافت لیست کارت‌های شبکه.
     
 **تعریف متریک‌ها**:
   - از نوع `Gauge` استفاده شده است، زیرا متریک‌های شبکه (مانند حجم و سرعت) می‌توانند افزایش یا کاهش یابند.
   - هر متریک یک برچسب (`interface`) دارد تا داده‌ها برای هر کارت شبکه جداگانه ثبت شوند.
     
 **تابع `get_network_interfaces`**:
   - لیست کارت‌های شبکه فعال (مانند `eth0`، `wlan0`) را برمی‌گرداند.
     
 **تابع `collect_network_metrics`**:
   - به صورت مداوم اطلاعات کارت شبکه را می‌خواند.
   - حجم کل داده‌های ارسالی و دریافتی را ثبت می‌کند.
   - سرعت ارسال و دریافت را با محاسبه تفاوت داده‌ها در واحد زمان محاسبه می‌کند.
     
 **شروع سرور HTTP**:
   - اکسپورتر روی پورت 8000 اجرا می‌شود و متریک‌ها را به پرومتئوس ارائه می‌دهد.

فایل را با نام `network_exporter.py` ذخیره کنید.

## مرحله ۳: تنظیم پرومتئوس

### نصب پرومتئوس
اگر پرومتئوس نصب نشده است، آن را نصب کنید:

```bash
sudo apt install prometheus
```

### ویرایش فایل تنظیمات پرومتئوس
فایل تنظیمات پرومتئوس (معمولاً در `/etc/prometheus/prometheus.yml`) را ویرایش کنید تا اکسپورتر جدید را شناسایی کند:
```bash
sudo nano /etc/prometheus/prometheus.yml
```

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'network_exporter'
    static_configs:
      - targets: ['localhost:8000']
```


### راه‌اندازی پرومتئوس
پرومتئوس را ری‌استارت کنید:

```bash
sudo systemctl restart prometheus
sudo systemctl enable prometheus
```

برای اطمینان از درستی تنظیمات، به آدرس `http://localhost:9090` بروید و در رابط وب پرومتئوس، متریک‌های `network_bytes_sent_total` یا `network_speed_sent_bytes_per_second` را جستجو کنید.

## مرحله ۴: تنظیم گرافانا

### نصب گرافانا
اگر گرافانا نصب نشده است، آن را نصب کنید:

```bash
sudo apt install grafana
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
```

گرافانا به صورت پیش‌فرض روی پورت 3000 اجرا می‌شود. به آدرس `http://localhost:3000` بروید و با نام کاربری و رمز عبور پیش‌فرض (`admin/admin`) وارد شوید.

### افزودن پرومتئوس به عنوان منبع داده
1. در گرافانا، به **Configuration > Data Sources** بروید.
2. روی **Add data source** کلیک کنید و **Prometheus** را انتخاب کنید.
3. در فیلد **URL**، آدرس پرومتئوس را وارد کنید (مثلاً `http://localhost:9090`).
4. روی **Save & Test** کلیک کنید تا اتصال برقرار شود.

### ایجاد داشبورد در گرافانا
 به **Create > Dashboard** بروید و یک پنل جدید اضافه کنید.
 در بخش **Query**، منبع داده را به پرومتئوس تنظیم کنید.
 متریک‌های زیر را برای نمایش اضافه کنید:
   
   - **حجم داده ارسالی**: `network_bytes_sent_total{interface="eth0"}`
   - **حجم داده دریافتی**: `network_bytes_received_total{interface="eth0"}`
   - **سرعت ارسال**: `network_speed_sent_bytes_per_second{interface="eth0"}`
   - **سرعت دریافت**: `network_speed_received_bytes_per_second{interface="eth0"}`
     
   - (جای `eth0` را با نام کارت شبکه خود جایگزین کنید، مثلاً `wlan0`).
     
 نوع نمایش را به **Graph** یا **Time Series** تنظیم کنید.
   
 برای زیباتر شدن داشبورد:
   - از **Unit** مناسب استفاده کنید (مثلاً `bytes` برای حجم و `bytes/sec` برای سرعت).
   - رنگ‌ها و لیبل‌ها را سفارشی کنید.
   - چندین پنل برای هر کارت شبکه ایجاد کنید.
   - 
 داشبورد را ذخیره کنید ، نتیجه داشبورد:
<img width="1257" height="1218" alt="image" src="https://github.com/user-attachments/assets/2dcf462e-afa3-4d88-996c-81d06c3bd3a1" />

### نکات برای نمایش بهینه در گرافانا
- **فیلتر کردن کارت‌های شبکه**: از متغیر (Variable) در گرافانا استفاده کنید تا کاربران بتوانند کارت شبکه مورد نظر را انتخاب کنند. برای این کار:
  1. به **Dashboard Settings > Variables** بروید.
  2. یک متغیر جدید با نام `interface` اضافه کنید.
  3. در بخش **Query**، از `label_values(network_bytes_sent_total, interface)` استفاده کنید.
  4. متغیر را در کوئری‌های خود به صورت `{interface="$interface"}` استفاده کنید.
- **نمایش چندگانه**: برای هر متریک یک پنل جداگانه بسازید تا داشبورد خواناتر شود.
- **استفاده از قالب‌های آماده**: گرافانا قالب‌های آماده‌ای برای مانیتورینگ شبکه دارد. می‌توانید داشبوردهای آماده را از **Grafana Labs** (مثلاً داشبورد ID 1860) وارد کنید و متریک‌های خود را جایگزین کنید.

## مرحله ۵: اجرای اکسپورتر

اسکریپت اکسپورتر را اجرا کنید:

```bash
python3 network_exporter.py
```

برای اجرای دائمی، می‌توانید از `systemd` استفاده کنید:

1. یک فایل سرویس ایجاد کنید:

```bash
sudo nano /etc/systemd/system/network_exporter.service
```

2. محتوای زیر را اضافه کنید:

```ini
[Unit]
Description=Network Exporter Service
After=network.target

[Service]
User=networkuser
Group=networkuser
WorkingDirectory=[Python Files]
ExecStart=[Python Files]/venv/bin/python3 [Python Files]/network_exporter.py
Restart=always

[Install]
WantedBy=multi-user.target
```

3. سرویس را فعال و اجرا کنید:

```bash
sudo systemctl daemon-reload
sudo systemctl start network_exporter
sudo systemctl enable network_exporter
```

## نکات مهم
- **دسترسی‌ها**: اگر اسکریپت با خطای دسترسی مواجه شد، بررسی کنید که کاربر اجراکننده به `/proc/net/dev` دسترسی داشته باشد.
- **کارایی**: فاصله زمانی جمع‌آوری متریک‌ها (1 ثانیه در کد) را بر اساس نیاز تنظیم کنید. مقادیر خیلی کم ممکن است بار سیستمی را افزایش دهد.
- **امنیت**: اکسپورتر روی پورت 8000 اجرا می‌شود. اگر سرور شما در معرض اینترنت است، از فایروال (مانند `ufw`) برای محدود کردن دسترسی استفاده کنید:

```bash
sudo ufw allow from 127.0.0.1 to any port 8000
```

- **مقیاس‌پذیری**: اگر چندین سرور دارید، می‌توانید اکسپورتر را روی هر سرور اجرا کنید و در فایل `prometheus.yml` آدرس‌های آن‌ها را اضافه کنید.
- **دیباگینگ**: برای بررسی متریک‌ها، به آدرس `http://localhost:8000` بروید و خروجی متریک‌ها را مشاهده کنید.

## نتیجه‌گیری
با این آموزش، شما یک اکسپورتر شخصی‌سازی شده برای مانیتورینگ کارت شبکه ساختید که متریک‌های حجم و سرعت داده را جمع‌آوری می‌کند.
این متریک‌ها در پرومتئوس ذخیره شده و در گرافانا به صورت داشبوردهای حرفه‌ای نمایش داده می‌شوند. با تنظیم متغیرها و قالب‌های گرافانا، می‌توانید تجربه کاربری بهتری ایجاد کنید.

برای گسترش این پروژه، می‌توانید متریک‌های دیگری مانند تعداد پکت‌ها یا خطاهای شبکه را اضافه کنید یا داشبوردهای پیچیده‌تری بسازید.
