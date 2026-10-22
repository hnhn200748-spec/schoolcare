# SchoolCare — ระบบแจ้งซ่อมเชื่อมฐานข้อมูลกลาง

ชุดนี้ปรับจากไฟล์ต้นฉบับให้ทุกหน้าทำงานกับฐานข้อมูล PostgreSQL กลางบน Supabase แทน localStorage สำหรับข้อมูลคำขอ

## ฟังก์ชันในชุดนี้
- แจ้งซ่อมและบันทึกลงฐานข้อมูลกลาง
- สร้างเลขคำขอและติดตามด้วยเลขคำขอ + เบอร์ติดต่อ
- ประวัติคำขอที่ผู้ใช้เคยส่งจากเบราว์เซอร์นี้ (เบราว์เซอร์เก็บเฉพาะเลขคำขอและเบอร์เพื่อค้นหาซ้ำ)
- เข้าสู่ระบบเจ้าหน้าที่ผ่าน Supabase Auth
- แดชบอร์ดเจ้าหน้าที่ดูคำขอทั้งหมด เปลี่ยนสถานะ และเปิดรายละเอียด
- สถิติหน้าแรกจากฐานข้อมูลกลาง
- ส่งออก CSV ของประวัติที่เรียกดูได้
- RLS ป้องกันไม่ให้ผู้ใช้ทั่วไปอ่านคำขอทั้งหมด

## ขั้นตอนเปิดใช้งานจริง

### 1. สร้างโปรเจกต์ Supabase
สร้างโปรเจกต์ที่ https://supabase.com/ แล้วเปิด SQL Editor

### 2. สร้างตารางและสิทธิ์
คัดลอกไฟล์ `supabase-schema.sql` ทั้งหมดไปรันใน SQL Editor ให้สำเร็จ ตรวจสอบว่าไม่มี error

### 3. ตั้งค่าเชื่อมต่อ
เปิด Project Settings → API แล้วคัดลอก Project URL และ anon/publishable key (ห้ามใช้ service_role/secret key)
แก้ `supabase-config.js`:
```js
window.SCHOOLCARE_SUPABASE_URL = "https://YOUR_PROJECT.supabase.co";
window.SCHOOLCARE_SUPABASE_ANON_KEY = "YOUR_ANON_OR_PUBLISHABLE_KEY";
```

### 4. สร้างบัญชีเจ้าหน้าที่
ใน Supabase Dashboard → Authentication → Users ให้สร้างผู้ใช้ด้วยอีเมลและรหัสผ่านที่ต้องการ จากนั้นรัน SQL โดยแทน UUID ด้วย User UID ที่เห็นในหน้า Users:
```sql
insert into public.profiles (id, display_name, role)
values ('ใส่-USER-UUID-ตรงนี้', 'เจ้าหน้าที่ซ่อมบำรุง', 'staff')
on conflict (id) do update set role='staff', display_name=excluded.display_name;
```
หน้า `login.html` ใช้อีเมลในช่องชื่อผู้ใช้และรหัสผ่านของ Supabase Auth ไม่ใช้บัญชีทดลอง hard-coded อีกต่อไป

### 5. อัปโหลดไป GitHub Pages
อัปโหลดไฟล์ทั้งหมดในโฟลเดอร์นี้ไปยังตำแหน่งเดียวกับ `index.html` ใน repository โดยคงชื่อและโครงสร้างไฟล์เดิม แล้ว Commit changes

### 6. ทดสอบก่อนใช้งานจริง
1. เปิด `report.html` ส่งคำขอทดสอบพร้อมเบอร์โทร
2. จดเลขคำขอ
3. เปิด `track.html` กรอกเลขคำขอและเบอร์เดิม ต้องเห็นสถานะ
4. เข้าสู่ระบบด้วยบัญชีเจ้าหน้าที่ แล้วเปลี่ยนสถานะ
5. กลับไปติดตามสถานะจากอีกอุปกรณ์ ต้องเห็นสถานะล่าสุดจากฐานข้อมูลเดียวกัน
6. ทดสอบบนมือถือและคอมพิวเตอร์ และเปิด realtime publication ตามคำแนะนำด้านล่างหากต้องการอัปเดตแดชบอร์ดทันที

