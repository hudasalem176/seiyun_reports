# متطلبات الخادم (Laravel) — أمان، صلاحيات، قاعدة بيانات

> كود الخادم `medicalhouse-ye.net/api` **غير موجود في هذا المستودع**، لذلك لم يتم فحصه ولا تعديله.
> كل ما يلي مطلوب تنفيذه على الخادم؛ حماية تطبيق Flutter وحدها **لا تكفي** لأن أي شخص
> يستطيع إرسال طلبات API مباشرة متجاوزاً التطبيق.

## 1. المصادقة (Critical)
```php
// Middleware: verify Firebase ID token on /login (kreait/laravel-firebase)
$verified = Firebase::auth()->verifyIdToken($request->bearerToken(), checkIfRevoked: true);
$claims   = $verified->claims();
abort_unless($claims->get('email_verified') === true
    || ($claims->get('firebase')['sign_in_provider'] ?? null) === 'google.com', 403);
$user = User::firstOrCreate(['firebase_uid' => $claims->get('sub')],
                            ['email' => $claims->get('email'), 'role' => 'citizen']);
// لا تقرأ email ولا role من جسم الطلب أبداً.
```
- رموز Sanctum بصلاحية محددة: `'expiration' => 60 * 24 * 7` في `config/sanctum.php`.
- `POST /logout` → `$request->user()->currentAccessToken()->delete();`
- `Route::post('/login')->middleware('throttle:10,1');`

## 2. الأدوار والصلاحيات (Critical)
| الدور | القيمة | الصلاحيات |
|---|---|---|
| مواطن | `citizen` (`citizens` حالياً) | إنشاء بلاغ، رؤية بلاغاته، رؤية البلاغات العامة المسموح بها، طلب خدمة، تعديل ملفه فقط |
| مشرف ميداني | `supervisor` (`supervisors` حالياً) | المهام المسندة إليه فقط، تحديث حالتها مع صورة الإنجاز |
| مسؤول | `admin` | إدارة البلاغات والحالات والرفض، إدارة طلبات الخدمات والأسعار |
| مدير أعلى | `super_admin` | إدارة حسابات الموظفين والأدوار، سجل العمليات |

```php
// Policies — لكل نموذج
class ReportPolicy {
  public function view(User $u, Report $r)   { return $r->is_public || $r->citizen_id === $u->id || $u->isStaff(); }
  public function update(User $u, Report $r) { return $u->isAdmin(); }           // المواطن لا يعدّل الحالة
  public function delete(User $u, Report $r) { return $u->isAdmin(); }
}
class AssignmentPolicy {
  public function update(User $u, Assignment $a) { return $a->supervisor_id === $u->id; } // منع IDOR
}
```
- **IDOR:** كل مسار يحتوي `{id}` (`reports/{id}/comments`, `assignments/{id}/update`, `service-requests/{id}`)
  يجب أن يمر عبر `$this->authorize(...)`. لا تثق بـ `citizen_id` أو `user_id` في جسم الطلب، خذه من `auth()->id()`.
- **تغيير الدور:** حقل `role` غير قابل للتعبئة (`$guarded = ['role', ...]`)، ولا يُغيَّر إلا من لوحة super_admin.
- `updateInformationCitizen`: اسمح فقط بـ `name, phone, latitude, longitude, image`. **لا تسمح بتغيير `email`** (يأتي من Firebase).
- ⚠️ `increment-likes` و`decrement-likes` تستخدم **GET** — حوّلها إلى POST مع جدول `report_likes (user_id, report_id) UNIQUE` لمنع التكرار والتلاعب.

## 3. دورة حالة البلاغ
القيم: `new → under_review → in_progress → resolved → closed`، و`rejected` مع `rejection_reason` إلزامي.
التطبيق يفهم القيم العربية والإنجليزية (`lib/core/models/report_status.dart`).
```php
const TRANSITIONS = [
  'new' => ['under_review','rejected'], 'under_review' => ['in_progress','rejected'],
  'in_progress' => ['resolved'], 'resolved' => ['closed','in_progress'],
];
```
- كل تغيير حالة يُسجَّل في `report_status_history` ويرسل FCM للمواطن (`type=report_status`, `report_id`).
- رقم مرجعي فريد: `reference_number` مثل `SYN-2026-000123` (عمود UNIQUE).

