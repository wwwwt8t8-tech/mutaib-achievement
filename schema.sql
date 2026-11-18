-- نفّذ هذا الملف مرة واحدة في Supabase SQL Editor
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null check (char_length(full_name) between 2 and 150),
 role text not null default 'teacher' check (role in ('admin','teacher')),
 created_at timestamptz not null default now()
);
create table if not exists public.analyses (
 id uuid primary key default gen_random_uuid(),
 teacher_id uuid not null references public.profiles(id),
 subject text not null, stage text not null check (stage in ('متوسطة','ثانوية')),
 grade text not null, section text not null, term text not null,
 analysis_date date not null, average numeric(5,2) not null check (average between 0 and 100),
 excellent integer not null check (excellent >= 0), very_good integer not null check (very_good >= 0),
 good integer not null check (good >= 0), pass integer not null check (pass >= 0),
 weak integer not null check (weak >= 0),
 post_average numeric(5,2) check (post_average between 0 and 100),
 notes text, created_at timestamptz not null default now(),
 constraint positive_total check (excellent+very_good+good+pass+weak>0)
);
create table if not exists public.plans (
 id uuid primary key default gen_random_uuid(),
 teacher_id uuid not null references public.profiles(id),
 kind text not null check (kind in ('علاجية','إثرائية','إجرائية')),
 title text not null, subject text not null,
 stage text not null check (stage in ('متوسطة','ثانوية')),
 start_date date not null, end_date date not null check (end_date>=start_date),
 status text not null check (status in ('قيد التخطيط','قيد التنفيذ','مكتملة')),
 actions text not null, impact text, created_at timestamptz not null default now()
);
create or replace function public.is_school_admin() returns boolean
language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.profiles where id=(select auth.uid()) and role='admin');
$$;
revoke all on function public.is_school_admin() from public;
grant execute on function public.is_school_admin() to authenticated;
alter table public.profiles enable row level security;
alter table public.analyses enable row level security;
alter table public.plans enable row level security;
create policy "profiles_read" on public.profiles for select to authenticated using (id=(select auth.uid()) or (select public.is_school_admin()));
create policy "analyses_read" on public.analyses for select to authenticated using (teacher_id=(select auth.uid()) or (select public.is_school_admin()));
create policy "analyses_insert" on public.analyses for insert to authenticated with check (teacher_id=(select auth.uid()));
create policy "analyses_update" on public.analyses for update to authenticated using (teacher_id=(select auth.uid())) with check (teacher_id=(select auth.uid()));
create policy "plans_read" on public.plans for select to authenticated using (teacher_id=(select auth.uid()) or (select public.is_school_admin()));
create policy "plans_insert" on public.plans for insert to authenticated with check (teacher_id=(select auth.uid()));
create policy "plans_update" on public.plans for update to authenticated using (teacher_id=(select auth.uid())) with check (teacher_id=(select auth.uid()));
-- إنشاء المستخدمين: من Supabase Authentication > Users، ثم أضف السجلات يدويًا
-- مثال بعد إنشاء المستخدم في Authentication (استبدل UUID بالقيمة الصحيحة):
-- insert into public.profiles(id,full_name,role) values ('UUID-هنا','مدير المجمع','admin');
-- insert into public.profiles(id,full_name,role) values ('UUID-هنا','اسم المعلم','teacher');
-- لا تفعّل التسجيل العام من الواجهة؛ الحسابات ينشئها مسؤول النظام فقط.
