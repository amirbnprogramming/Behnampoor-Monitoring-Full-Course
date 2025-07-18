# آموزش پرومتئوس - قسمت نهم: مانیتورینگ متریک‌های سفارشی با Textfile Collector در Node Exporter

در این قسمت از سری آموزش‌های پرومتئوس، به بررسی ماژول **Textfile Collector** در **Node Exporter** می‌پردازیم که به شما امکان می‌دهد متریک‌های سفارشی را از سیستم لینوکس یا یونیکسی خود به پرومتئوس اضافه کنید. این ماژول برای جمع‌آوری اطلاعاتی که به‌صورت پیش‌فرض توسط Node Exporter ارائه نمی‌شوند (مانند وضعیت کنترلر RAID یا اطلاعات بسته‌های نصب‌شده) بسیار مفید است. در این آموزش، به‌صورت گام‌به‌گام نحوه پیکربندی Textfile Collector، تولید متریک‌های سفارشی، و نمایش آن‌ها در پرومتئوس و گرافانا را توضیح می‌دهیم. همچنین، ریشه‌یابی مسئله و کاربردهای این ماژول را با مثال‌های عملی و عمیق بررسی می‌کنیم.

## ریشه‌یابی مسئله: چرا Textfile Collector به وجود آمد؟

### مشکل
خود Node Exporter به‌صورت پیش‌فرض متریک‌های استاندارد سیستم (مانند CPU، حافظه، دیسک، و شبکه) را جمع‌آوری می‌کند، اما بسیاری از سناریوها نیاز به متریک‌های خاص دارند که در کلکتورهای پیش‌فرض وجود ندارند.

#### مثلاً:
- اطلاعات مربوط به وضعیت یک کنترلر RAID.
- تعداد بسته‌های نصب‌شده در سیستم.
- خروجی‌های خاص از اسکریپت‌های سفارشی یا ابزارهای مانیتورینگ.
 
اینا همگی در خود Node_Exporter به طور پیش فرض نیستند .
این متریک‌ها معمولاً در قالب استاندارد پرومتئوس (فرمت متنی OpenMetrics) توسط سیستم ارائه نمی‌شوند. بدون راهی برای افزودن این متریک‌ها، مانیتورینگ کامل سیستم دشوار می‌شود.

### راه‌حل
ماژول **Textfile Collector** به‌عنوان یک راه‌حل انعطاف‌پذیر طراحی شد تا:
- به کاربران اجازه دهد متریک‌های سفارشی را در فایل‌های متنی با فرمت `.prom` تولید کنند.
- خود Node Exporter این فایل‌ها را بخواند و متریک‌ها را به خروجی خود اضافه کند.
- پرومتئوس هم بتواند این متریک‌ها را مانند سایر متریک‌های Node Exporter اسکرپ کند.

### کاربردها
- **مانیتورینگ سخت‌افزار خاص:** مانند وضعیت دیسک‌های RAID یا دمای حسگرهای خاص.
- **مانیتورینگ نرم‌افزارها:** مثلاً تعداد کاربران فعال در یک اپلیکیشن یا وضعیت یک سرویس خاص.
- **اتوماسیون و اسکریپت‌ها:** استفاده از کرون‌جاب‌ها یا اسکریپت‌ها برای تولید متریک‌های پویا.
- **انعطاف‌پذیری:** امکان ادغام با ابزارهای دیگر (مثل اسکریپت‌های Bash، Python یا Go) برای تولید متریک.

## پیش‌نیازها
- اول اینکه Node Exporter روی سیستم نصب شده باشد (مراجعه به قسمت هشتم آموزش).
- دوم ، پرومتئوس برای اسکرپ متریک‌ها تنظیم شده باشد.
- سوم ،گرافانا (اختیاری) برای بصری‌سازی متریک‌ها.
- در نهایت ، دسترسی به خط فرمان لینوکس و دانش اولیه درباره نوشتن اسکریپت.

## گام ۱: فعال‌سازی Textfile Collector

خود Textfile Collector به‌صورت پیش‌فرض در Node Exporter فعال است، اما باید یک دایرکتوری برای ذخیره فایل‌های `.prom` مشخص کنید.

