# برگه تقلب PromQL

برای یادگیری کامل PromQL از ابتدا، به دوره خودآموز و جامع PromQL ما مراجعه کنید!

## انتخاب سری‌ها

### انتخاب آخرین نمونه برای سری‌ها با نام متریک مشخص
```promql
node_cpu_seconds_total
```
این کوئری آخرین نمونه داده را برای متریکی با نام `node_cpu_seconds_total` انتخاب می‌کند.

### انتخاب بازه ۵ دقیقه‌ای از نمونه‌ها برای سری‌ها با نام متریک مشخص
```promql
node_cpu_seconds_total[5m]
```
این کوئری تمام نمونه‌های داده در بازه زمانی ۵ دقیقه گذشته را برای متریک `node_cpu_seconds_total` انتخاب می‌کند.

### سری‌هایی با مقادیر برچسب مشخص
```promql
node_cpu_seconds_total{cpu="0",mode="idle"}
```
این کوئری سری‌هایی را انتخاب می‌کند که برچسب `cpu` برابر با `"0"` و برچسب `mode` برابر با `"idle"` باشد.

### تطبیق پیچیده برچسب‌ها
```promql
node_cpu_seconds_total{cpu!="0",mode=~"user|system"}
```
این کوئری از تطبیق‌دهنده‌های برچسب پیچیده استفاده می‌کند:
- `!=`: عدم برابری (غیر برابر)
- `=~`: تطبیق با عبارت منظم (regex)
- `!~`: تطبیق منفی با عبارت منظم
در اینجا، سری‌هایی انتخاب می‌شوند که برچسب `cpu` برابر با `"0"` نباشد و برچسب `mode` با یکی از مقادیر `"user"` یا `"system"` مطابقت داشته باشد.

### انتخاب داده از یک روز قبل و جابه‌جایی به زمان کنونی
```promql
process_resident_memory_bytes offset 1d
```
این کوئری داده‌های متریک `process_resident_memory_bytes` از یک روز قبل را انتخاب کرده و آن‌ها را به زمان کنونی منتقل می‌کند.

## نرخ‌های افزایش برای کانترها

### نرخ افزایش در ثانیه، میانگین در ۵ دقیقه گذشته
```promql
rate(demo_api_request_duration_seconds_count[5m])
```
این کوئری نرخ افزایش در ثانیه را برای متریک `demo_api_request_duration_seconds_count` در بازه ۵ دقیقه گذشته محاسبه می‌کند.

### نرخ افزایش در ثانیه، محاسبه‌شده بر اساس دو نمونه آخر در بازه زمانی ۱ دقیقه
```promql
irate(demo_api_request_duration_seconds_count[1m])
```
این کوئری نرخ افزایش در ثانیه را بر اساس دو نمونه آخر در بازه ۱ دقیقه محاسبه می‌کند.

### افزایش مطلق در یک ساعت گذشته
```promql
increase(demo_api_request_duration_seconds_count[1h])
```
این کوئری مقدار افزایش مطلق متریک `demo_api_request_duration_seconds_count` را در یک ساعت گذشته محاسبه می‌کند.

## تجمیع روی چندین سری

### جمع کل سری‌ها
```promql
sum(node_filesystem_size_bytes)
```
این کوئری مجموع تمام سری‌های متریک `node_filesystem_size_bytes` را محاسبه می‌کند.

### حفظ ابعاد برچسب instance و job
```promql
sum by(job, instance) (node_filesystem_size_bytes)
```
این کوئری مجموع سری‌ها را محاسبه می‌کند اما ابعاد برچسب `job` و `instance` را حفظ می‌کند.

### حذف ابعاد برچسب instance و job
```promql
sum without(instance, job) (node_filesystem_size_bytes)
```
این کوئری مجموع سری‌ها را محاسبه می‌کند و ابعاد برچسب `job` و `instance` را حذف می‌کند.

### عملگرهای تجمیع موجود
`sum()`, `min()`, `max()`, `avg()`, `stddev()`, `stdvar()`, `count()`, `count_values()`, `group()`, `bottomk()`, `topk()`, `quantile()`

## عملیات ریاضی بین سری‌ها

### جمع سری‌های با برچسب یکسان
```promql
node_memory_MemFree_bytes + node_memory_Cached_bytes
```
این کوئری مقادیر سری‌های `node_memory_MemFree_bytes` و `node_memory_Cached_bytes` را که برچسب‌های یکسانی دارند، جمع می‌کند.

### جمع سری‌ها با تطبیق فقط روی برچسب‌های instance و job
```promql
node_memory_MemFree_bytes + on(instance, job) node_memory_Cached_bytes
```
این کوئری سری‌ها را فقط بر اساس برچسب‌های `instance` و `job` تطبیق داده و جمع می‌کند.

