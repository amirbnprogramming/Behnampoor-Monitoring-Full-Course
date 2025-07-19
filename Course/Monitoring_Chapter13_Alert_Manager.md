# آموزش پرومتئوس - قسمت سیزدهم هشدارها و Alertmanager 

در این آموزش، به صورت عمیق و جامع به موضوع **هشدارها (Alerting)** در پرومتئوس و نحوه استفاده از **Alertmanager** می‌پردازیم.
این راهنما از مفاهیم پایه شروع می‌کند، به مثال‌های عملی می‌رسد و در نهایت به بررسی عمیق Alertmanager و نحوه کار با آن می‌پردازد. 
هدف این است که تمام جنبه‌های مرتبط با هشدارها، از فلسفه و مفاهیم اولیه تا پیاده‌سازی و مدیریت، به زبانی ساده و قابل فهم توضیح داده شود.

---

## 1. فلسفه هشدارها در پرومتئوس

هشدارها در پرومتئوس یکی از اجزای کلیدی برای نظارت (Monitoring) و اطمینان از پایداری و سلامت سیستم‌ها هستند.
فلسفه اصلی هشدارها این است که به تیم‌های عملیاتی اجازه دهند قبل از وقوع مشکلات بزرگ، از مسائل احتمالی آگاه شوند و اقدامات لازم را انجام دهند. هشدارها به ما کمک می‌کنند تا:

- **مشکلات را زود تشخیص دهیم**: به جای اینکه منتظر خرابی سیستم باشیم، می‌توانیم با تنظیم آستانه‌های مشخص، مشکلات را در مراحل اولیه شناسایی کنیم.
- **اولویت‌بندی کنیم**: هشدارها بر اساس شدت (Severity) اولویت‌بندی می‌شوند تا تیم‌ها بدانند کدام مسائل فوریت بیشتری دارند.
- **اتوماسیون را بهبود دهیم**: هشدارها می‌توانند به سیستم‌های خودکار متصل شوند تا اقدامات اصلاحی به صورت خودکار انجام شوند.

### مثال جذاب:
فرض کنید شما یک اپلیکیشن فروش آنلاین دارید.
اگر نرخ خطای درخواست‌ها (Error Rate) به بیش از 5% برسد، می‌خواهید فوراً مطلع شوید تا تیم توسعه سریعاً مشکل را بررسی کند.
یا اگر سرور شما بیش از 80% از ظرفیت CPU را استفاده کند، هشداری دریافت کنید تا قبل از کند شدن سیستم، سرور جدیدی اضافه کنید.
این هشدارها مثل یک نگهبان هوشیار عمل می‌کنند که قبل از به صدا درآمدن زنگ خطر، شما را بیدار می‌کند!

---

## 2. مفاهیم پایه در هشدارها

### 2.1 هشدار چیست؟
هشدار (Alert) یک اعلان است که وقتی یک شرط خاص در داده‌های جمع‌آوری‌شده توسط پرومتئوس برقرار شود، فعال (Firing) می‌شود. این شرط‌ها در قالب **Prometheus Rules** تعریف می‌شوند.

### 2.2 اجزای اصلی هشدارها
- بخش **Prometheus Rules**: قوانینی که شرایط هشدار را تعریف می‌کنند (مثلاً اگر CPU Usage بیش از 80% شد).
- بخش **Alertmanager**: ابزاری که هشدارهای تولیدشده توسط پرومتئوس را مدیریت کرده و به مقصدهای مختلف (مانند Slack، Email، PagerDuty) ارسال می‌کند.
- **شدت (Severity)**: نشان‌دهنده میزان اهمیت هشدار است (مثل Critical، Warning، Info).
- **وضعیت‌های هشدار**:
  - **مرحله Pending**: هشدار فعال شده اما هنوز به مدت زمان مشخصی (Duration) نرسیده تا به حالت Firing برود.
  - **مرحله Firing**: هشدار به طور کامل فعال شده و به Alertmanager ارسال شده است.
  - **مرحله Resolved**: هشدار برطرف شده و دیگر فعال نیست.

### 2.3 کی هشدار تولید می‌کند؟
پرومتئوس مسئول تولید هشدارها بر اساس قوانین تعریف‌شده (Prometheus Rules) است.
این قوانین در قالب **Custom Resource Definitions (CRDs)** یا فایل‌های YAML تعریف می‌شوند و پرومتئوس داده‌های متریک را بررسی می‌کند تا ببیند آیا شرایط هشدار برقرار است یا خیر.

