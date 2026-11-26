-- 수업용 영상 공유: 테이블 + RLS(누구나 읽기/쓰기) + 실시간 + 스토리지 버킷

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id text not null,
  nickname text not null,
  title text not null,
  tools text,
  prompt text,
  how_made text,
  video_path text not null,
  video_url text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_id text not null,
  nickname text not null,
  body text not null,
  created_at timestamptz not null default now()
);

create index if not exists comments_post_id_idx on public.comments(post_id);

alter table public.posts enable row level security;
alter table public.comments enable row level security;

drop policy if exists "posts read" on public.posts;
drop policy if exists "posts insert" on public.posts;
drop policy if exists "posts delete" on public.posts;
create policy "posts read" on public.posts for select to anon, authenticated using (true);
create policy "posts insert" on public.posts for insert to anon, authenticated with check (true);
create policy "posts delete" on public.posts for delete to anon, authenticated using (true);

drop policy if exists "comments read" on public.comments;
drop policy if exists "comments insert" on public.comments;
drop policy if exists "comments delete" on public.comments;
create policy "comments read" on public.comments for select to anon, authenticated using (true);
create policy "comments insert" on public.comments for insert to anon, authenticated with check (true);
create policy "comments delete" on public.comments for delete to anon, authenticated using (true);

grant select, insert, delete on public.posts, public.comments to anon, authenticated;

-- 실시간
alter table public.posts replica identity full;
alter table public.comments replica identity full;
do $$ begin
  begin alter publication supabase_realtime add table public.posts; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.comments; exception when duplicate_object then null; end;
end $$;

-- 스토리지: 공개 버킷, 파일당 50MB, 영상만
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('videos', 'videos', true, 52428800, array['video/mp4','video/quicktime','video/webm','video/x-m4v'])
on conflict (id) do update set public = true, file_size_limit = 52428800,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "videos upload" on storage.objects;
drop policy if exists "videos read" on storage.objects;
drop policy if exists "videos delete" on storage.objects;
create policy "videos upload" on storage.objects for insert to anon, authenticated with check (bucket_id = 'videos');
create policy "videos read" on storage.objects for select to anon, authenticated using (bucket_id = 'videos');
create policy "videos delete" on storage.objects for delete to anon, authenticated using (bucket_id = 'videos');