1. **ایجاد دایرکتوری برای فایل‌های متریک:**
```bash
sudo mkdir /var/lib/node_exporter/textfile_metrics
sudo chown node_exporter:node_exporter /var/lib/node_exporter/textfile_metrics
```

2. **پیکربندی Node Exporter:**
فایل سرویس Systemd را ویرایش کنید تا دایرکتوری مشخص شود:
```bash
sudo nano /etc/systemd/system/node_exporter.service
```

خط `ExecStart` را به‌صورت زیر به‌روزرسانی کنید:
```ini
ExecStart=/usr/bin/node_exporter --collector.textfile.directory=/var/lib/node_exporter/textfile_metrics
```

3. **ری‌استارت سرویس:**
```bash
sudo systemctl daemon-reload
sudo systemctl restart node_exporter
sudo systemctl status node_exporter
```

## گام ۲: تولید فایل متریک‌های سفارشی

فایل‌های متریک باید:
- در فرمت متنی پرومتئوس (OpenMetrics) باشند.
- پسوند `.prom` داشته باشند.
- به‌صورت اتمیک (atomic) نوشته شوند تا از خواندن ناقص توسط Node Exporter جلوگیری شود.

### فرمت فایل `.prom`
یک فایل `.prom` شامل خطوطی با ساختار زیر است:
```
# HELP metric_name توضیح مختصر درباره متریک
# TYPE metric_name type
metric_name{label1="value1", label2="value2"} value
```
- **قسمت HELP:** توضیحی برای متریک.
- **قسمت TYPE:** نوع متریک (مثل `gauge`، `counter`، یا `histogram`).
- **قسمت value:** مقدار عددی آن متریک که pull شده .

### مثال ۱: مانیتورینگ زمان اجرای کرون‌جاب
فرض کنید یک کرون‌جاب دارید که می‌خواهید زمان آخرین اجرای آن را مانیتور کنید.

1. **ایجاد اسکریپت برای تولید متریک:**
   فایل اسکریپت Bash زیر را ایجاد کنید:
```bash
nano /usr/local/bin/generate_cron_metric.sh
```

   محتوای اسکریپت:
```bash
#!/bin/bash
METRIC_DIR="/var/lib/node_exporter/textfile_metrics"
TEMP_FILE="$METRIC_DIR/cron_last_run.$$.prom"
FINAL_FILE="$METRIC_DIR/cron_last_run.prom"

   # تولید متریک
echo "# HELP cron_last_run_timestamp Timestamp of the last cron job run in Unix seconds" > $TEMP_FILE
echo "# TYPE cron_last_run_timestamp gauge" >> $TEMP_FILE
echo "cron_last_run_timestamp $(date +%s)" >> $TEMP_FILE

   # انتقال اتمیک فایل
mv $TEMP_FILE $FINAL_FILE
```

2. **اعطای مجوز اجرا:**
```bash
chmod +x /usr/local/bin/generate_cron_metric.sh
```

3. **تنظیم کرون‌جاب:**
   کرون‌جاب را برای اجرای دوره‌ای اسکریپت تنظیم کنید:
```bash
crontab -e
```
   خط زیر را اضافه کنید تا هر دقیقه اجرا شود:
```
* * * * * /usr/local/bin/generate_cron_metric.sh
```

4. **بررسی در Node Exporter:**
   به آدرس `http://localhost:9100/metrics` بروید و متریک `cron_last_run_timestamp` را جستجو کنید. باید چیزی شبیه این ببینید:
```
# HELP cron_last_run_timestamp Timestamp of the last cron job run in Unix seconds
# TYPE cron_last_run_timestamp gauge
cron_last_run_timestamp 1698765432
```

5. **کوئری در پرومتئوس:**
   در رابط وب پرومتئوس، کوئری زیر را اجرا کنید:
```promql
cron_last_run_timestamp
```
   این کوئری زمان آخرین اجرای کرون‌جاب را نشان می‌دهد.