---

## 3. سیستم‌های مدیریت هشدار

مدیریت هشدارها در پرومتئوس توسط **Alertmanager** انجام می‌شود. 
این ابزار وظیفه دریافت هشدارها از پرومتئوس و مدیریت آن‌ها (مانند گروه‌بندی، سرکوب، ارسال به مقصدهای مختلف) را بر عهده دارد.

### 3.1 وظایف Alertmanager
- **گروه‌بندی (Grouping)**: هشدارهای مرتبط را در یک اعلان ترکیب می‌کند تا از اسپم شدن جلوگیری شود.
- **سرکوب (Inhibition)**: اگر یک هشدار مهم‌تر فعال باشد، هشدارهای کم‌اهمیت‌تر را سرکوب می‌کند.
- **سکوت (Silencing)**: امکان غیرفعال کردن موقت هشدارها برای دوره‌های خاص (مثلاً در زمان نگهداری سیستم).
- **ارسال اعلان‌ها**: هشدارها را به مقصدهایی مثل Slack، Email، PagerDuty یا سیستم‌های دیگر ارسال می‌کند.

### 3.2 معماری Alertmanager
سرویس Alertmanager معمولاً به صورت یک جزء جداگانه در کنار پرومتئوس نصب می‌شود. 
در یک خوشه Kubernetes، می‌توان آن را از طریق Helm Chart (مانند kube-prometheus-stack) نصب کرد.
پرومتئوس هشدارها را به Alertmanager ارسال می‌کند و Alertmanager بر اساس تنظیماتش (مانند فایل `alertmanager.yml`) تصمیم می‌گیرد که چه اقدامی انجام دهد.

---

## 4. راه‌های مدیریت هشدارها

مدیریت موثر هشدارها نیازمند رعایت چند اصل است:
1. **وضوح در تعریف هشدارها**: هشدارها باید دقیق و مرتبط با مشکلات واقعی باشند.
2. **اولویت‌بندی**: هشدارهای بحرانی (Critical) باید از هشدارهای اطلاعاتی (Info) متمایز شوند.
3. **کاهش نویز**: از ایجاد هشدارهای غیرضروری که باعث خستگی تیم می‌شوند (Alert Fatigue) خودداری کنید.
4. **اتوماسیون**: هشدارها را به ابزارهای خودکار متصل کنید تا اقدامات اصلاحی سریع‌تر انجام شوند.
5. **مستندسازی**: برای هر هشدار، یک Runbook (راهنمای عملیاتی) تهیه کنید تا تیم‌ها بدانند چگونه به آن واکنش نشان دهند.

---

## 5. عمیق شدن در Alertmanager

### 5.1 نصب Alertmanager
سرویس Alertmanager معمولاً از طریق Helm Chart به نام `kube-prometheus-stack` نصب می‌شود.
این Helm Chart شامل پرومتئوس، Alertmanager، Grafana و سایر ابزارهای نظارتی است.

#### مثال نصب با Helm:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prom prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --values prom-alertmanager-values.yaml
```

### 5.2 فایل تنظیمات Alertmanager
فایل تنظیمات Alertmanager (معمولاً `alertmanager.yml`) شامل بخش‌های زیر است:
- **قسمت Global**: تنظیمات کلی مثل URL وب‌هوک Slack یا تنظیمات SMTP برای ایمیل.
- **قسمت Route**: تعریف مسیرهای هدایت هشدارها (مثلاً کدام هشدار به کدام مقصد ارسال شود).
- **قسمت Receivers**: تعریف مقصدهای اعلان (مثل Slack، PagerDuty).
- **قسمت Inhibit Rules**: قوانینی برای سرکوب هشدارهای کم‌اهمیت.

#### مثال فایل تنظیمات Alertmanager:
```yaml
global:
  slack_api_url: 'https://hooks.slack.com/services/xxx/yyy/zzz'

route:
  receiver: 'slack-notifications'
  group_by: ['alertname', 'namespace']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h

receivers:
- name: 'slack-notifications'
  slack_configs:
  - channel: '#alerts'
    send_resolved: true
    text: "<!channel> {{ .CommonAnnotations.summary }}: {{ .CommonAnnotations.description }}"