### جمع سری‌ها با نادیده گرفتن برچسب‌های instance و job
```promql
node_memory_MemFree_bytes + ignoring(instance, job) node_memory_Cached_bytes
```
این کوئری سری‌ها را با نادیده گرفتن برچسب‌های `instance` و `job` برای تطبیق، جمع می‌کند.

### اجازه صریح تطبیق چند به یک
```promql
rate(demo_cpu_usage_seconds_total[1m]) / on(instance, job) group_left demo_num_cpus
```
این کوئری امکان تطبیق چند به یک را به صورت صریح فراهم می‌کند.

### شامل کردن برچسب version از سمت راست در نتیجه
```promql
node_filesystem_avail_bytes * on(instance, job) group_left(version) node_exporter_build_info
```
این کوئری برچسب `version` را از سمت راست (one) در نتیجه نهایی شامل می‌کند.

### عملگرهای حسابی موجود
`+`, `-`, `*`, `/`, `%`, `^`

## فیلتر کردن سری‌ها بر اساس مقدار

### نگه داشتن سری‌هایی با مقدار نمونه بیشتر از یک عدد مشخص
```promql
node_filesystem_avail_bytes > 10*1024*1024
```
این کوئری فقط سری‌هایی را نگه می‌دارد که مقدار نمونه آن‌ها بیشتر از ۱۰ مگابایت باشد.

### نگه داشتن سری‌هایی که مقادیرشان بزرگ‌تر از مقادیر سمت راست است
```promql
go_goroutines > go_threads
```
این کوئری سری‌هایی از سمت چپ را نگه می‌دارد که مقادیر نمونه آن‌ها بزرگ‌تر از مقادیر سری‌های تطبیق‌یافته سمت راست باشد.

### بازگشت ۰ یا ۱ به جای فیلتر کردن
```promql
go_goroutines > bool go_threads
```
این کوئری به جای فیلتر کردن سری‌ها، برای هر سری مقایسه‌شده مقدار ۰ یا ۱ را برمی‌گرداند.

### تطبیق فقط روی برچسب‌های خاص
```promql
go_goroutines > bool on(job, instance) go_threads
```
این کوئری مقایسه را فقط بر اساس برچسب‌های `job` و `instance` انجام می‌دهد.

### عملگرهای مقایسه‌ای موجود
`==`, `!=`, `>`, `<`, `>=`, `<=`

## عملیات مجموعه‌ای

### شامل کردن مجموعه‌های برچسب از هر دو طرف
```promql
up{job="prometheus"} or up{job="node"}
```
این کوئری هر مجموعه برچسبی که در سمت چپ یا راست وجود داشته باشد را شامل می‌شود.

### شامل کردن مجموعه‌های برچسب موجود در هر دو طرف
```promql
node_network_mtu_bytes and (node_network_address_assign_type == 0)
```
این کوئری فقط مجموعه‌های برچسبی را شامل می‌شود که در هر دو طرف حضور دارند.

### شامل کردن مجموعه‌های برچسب از سمت چپ که در سمت راست نیستند
```promql
node_network_mtu_bytes unless (node_network_address_assign_type == 1)
```
این کوئری مجموعه‌های برچسبی از سمت چپ را شامل می‌شود که در سمت راست وجود ندارند.

### تطبیق فقط روی برچسب‌های خاص
```promql
node_network_mtu_bytes and on(device) (node_network_address_assign_type == 0)
```
این کوئری عملیات مجموعه‌ای را فقط بر اساس برچسب `device` انجام می‌دهد.

## کوانتایل‌ها از هیستوگرام‌ها

### کوانتایل ۹۰ درصد تأخیر درخواست در ۵ دقیقه گذشته
```promql
histogram_quantile(0.9, rate(demo_api_request_duration_seconds_bucket[5m]))
```
این کوئری کوانتایل ۹۰ درصد تأخیر درخواست را برای تمام ابعاد برچسب در بازه ۵ دقیقه گذشته محاسبه می‌کند.

### کوانتایل فقط برای ابعاد path و method
```promql
histogram_quantile(
  0.9,
  sum by(le, path, method) (
    rate(demo_api_request_duration_seconds_bucket[5m])
  )
)
```
این کوئری کوانتایل ۹۰ درصد را فقط برای ابعاد برچسب `path` و `method` محاسبه می‌کند.

## تغییرات در گیج‌ها

### مشتق در ثانیه با استفاده از رگرسیون خطی
```promql
deriv(demo_disk_usage_bytes[1h])
```
این کوئری مشتق در ثانیه را برای متریک `demo_disk_usage_bytes` در بازه یک ساعته با استفاده از رگرسیون خطی محاسبه می‌کند.

### تغییر مطلق در مقدار طی یک ساعت گذشته
```promql
delta(demo_disk_usage_bytes[1h])
```
این کوئری تغییر مطلق مقدار متریک `demo_disk_usage_bytes` را در یک ساعت گذشته محاسبه می‌کند.

