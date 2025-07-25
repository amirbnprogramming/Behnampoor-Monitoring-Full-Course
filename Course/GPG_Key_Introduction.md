## کلید GPG چیست؟

کلید GPG شامل دو بخش است:
1. **کلید عمومی (Public Key):** این کلید برای رمزنگاری داده‌ها یا تأیید امضای دیجیتال استفاده می‌شود و می‌توانید آن را با دیگران به اشتراک بگذارید.
2. **کلید خصوصی (Private Key):** این کلید برای رمزگشایی داده‌های رمزنگاری‌شده یا ایجاد امضای دیجیتال استفاده می‌شود و باید کاملاً محرمانه بماند.

این دو کلید به‌صورت جفت تولید می‌شوند و از الگوریتم‌های رمزنگاری نامتقارن (مانند RSA یا DSA) استفاده می‌کنند. ایده اصلی این است که چیزی که با کلید عمومی رمزنگاری شود، فقط با کلید خصوصی مربوطه قابل رمزگشایی است و بالعکس.

### چرا از کلید GPG استفاده می‌کنیم؟
- **امنیت داده‌ها:** برای رمزنگاری ایمیل‌ها، فایل‌ها یا پیام‌ها تا فقط گیرنده موردنظر بتواند آن‌ها را بخواند.
- **تأیید هویت:** برای امضای دیجیتال داده‌ها، که ثابت می‌کند داده از شما آمده و دستکاری نشده است.
- **اعتماد در ارتباطات:** در پروژه‌های متن‌باز (مثل بسته‌های نرم‌افزاری)، کلید GPG برای تأیید صحت و اصالت استفاده می‌شود.
- **حفظ حریم خصوصی:** جلوگیری از دسترسی غیرمجاز به اطلاعات حساس.

## نحوه کار کلید GPG

1. **تولید جفت کلید:**
   - با استفاده از ابزار GPG، یک جفت کلید (عمومی و خصوصی) تولید می‌کنید.
   - کلید عمومی را به دیگران می‌دهید (مثلاً در سرورهای کلید عمومی مثل `keys.openpgp.org`).
   - کلید خصوصی را در سیستم خود (یا یک مکان امن) نگه می‌دارید.

2. **رمزنگاری:**
   - فرستنده با کلید عمومی گیرنده، داده را رمزنگاری می‌کند.
   - گیرنده با کلید خصوصی خود داده را رمزگشایی می‌کند.

3. **امضای دیجیتال:**
   - فرستنده با کلید خصوصی خود داده را امضا می‌کند.
   - گیرنده با کلید عمومی فرستنده، صحت امضا را تأیید می‌کند.

## مثال‌های کاربردی

### مثال ۱: رمزنگاری و رمزگشایی فایل
فرض کنید می‌خواهید یک فایل حساس (`secret.txt`) را برای دوستتان (با ایمیل `friend@example.com`) بفرستید.

1. **تولید کلید GPG (اگر ندارید):**
   ```bash
   gpg --gen-key
   ```
   - اطلاعات خواسته‌شده (نام، ایمیل، نوع کلید) را وارد کنید.
   - این دستور یک جفت کلید تولید می‌کند.

2. **دریافت کلید عمومی دوستتان:**
   فرض کنید دوستتان کلید عمومی‌اش را به شما داده یا از سرور کلید گرفته‌اید:
   ```bash
   gpg --import friend_public_key.asc
   ```

3. **رمزنگاری فایل:**
   ```bash
   gpg --encrypt --recipient friend@example.com secret.txt
   ```
   - خروجی: فایلی به نام `secret.txt.gpg` که فقط دوستتان می‌تواند رمزگشایی کند.

4. **رمزگشایی (توسط گیرنده):**
   دوستتان با کلید خصوصی خود فایل را رمزگشایی می‌کند:
   ```bash
   gpg --decrypt secret.txt.gpg > secret_decrypted.txt
   ```

### مثال ۲: امضای دیجیتال برای تأیید اصالت
فرض کنید یک بسته نرم‌افزاری (`app.tar.gz`) منتشر کرده‌اید و می‌خواهید کاربران مطمئن شوند که این بسته از شماست.

1. **امضای فایل:**
   ```bash
   gpg --sign app.tar.gz
   ```
   - خروجی: فایلی به نام `app.tar.gz.gpg` که شامل امضای دیجیتال شماست.