**کاربرد:** می‌توانید هشدار تنظیم کنید تا اگر کرون‌جاب برای مدتی اجرا نشد، اطلاع‌رسانی شود:
```promql
ALERT CronJobNotRunning
  IF time() - cron_last_run_timestamp > 300
  FOR 5m
  LABELS { severity = "warning" }
  ANNOTATIONS {
    summary = "کرون‌جاب اجرا نشده است",
    description = "کرون‌جاب برای بیش از ۵ دقیقه اجرا نشده است."
  }
```

### مثال ۲: مانیتورینگ تعداد بسته‌های نصب‌شده
فرض کنید می‌خواهید تعداد بسته‌های نصب‌شده در سیستم (مثلاً در Ubuntu) را مانیتور کنید.

1. **ایجاد اسکریپت:**
```bash
nano /usr/local/bin/package_count_metric.sh
```

   محتوای اسکریپت:
```bash
#!/bin/bash
METRIC_DIR="/var/lib/node_exporter/textfile_metrics"
TEMP_FILE="$METRIC_DIR/package_count.$$.prom"
FINAL_FILE="$METRIC_DIR/package_count.prom"

   # شمارش بسته‌های نصب‌شده
PACKAGE_COUNT=$(dpkg -l | grep ^ii | wc -l)

   # تولید متریک
echo "# HELP node_package_count Number of installed packages on the system" > $TEMP_FILE
echo "# TYPE node_package_count gauge" >> $TEMP_FILE
echo "node_package_count $PACKAGE_COUNT" >> $TEMP_FILE

   # انتقال اتمیک
mv $TEMP_FILE $FINAL_FILE
```

2. **اجرا و کرون‌جاب:**
   مانند مثال قبل، اسکریپت را قابل اجرا کنید و به کرون اضافه کنید:
```
* * * * * /usr/local/bin/package_count_metric.sh
```

3. **بررسی در پرومتئوس:**
   کوئری:
```promql
node_package_count
```
   این کوئری تعداد بسته‌های نصب‌شده را نشان می‌دهد.

**کاربرد:** می‌توانید تغییرات غیرمنتظره در تعداد بسته‌ها (مثلاً نصب یا حذف ناخواسته) را تشخیص دهید.

### مثال ۳: استفاده از کتابخانه Go
برای تولید متریک‌های پیچیده‌تر، می‌توانید از کتابخانه Go پرومتئوس استفاده کنید.

1. **نصب Go (اگر نصب نیست):**
```bash
sudo apt install golang
```

2. **ایجاد برنامه Go:**
   فایل `generate_metric.go`:
```go
package main

import (
       "github.com/prometheus/client_golang/prometheus"
       "github.com/prometheus/client_golang/prometheus/collectors"
       "github.com/prometheus/common/expfmt"
       "os"
)

func main() {
   registry := prometheus.NewRegistry()
   gauge := prometheus.NewGauge(prometheus.GaugeOpts{
   Name: "custom_service_status",
   Help: "Status of a custom service (1=up, 0=down)",
})
registry.Register(gauge)
       // فرض کنید وضعیت سرویس را بررسی می‌کنید
gauge.Set(1) // سرویس فعال است

       // نوشتن متریک به فایل
file, _ := os.Create("/var/lib/node_exporter/textfile_metrics/service_status.prom")
defer file.Close()
encoder := expfmt.NewEncoder(file, expfmt.FmtText)
encoder.Encode(collectors.NewGoCollector())
encoder.Encode(registry.MustRegister(gauge).(*prometheus.GaugeVec))
}
   ```

3. **کامپایل و اجرا:**
```bash
go build -o generate_metric generate_metric.go
sudo mv generate_metric /usr/local/bin/
/usr/local/bin/generate_metric
```

4. **بررسی متریک:**
   متریک `custom_service_status` در `http://localhost:9100/metrics` ظاهر می‌شود.

**کاربرد:** این روش برای برنامه‌های پیچیده‌تر که نیاز به متریک‌های پویا دارند مناسب است.

## گام ۳: ادغام با پرومتئوس و گرافانا

1. **اسکرپ متریک‌ها در پرومتئوس:**
   مطمئن شوید که Node Exporter در فایل `prometheus.yml` تنظیم شده است:
```yaml
scrape_configs:
   - job_name: 'node_exporter'
      scrape_interval: 15s
      static_configs:
         - targets: ['localhost:9100']
```

2. **ایجاد داشبورد گرافانا:**
   - داشبورد **Node Exporter Full (ID: 1860)** را ایمپورت کنید.
   - برای متریک‌های سفارشی، یک پنل جدید اضافه کنید:
     - **کوئری:** `cron_last_run_timestamp` یا `node_package_count`
     - **نوع پنل:** Gauge (برای مقادیر لحظه‌ای) یا Graph (برای تغییرات زمانی).
     - **عنوان:** مثلاً «زمان آخرین اجرای کرون‌جاب» یا «تعداد بسته‌های نصب‌شده».

## نکات کاربردی

1. **نوشتن اتمیک فایل‌ها:**
   - همیشه از فایل موقت استفاده کنید و با `mv` آن را به مقصد نهایی منتقل کنید تا از خواندن ناقص توسط Node Exporter جلوگیری شود.
   - مثال:
```bash
mv temp_file.prom final_file.prom
```

2. **مدیریت تعداد متریک‌ها:**
   - از تولید متریک‌های بیش از حد خودداری کنید، زیرا ممکن است عملکرد Node Exporter یا پرومتئوس را تحت تأثیر قرار دهد.
   - کلکتورهای غیرضروری را غیرفعال کنید (مثل `--no-collector.diskstats`).

3. **امنیت:**
   - دایرکتوری `/var/lib/node_exporter/textfile_metrics` باید فقط برای کاربر `node_exporter` قابل نوشتن باشد:
```bash
sudo chmod 750 /var/lib/node_exporter/textfile_metrics
```

4. **منابع الهام:**
   - مخزن [prometheus-community/node-exporter-textfile-collector-scripts](https://github.com/prometheus-community/node-exporter-textfile-collector-scripts) شامل اسکریپت‌های آماده برای تولید متریک است.

## مثال جامع: مانیتورینگ وضعیت RAID
فرض کنید می‌خواهید وضعیت یک کنترلر RAID را مانیتور کنید.

1. **اسکریپت برای بررسی RAID:**
```bash
nano /usr/local/bin/raid_status_metric.sh
```
```bash
#!/bin/bash
METRIC_DIR="/var/lib/node_exporter/textfile_metrics"
TEMP_FILE="$METRIC_DIR/raid_status.$$.prom"
FINAL_FILE="$METRIC_DIR/raid_status.prom"

   # فرض کنید از ابزار megacli برای بررسی RAID استفاده می‌کنید
RAID_STATUS=$(megacli -LDInfo -Lall -aALL | grep "State" | grep -c "Optimal")
echo "# HELP node_raid_status Number of RAID arrays in optimal state" > $TEMP_FILE
echo "# TYPE node_raid_status gauge" >> $TEMP_FILE
echo "node_raid_status $RAID_STATUS" >> $TEMP_FILE

mv $TEMP_FILE $FINAL_FILE
```

2. **تنظیم کرون:**
```bash
crontab -e
```
```
*/5 * * * * /usr/local/bin/raid_status_metric.sh
```


## جمع‌بندی
ماژول **Textfile Collector** در Node Exporter به شما امکان می‌دهد متریک‌های سفارشی را به‌راحتی به سیستم مانیتورینگ پرومتئوس اضافه کنید. با استفاده از اسکریپت‌های ساده یا ابزارهای پیچیده‌تر (مثل Go)، می‌توانید هر نوع داده‌ای را به متریک تبدیل کنید. این ماژول انعطاف‌پذیری بالایی برای مانیتورینگ سناریوهای خاص فراهم می‌کند. با رعایت نکات امنیتی و بهینه‌سازی، می‌توانید سیستم‌های خود را با دقت و کارایی بالا مانیتور کنید. برای ایده‌های بیشتر، مخزن اسکریپت‌های جامعه پرومتئوس را بررسی کنید یا سوالات خود را در بخش نظرات مطرح کنید!
