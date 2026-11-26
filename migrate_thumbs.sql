-- 썸네일 이미지: 목록에는 작은 jpg만 보여 주고 영상은 열어 볼 때만 받기
alter table public.posts add column if not exists thumb_url text;
update storage.buckets
   set allowed_mime_types = array['video/mp4','video/quicktime','video/webm','video/x-m4v','image/jpeg']
 where id = 'videos';
notify pgrst, 'reload schema';