```

**توضیحات:**
- `قسمت group_by`: هشدارها را بر اساس برچسب‌هایی مثل `alertname` و `namespace` گروه‌بندی می‌کند.
- `قسمت group_wait`: مدت زمانی که منتظر می‌ماند تا هشدارهای مرتبط جمع شوند.
- `قسمت group_interval`: فاصله بین ارسال گروه‌های جدید هشدار.
- `قسمت repeat_interval`: فاصله زمانی برای تکرار هشدار.
- `قسمت slack_configs`: تنظیمات مربوط به ارسال اعلان به Slack.

---

## 6. تعریف قوانین هشدار (Prometheus Rules)

قوانین هشدار در پرومتئوس از طریق **PrometheusRule CRD** تعریف می‌شوند. این قوانین شامل شرایطی هستند که وقتی برقرار شوند، هشدار تولید می‌شود.

### 6.1 ساختار یک PrometheusRule
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: trivy-alerts
  namespace: monitoring
  labels:
    prometheus: example
spec:
  groups:
  - name: trivy
    rules:
    - alert: TrivyNewCriticalVulnerability
      expr: trivy_vulnerability_critical_count{namespace="test"} > 0
      for: 30s
      labels:
        severity: critical
      annotations:
        summary: "New critical vulnerability detected"
        description: "A critical vulnerability was found in {{ $labels.namespace }} namespace."
```

**توضیحات:**
- `قسمت expr`: عبارت PromQL که شرط هشدار را تعریف می‌کند.
- `قسمت for`: مدت زمانی که شرط باید برقرار باشد تا هشدار به حالت Firing برود.
- `قسمت labels`: برچسب‌هایی که به هشدار اضافه می‌شوند (مثل `severity`).
- `قسمت annotations`: اطلاعات اضافی مثل توضیحات یا لینک به Runbook.

### 6.2 مفهوم Matchers در Alertmanager
باید در نظر گرفت که ** Matchers** در Alertmanager برای فیلتر کردن و هدایت هشدارها استفاده می‌شوند.
سه نوع Matcher داریم:
- **مدل match**: تطبیق دقیق با یک مقدار (مثلاً `severity=critical`).
- **مدل match_re**: تطبیق با استفاده از Regular Expression (مثلاً `severity=~critical|warning`).
- **مدل matchers**: ترکیبی از match و match_re برای نسخه‌های جدیدتر Alertmanager.

#### مثال استفاده از Matchers:
```yaml
route:
  receiver: 'slack-critical'
  match:
    severity: critical
  match_re:
    namespace: test.*
```

**توضیحات:**
- `سازو کار match`: هشدارهایی که دقیقاً `severity=critical` دارند به این مسیر هدایت می‌شوند.
- `سازو کار match_re`: هشدارهایی که نام فضای کاری (namespace) آن‌ها با `test` شروع می‌شود.

---

## 7. حالات Pending و Firing

- **مرحله Pending**: وقتی شرط یک هشدار برقرار می‌شود، ابتدا به حالت Pending می‌رود. در این حالت، پرومتئوس منتظر می‌ماند تا شرط به مدت زمان مشخصی (تعریف‌شده در `for`) برقرار بماند.
- **مرحله Firing**: اگر شرط برای مدت زمان مشخص برقرار بماند، هشدار به حالت Firing می‌رود و به Alertmanager ارسال می‌شود.

**چرا این دو حالت؟**
این مکانیزم از ارسال هشدارهای لحظه‌ای و ناپایدار (مثلاً به دلیل نوسانات موقتی) جلوگیری می‌کند.
برای مثال، اگر CPU Usage برای چند ثانیه به 80% برسد، ممکن است نخواهید هشداری دریافت کنید، اما اگر این وضعیت 30 ثانیه ادامه پیدا کند، هشدار فعال می‌شود.

---

## 8. مثال عملی: تنظیم هشدار برای آسیب‌پذیری‌ها

فرض کنید از **Trivy Operator** برای اسکن آسیب‌پذیری‌های امنیتی در خوشه Kubernetes استفاده می‌کنید. 
می‌خواهید اگر یک آسیب‌پذیری بحرانی (Critical Vulnerability) در فضای کاری `test` شناسایی شد، هشداری دریافت کنید.