### پیش‌بینی مقدار در یک ساعت آینده بر اساس ۴ ساعت گذشته
```promql
predict_linear(demo_disk_usage_bytes[4h], 3600)
```
این کوئری مقدار متریک `demo_disk_usage_bytes` را برای یک ساعت آینده بر اساس داده‌های ۴ ساعت گذشته پیش‌بینی می‌کند.

## تجمیع در طول زمان

### میانگین در هر سری طی دوره ۵ دقیقه‌ای
```promql
avg_over_time(go_goroutines[5m])
```
این کوئری میانگین مقادیر هر سری را در بازه ۵ دقیقه محاسبه می‌کند.

### حداکثر هر سری در دوره یک‌روزه
```promql
max_over_time(process_resident_memory_bytes[1d])
```
این کوئری حداکثر مقدار هر سری را در بازه یک روز محاسبه می‌کند.

### شمارش تعداد نمونه‌ها برای هر سری در دوره ۵ دقیقه‌ای
```promql
count_over_time(process_resident_memory_bytes[5m])
```
این کوئری تعداد نمونه‌های هر سری را در بازه ۵ دقیقه محاسبه می‌کند.

## زمان

### دریافت زمان یونیکس در ثانیه در هر گام رزولوشن
```promql
time()
```
این کوئری زمان فعلی یونیکس را در ثانیه برای هر گام رزولوشن برمی‌گرداند.

### محاسبه سن آخرین اجرای موفق جاب دسته‌ای
```promql
time() - demo_batch_last_success_timestamp_seconds
```
این کوئری فاصله زمانی از آخرین اجرای موفق جاب دسته‌ای را محاسبه می‌کند.

### یافتن جاب‌های دسته‌ای که در یک ساعت گذشته موفق نبوده‌اند
```promql
time() - demo_batch_last_success_timestamp_seconds > 3600
```
این کوئری جاب‌های دسته‌ای را پیدا می‌کند که در یک ساعت گذشته موفق به اجرا نشده‌اند.

## مدیریت داده‌های گمشده

### ایجاد یک سری خروجی وقتی بردار ورودی خالی است
```promql
absent(up{job="some-job"})
```
این کوئری در صورت خالی بودن بردار ورودی، یک سری خروجی ایجاد می‌کند.

### ایجاد یک سری خروجی وقتی بردار بازه‌ای در ۵ دقیقه خالی است
```promql
absent_over_time(up{job="some-job"}[5m])
```
این کوئری در صورت خالی بودن بردار بازه‌ای در بازه ۵ دقیقه، یک سری خروجی ایجاد می‌کند.

## دستکاری برچسب‌ها

### اتصال مقادیر دو برچسب با جداکننده
```promql
label_join(rate(demo_api_request_duration_seconds_count[5m]), "endpoint", " ", "method", "path")
```
این کوئری مقادیر برچسب‌های `method` و `path` را با جداکننده فاصله (" ") به یک برچسب جدید به نام `endpoint` متصل می‌کند.

### استخراج بخشی از یک برچسب و ذخیره در برچسب جدید
```promql
label_replace(up, "hostname", "$1", "instance", "(.+):(\\d+)")
```
این کوئری بخشی از برچسب `instance` را استخراج کرده و در برچسب جدید `hostname` ذخیره می‌کند.

## زیرکوئری‌ها

### محاسبه نرخ میانگین ۵ دقیقه‌ای در دوره یک ساعته
```promql
rate(demo_api_request_duration_seconds_count[5m])[1h:]
```
این کوئری نرخ میانگین ۵ دقیقه‌ای را در بازه یک ساعته با رزولوشن پیش‌فرض محاسبه می‌کند.

### محاسبه نرخ میانگین ۵ دقیقه‌ای در دوره یک ساعته با رزولوشن ۱۵ ثانیه
```promql
rate(demo_api_request_duration_seconds_count[5m])[1h:15s]
```
این کوئری نرخ میانگین ۵ دقیقه‌ای را در بازه یک ساعته با رزولوشن ۱۵ ثانیه محاسبه می‌کند.

### استفاده از نتیجه زیرکوئری برای دریافت حداکثر نرخ در یک ساعت
```promql
max_over_time(
  rate(
    demo_api_request_duration_seconds_count[5m]
  )[1h:]
)
```
این کوئری حداکثر نرخ را از نتیجه زیرکوئری در بازه یک ساعته محاسبه می‌کند.

## اطلاعات بیشتر
برای جزئیات بیشتر در مورد PromQL، به مستندات رسمی PromQL مراجعه کنید:
- [مبانی](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [عملگرها](https://prometheus.io/docs/prometheus/latest/querying/operators/)
- [توابع](https://prometheus.io/docs/prometheus/latest/querying/functions/)
- [مثال‌ها](https://prometheus.io/docs/prometheus/latest/querying/examples/)

برای یادگیری بیشتر، دوره خودآموز و جامع PromQL ما را که توسط خالق PromQL طراحی شده است، بررسی کنید.

© 2025 PromLabs GmbH
