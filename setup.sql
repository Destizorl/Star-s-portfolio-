-- Star Jennie portfolio CMS: run this entire script in Supabase SQL Editor.
-- Public visitors can read published content and media. Only allowlisted Auth users can edit or upload.

create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admin_users enable row level security;
grant select on public.admin_users to authenticated;
drop policy if exists "Admins can read their own allowlist record" on public.admin_users;
create policy "Admins can read their own allowlist record"
  on public.admin_users for select to authenticated
  using (user_id = (select auth.uid()));

create or replace function private.is_site_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_users
    where user_id = (select auth.uid())
  );
$$;
revoke all on function private.is_site_admin() from public, anon;
grant execute on function private.is_site_admin() to authenticated;

create table if not exists public.site_content (
  id smallint primary key check (id = 1),
  content jsonb not null,
  updated_at timestamptz not null default now()
);
alter table public.site_content enable row level security;
grant select on public.site_content to anon, authenticated;
grant update on public.site_content to authenticated;
drop policy if exists "Published site content is readable by everyone" on public.site_content;
create policy "Published site content is readable by everyone"
  on public.site_content for select to anon, authenticated using (true);
drop policy if exists "Allowlisted administrators can update site content" on public.site_content;
create policy "Allowlisted administrators can update site content"
  on public.site_content for update to authenticated
  using ((select private.is_site_admin()))
  with check ((select private.is_site_admin()));

insert into public.site_content (id, content)
values (1, '{"heroTitle":"Little Miss\nGraduate.","heroLead":"A curious mind with a passion for engineering, creativity, good food and building meaningful digital communities. I bring ideas to life through skill, service and imagination.","about":["I''m Star Jennie — an electrical engineer with a creative side and a people-first approach. My interests and professional skills span engineering, food services, online community management and visual design.","Whether I''m solving a technical challenge, creating a memorable food experience or helping a digital community thrive, I enjoy bringing care, precision and fresh ideas to everything I do."],"services":[{"icon":"ϟ","title":"Electrical Engineering","description":"Technical thinking, practical problem-solving and an engineering mindset focused on safe, thoughtful solutions."},{"icon":"♨","title":"Catering","description":"Food preparation and catering with attention to flavour, presentation and a welcoming experience."},{"icon":"◎","title":"Web Community Management","description":"Supporting online communities through communication, engagement and organized digital interaction."},{"icon":"✳","title":"Graphic Design","description":"Creative visual communication, thoughtful layouts and graphics that help ideas stand out."}],"works":[],"heroImage":"","heroImagePosition":"center bottom","heroImageScale":1,"heroImageFit":"contain","theme":{"navy":"#07152d","blue":"#102b55","lime":"#b7f500","green":"#5fae00","gray":"#35445b","background":"#ffffff","footer":"#07152d"}}'::jsonb)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('site-media', 'site-media', true, 8388608, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = excluded.public, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public can view published site media" on storage.objects;
create policy "Public can view published site media"
  on storage.objects for select to anon, authenticated
  using (bucket_id = 'site-media');
drop policy if exists "Allowlisted administrators can upload site media" on storage.objects;
create policy "Allowlisted administrators can upload site media"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'site-media' and (select private.is_site_admin()));
drop policy if exists "Allowlisted administrators can update site media" on storage.objects;
create policy "Allowlisted administrators can update site media"
  on storage.objects for update to authenticated
  using (bucket_id = 'site-media' and (select private.is_site_admin()))
  with check (bucket_id = 'site-media' and (select private.is_site_admin()));
drop policy if exists "Allowlisted administrators can delete site media" on storage.objects;
create policy "Allowlisted administrators can delete site media"
  on storage.objects for delete to authenticated
  using (bucket_id = 'site-media' and (select private.is_site_admin()));

-- Next: create the admin user in Supabase Dashboard > Authentication > Users.
-- Then copy that user's UUID and run:
-- insert into public.admin_users (user_id) values ('PASTE-AUTH-USER-UUID-HERE');