### 8.1 نصب Trivy Operator
```bash
helm repo add aqua https://aquasecurity.github.io/helm-charts/
helm repo update
helm upgrade --install trivy-operator aqua/trivy-operator \
  --namespace trivy-system --create-namespace \
  --set trivy.ignoreUnfixed=true \
  --set serviceMonitor.enabled=true
```

### 8.2 تعریف PrometheusRule برای Trivy
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: trivy-alerts
  namespace: monitoring
  labels:
    prometheus: example
spec:
  groups:
  - name: trivy
    rules:
    - alert: TrivyNewCriticalVulnerability
      expr: trivy_vulnerability_critical_count{namespace="test"} > 0
      for: 30s
      labels:
        severity: critical
      annotations:
        summary: "New critical vulnerability detected in test namespace"
        description: "A critical vulnerability was found in {{ $labels.namespace }} namespace. Check the Trivy vulnerability report for details."
        runbook_url: "https://example.com/runbook/trivy-critical"
```

### 8.3 تنظیم Alertmanager برای ارسال به Slack
```yaml
global:
  slack_api_url: 'https://hooks.slack.com/services/xxx/yyy/zzz'

route:
  receiver: 'slack-notifications'
  group_by: ['alertname', 'namespace']
  match:
    severity: critical

receivers:
- name: 'slack-notifications'
  slack_configs:
  - channel: '#alerts'
    send_resolved: true
    text: "<!channel> {{ .CommonAnnotations.summary }}: {{ .CommonAnnotations.description }}"
```

### 8.4 اعمال تنظیمات
1. فایل PrometheusRule را اعمال کنید:
```bash
kubectl apply -f trivy-alerts.yaml -n monitoring
```
2. فایل تنظیمات Alertmanager را به‌روزرسانی کنید:
```bash
kubectl edit configmap alertmanager-prometheus-alertmanager -n monitoring
```

---

## 9. بررسی پنل Alertmanager

برای دسترسی به Alertmanager، می‌توانید سرویس آن را Port Forward کنید:
```bash
kubectl port-forward svc/prom-prometheus-stack-alertmanager 9093:9093 -n monitoring
```

سپس در مرورگر به آدرس `http://localhost:9093` بروید. در پنل Alertmanager:
- **قسمت Alerts**: لیستی از هشدارهای فعال (Pending یا Firing) را نشان می‌دهد.
- **قسمت Silences**: می‌توانید هشدارها را برای مدت زمان مشخصی غیرفعال کنید.
- **قسمت Status**: وضعیت Alertmanager و تنظیمات آن را نمایش می‌دهد.

### مثال عملی در پنل:
فرض کنید هشدار `TrivyNewCriticalVulnerability` فعال شده است:
1. در بخش Alerts، هشدار را با برچسب `severity=critical` می‌بینید.
2. می‌توانید روی آن کلیک کنید و جزئیات (مانند Annotations و Runbook URL) را مشاهده کنید.
3. اگر بخواهید هشدار را موقتاً غیرفعال کنید، از بخش Silences استفاده کنید.

---

## 10. نکات پیشرفته و بهترین روش‌ها

- **گروه‌بندی هشدارها**: از `group_by` برای کاهش تعداد اعلان‌ها استفاده کنید.
-  مثلاً هشدارهای یک Namespace را در یک اعلان ترکیب کنید.
- **ایجاد Runbook**: برای هر هشدار، یک Runbook با دستورالعمل‌های دقیق برای رفع مشکل ایجاد کنید.
- **تست هشدارها**: قبل از استفاده در محیط Production، هشدارها را در محیط تست بررسی کنید.
- **مانیتورینگ Alertmanager**: از متریک‌های خود Alertmanager (مثل `alertmanager_alerts`) برای نظارت بر سلامت آن استفاده کنید.

---

## 11. جمع‌بندی

هشدارها در پرومتئوس و Alertmanager ابزارهای قدرتمندی برای نظارت و واکنش به مشکلات سیستم هستند. 
با تعریف قوانین دقیق، تنظیم Alertmanager برای ارسال اعلان‌ها به مقصدهای مناسب، و استفاده از بهترین روش‌ها، می‌توانید یک سیستم نظارتی قوی و کارآمد ایجاد کنید.
در این آموزش، از مفاهیم پایه تا پیاده‌سازی عملی و کار با پنل Alertmanager را پوشش دادیم. حالا شما آماده‌اید تا هشدارهای خود را در محیط واقعی پیاده‌سازی کنید!