2. **تأیید امضا توسط کاربر:**
   کاربر ابتدا کلید عمومی شما را وارد می‌کند:
   ```bash
   gpg --import your_public_key.asc
   ```
   سپس امضا را تأیید می‌کند:
   ```bash
   gpg --verify app.tar.gz.gpg
   ```
   - اگر خروجی حاوی عبارت `Good signature` باشد، فایل معتبر است.

### مثال ۳: امضای Git Commit
در پروژه‌های متن‌باز، می‌توانید کامیت‌های Git را با GPG امضا کنید تا اصالت آن‌ها تأیید شود.

1. **تنظیم کلید GPG در Git:**
   ```bash
   git config --global user.signingkey <GPG_KEY_ID>
   git config --global commit.gpgsign true
   ```
   - `<GPG_KEY_ID>` را با شناسه کلید خود جایگزین کنید (با `gpg --list-keys` پیدا کنید).

2. **امضای کامیت:**
   ```bash
   git commit -m "پیام کامیت"
   ```
   - این کامیت به‌صورت خودکار با کلید GPG شما امضا می‌شود.

3. **تأیید در GitHub:**
   در GitHub، کامیت‌های امضا‌شده با علامت «Verified» نمایش داده می‌شوند (به شرطی که کلید عمومی در پروفایل GitHub آپلود شده باشد).

## نکات کاربردی

1. **مدیریت کلیدها:**
   - کلید خصوصی را در مکانی امن (مثل دیسک رمزنگاری‌شده یا دستگاه سخت‌افزاری) ذخیره کنید.
   - از کلیدهای خود نسخه پشتیبان تهیه کنید:
     ```bash
     gpg --export --armor <your_email> > my_public_key.asc
     gpg --export-secret-keys --armor <your_email> > my_private_key.asc
     ```

2. **انتشار کلید عمومی:**
   - کلید عمومی را در سرورهای کلید (مثل `keys.openpgp.org`) آپلود کنید:
     ```bash
     gpg --keyserver keys.openpgp.org --send-keys <GPG_KEY_ID>
     ```

3. **امنیت کلید خصوصی:**
   - هرگز کلید خصوصی را به اشتراک نگذارید.
   - از رمز عبور قوی برای کلید خصوصی استفاده کنید.

4. **به‌روزرسانی و تمدید کلید:**
   - کلیدهای GPG می‌توانند تاریخ انقضا داشته باشند. برای تمدید:
     ```bash
     gpg --edit-key <GPG_KEY_ID>
     gpg> expire
     ```

5. **کاربرد در پرومتئوس (رابطه با آموزش):**
   اگر بسته‌های پرومتئوس یا ابزارهای مرتبط (مثل گرافانا) را از مخازن متن‌باز دانلود می‌کنید، ممکن است با امضاهای GPG مواجه شوید. برای تأیید بسته:
   ```bash
   gpg --verify prometheus-2.45.0.tar.gz.sig prometheus-2.45.0.tar.gz
   ```
   این کار تضمین می‌کند که بسته از منبع معتبر است و دستکاری نشده.

## مثال جامع: استفاده در پروژه متن‌باز
فرض کنید شما توسعه‌دهنده یک پروژه متن‌باز هستید و می‌خواهید بسته نرم‌افزاری خود را منتشر کنید:
1. بسته را امضا کنید:
   ```bash
   gpg --detach-sign -a prometheus-2.45.0.tar.gz
   ```
   - این دستور یک فایل امضا (`prometheus-2.45.0.tar.gz.asc`) تولید می‌کند.
2. کلید عمومی خود را منتشر کنید:
   ```bash
   gpg --keyserver keys.openpgp.org --send-keys <your_key_id>
   ```
3. کاربران می‌توانند بسته را تأیید کنند:
   ```bash
   gpg --verify prometheus-2.45.0.tar.gz.asc prometheus-2.45.0.tar.gz
   ```

## جمع‌بندی
کلید GPG ابزاری قدرتمند برای رمزنگاری، امضای دیجیتال و تأیید اصالت داده‌ها است. با استفاده از جفت کلید عمومی و خصوصی، می‌توانید امنیت ارتباطات و داده‌های خود را تضمین کنید. کاربردهای آن از رمزنگاری ایمیل و فایل گرفته تا امضای بسته‌های نرم‌افزاری و کامیت‌های Git گسترده است. با رعایت نکات امنیتی و استفاده از مثال‌های بالا، می‌توانید به‌راحتی از GPG در پروژه‌های خود استفاده کنید.

برای یادگیری بیشتر، مستندات GPG در [gnupg.org](https://gnupg.org) را مطالعه کنید یا سوالات خود را در بخش نظرات مطرح کنید!