## ความปลอดภัยและข้อจำกัด
- อย่าใส่ `service_role` key ใน `supabase-config.js` หรือ GitHub
- ผู้ใช้ทั่วไปส่งคำขอได้ แต่ดูข้อมูลได้เฉพาะคำขอที่ตรงทั้งเลขคำขอและเบอร์โทรผ่าน RPC
- รายการทั้งหมดและการแก้สถานะต้องผ่านบัญชีเจ้าหน้าที่ที่มี `profiles.role='staff'`
- ประวัติหน้าสาธารณะจำรายการที่ผู้ใช้เคยส่งไว้ใน localStorage ของเบราว์เซอร์เฉพาะเพื่อความสะดวก หากใช้เครื่องอื่นยังติดตามได้ด้วยเลขคำขอและเบอร์โทร
- โปรเจกต์ Supabase ต้องถูกสร้างและตั้งค่าโดยเจ้าของเว็บไซต์ก่อน ชุดไฟล์นี้ไม่สามารถเชื่อมฐานข้อมูลที่ยังไม่มี URL/key ได้โดยอัตโนมัติ
- ก่อนใช้ในโรงเรียนจริง ควรเพิ่ม CAPTCHA/rate limiting สำหรับการส่งคำขอสาธารณะ, นโยบายเก็บข้อมูลส่วนบุคคล, สำรองฐานข้อมูล, และตรวจทาน RLS โดยผู้ดูแลระบบ

## Realtime (ตัวเลือก)
ใน Supabase Dashboard ไป Database → Publications → `supabase_realtime` แล้วเปิด `repair_requests` หากยังไม่เปิด เพื่อให้หน้าแดชบอร์ดรีเฟรชเมื่อมีการเปลี่ยนแปลงข้อมูล


## หากเว็บขึ้น `Could not find the 'category' column ... in the schema cache`
แปลว่าตาราง `repair_requests` เดิมใน Supabase ใช้ชื่อคอลัมน์คนละชุดกับเว็บเวอร์ชันนี้ อย่าเพิ่งลบตารางหรือสร้างโปรเจกต์ใหม่ เพราะอาจทำให้คำขอเก่าหาย

1. เปิด Supabase → SQL Editor → New query
2. เปิดไฟล์ `supabase-migrate-existing-table.sql` ในชุดนี้ แล้วคัดลอกทั้งหมดไปวาง
3. กด **Run** ให้สำเร็จ
4. รอสักครู่ แล้วรีโหลดหน้าเว็บ SchoolCare ใหม่ หากยังมี error ให้เปิด Settings/Database หรือ SQL Editor แล้วรัน `NOTIFY pgrst, 'reload schema';`
5. ตรวจสอบว่าคอลัมน์ `request_number`, `reporter`, `phone`, `category`, `location`, `subject`, `details`, `priority`, `status`, `created_at`, `updated_at` มีอยู่ใน `public.repair_requests`

สคริปต์นี้เปลี่ยนชื่อคอลัมน์เดิมที่ตรงกันและเพิ่มคอลัมน์ที่ขาด โดยไม่ลบแถวคำขอเดิม


## แก้ปัญหา `lookup_repair_request ... schema cache`

หากหน้า `track.html` ขึ้นข้อความว่าไม่พบฟังก์ชัน `public.lookup_repair_request`:

1. เปิด Supabase Dashboard ของโปรเจกต์ที่เว็บไซต์เชื่อมต่ออยู่
2. ไปที่ **SQL Editor** แล้วเลือก **New query**
3. เปิดไฟล์ `fix-tracking-lookup.sql` ในชุดนี้ คัดลอกทั้งหมดไปวาง แล้วกด **Run**
4. รอสักครู่ แล้วรีเฟรชหน้า `track.html` และลองค้นหาอีกครั้ง

สคริปต์นี้สร้าง/อัปเดตเฉพาะฟังก์ชันค้นหาและโหลด schema cache ใหม่ ไม่ลบคำขอแจ้งซ่อมเดิม หากยังพบ error ให้ตรวจสอบว่า `repair_requests` มีคอลัมน์ `request_number`, `reporter`, `phone`, `category`, `location`, `subject`, `details`, `priority`, `status`, `created_at` และ `updated_at` และเว็บไซต์กำลังเชื่อมกับ Supabase โปรเจกต์เดียวกับที่รัน SQL