## 4. رفع الملفات (High)
```php
$request->validate(['image' => 'nullable|file|mimes:jpg,jpeg,png,webp,heic|max:8192']);
$path = $request->file('image')->store('reports', 'public'); // اسم عشوائي، لا تستخدم الاسم الأصلي
```
- أعد ترميز الصورة (Intervention Image) لإزالة بيانات EXIF (الموقع الدقيق للجهاز) وأي محتوى مدمج.
- مجلد الرفع يجب ألا ينفّذ PHP.

## 5. طلبات الخدمات (جديد — مطلوب ليعمل زر "ارسال الطلب")
`POST /api/service-requests` (auth:sanctum, throttle:5,1)
```json
{ "service_id":"1", "preferred_date":"2026-12-01", "time_slot":"مساءً", "phone":"771234567",
  "notes":"", "latitude":15.94, "longitude":48.78, "payment_method":"cash_on_service",
  "client_request_id":"<hex>" }
```
الاستجابة: `201 { "data": { "id": 1, "reference_number": "SRV-2026-0001", "status": "pending" } }`
- السعر يُحسب على الخادم من جدول `services` (لا يُقبل من التطبيق).
- `client_request_id` + ترويسة `Idempotency-Key` → UNIQUE لمنع الطلب المكرر.
- حالات: `pending → confirmed → scheduled → completed` أو `cancelled`. كل تغيير يرسل FCM (`type=service_request`).
- **الدفع:** لا يوجد دفع إلكتروني. عند إضافته: payment intent على الخادم، صفحة البوابة، تأكيد عبر Webhook موقّع. لا تُخزَّن بيانات البطاقات.
- حتى تُنفَّذ هذه النقطة يعرض التطبيق "الطلب الإلكتروني غير مفعّل" ويعرض الإرسال عبر البريد — ولا يدّعي النجاح.

## 6. حذف الحساب (مطلوب لمتجر Google Play)
`DELETE /api/account` (auth:sanctum): حذف/إخفاء البيانات الشخصية (الاسم، الهاتف، البريد، الصورة، الموقع،
رمز FCM)، إلغاء كل الرموز، وإبقاء البلاغات مجهولة الهوية (`citizen_id = null`). ثم احذف مستخدم Firebase
عبر Admin SDK إن لم يحذفه التطبيق. الاستجابة `204`.
الحسابات المعطلة: عمود `disabled_at`؛ middleware يرفض الطلبات بـ `403`، ومزامنة التعطيل مع Firebase (`disabled: true`).

## 7. الإشعارات (FCM)
| الحدث | المستلم | data.type |
|---|---|---|
| تغيير حالة البلاغ / قبول / رفض | المواطن صاحب البلاغ | `report_status` |
| تحديث طلب الخدمة | صاحب الطلب | `service_request` |
| بلاغ جديد | Topic `admins` أو أجهزة الموظفين | `new_report` |
| إسناد مهمة | المشرف | `assignment` |
تفعيل الحساب يتم برسالة Firebase البريدية (ليس FCM لأن الجهاز لم يُسجَّل بعد).
لا ترسل بيانات شخصية في نص الإشعار؛ أرسل المعرّف فقط.

## 8. قاعدة البيانات
- فهارس: `reports(citizen_id, created_at)`, `reports(status)`, `reports(area_id, status)`, `reports(lat, lng)` أو عمود SPATIAL،
  `assignments(supervisor_id, status)`, `users(firebase_uid) UNIQUE`, `users(email) UNIQUE`, `service_requests(user_id, status)`.
- استخدم Eloquent/Query Builder مع bindings فقط؛ ابحث في الكود عن `DB::raw(`, `whereRaw(`, `orderByRaw(` مع مدخلات المستخدم (SQL Injection).
- لا ترجع حقولاً حساسة: `$hidden = ['password','remember_token','fcm_token','firebase_uid']`.
- `APP_DEBUG=false` في الإنتاج (وإلا تُكشف الاستعلامات ومفاتيح البيئة في رسائل الخطأ).
- نسخ احتياطي يومي مشفّر (`spatie/laravel-backup`) خارج الخادم، مع اختبار استعادة شهري.
- جدول `audit_logs (actor_id, action, subject_type, subject_id, changes JSON, ip, created_at)` لكل عمليات الإدارة.

## 9. كلمات المرور
كلمات مرور المستخدمين تُدار في Firebase Authentication (مُجزّأة بـ scrypt) ولا تصل إلى Laravel.
إن كان في لوحة الإدارة تسجيل دخول بكلمة مرور خاصة بالموظفين فاستخدم `Hash::make` (bcrypt/argon2id)
و`'driver' => 'argon2id'` في `config/hashing.php`، مع 2FA لحسابات admin/super_admin.
