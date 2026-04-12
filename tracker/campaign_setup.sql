-- ============================================================
--  Exalt Digital — Campaign Delivery Setup
--  Run this in: Supabase Dashboard → SQL Editor
-- ============================================================

-- Step 1: Enable pg_cron (if not already on)
create extension if not exists pg_cron;

-- Step 2: Create boosts table
create table if not exists boosts (
  id                 uuid        primary key default gen_random_uuid(),
  site_url           text,
  amount             integer,
  visitors_target    integer     default 0,
  visitors_delivered integer     default 0,
  created_at         timestamptz default now(),
  active             boolean     default true
);

-- Add delivery-tracking columns if upgrading from an older version
alter table boosts add column if not exists visitors_target    integer default 0;
alter table boosts add column if not exists visitors_delivered integer default 0;

-- RLS
alter table boosts enable row level security;
do $$
begin
  if not exists (select 1 from pg_policies where tablename='boosts' and policyname='anon_insert_boost') then
    execute 'create policy "anon_insert_boost" on boosts for insert to anon with check (true)';
  end if;
  if not exists (select 1 from pg_policies where tablename='boosts' and policyname='anon_select_boost') then
    execute 'create policy "anon_select_boost" on boosts for select to anon using (true)';
  end if;
end $$;

-- Step 3: Remove old job if present
do $$
begin
  perform cron.unschedule('trickle-traffic');
exception when others then null;
end $$;

-- Step 4: Delivery function — spreads visits evenly over 24 hours
create or replace function insert_campaign_visits()
returns void as $$
declare
  boost_rec   record;
  browsers    text[] := array['Chrome', 'Chrome', 'Chrome', 'Safari', 'Firefox', 'Edge'];
  devices     text[] := array['desktop', 'desktop', 'mobile', 'mobile', 'tablet'];
  os_list     text[] := array['Windows', 'Windows', 'macOS', 'iOS', 'Android'];
  referrers   text[] := array[
    'https://google.com', 'https://google.com', 'https://google.com',
    'https://facebook.com', 'https://instagram.com',
    '', '', ''
  ];
  screens     text[] := array['1920x1080', '1440x900', '390x844', '414x896', '1280x800'];
  paths       text[];
  num_visits  integer;
  chosen_path text;
  i           integer;
  mins_active integer;
  mins_left   integer;
  remaining   integer;
begin
  for boost_rec in
    select * from boosts where active = true
  loop
    -- Already finished?
    if boost_rec.visitors_delivered >= boost_rec.visitors_target then
      update boosts set active = false where id = boost_rec.id;
      continue;
    end if;

    -- Spread remaining visitors evenly across remaining minutes (max 1440 = 24 h)
    mins_active := greatest(1, extract(epoch from (now() - boost_rec.created_at)) / 60)::int;
    mins_left   := greatest(1, 1440 - mins_active);
    remaining   := boost_rec.visitors_target - boost_rec.visitors_delivered;
    num_visits  := least(remaining, greatest(1, ceil(remaining::float / mins_left)::int));

    paths := array['/', '/read.html', '/audios/index.html', '/contents.html', '/index.html'];

    for i in 1..num_visits loop
      chosen_path := paths[1 + floor(random() * array_length(paths, 1))::int];
      insert into page_views (
        url, path, title, referrer, browser, os,
        device_type, screen_size, language, session_id, site_id
      ) values (
        boost_rec.site_url || chosen_path,
        chosen_path,
        case chosen_path
          when '/'                  then 'Home'
          when '/read.html'         then 'Read'
          when '/audios/index.html' then 'Audios'
          when '/contents.html'     then 'Contents'
          else 'Page'
        end,
        referrers[1 + floor(random() * array_length(referrers, 1))::int],
        browsers[1 + floor(random() * array_length(browsers, 1))::int],
        os_list[1 + floor(random() * array_length(os_list, 1))::int],
        devices[1 + floor(random() * array_length(devices, 1))::int],
        screens[1 + floor(random() * array_length(screens, 1))::int],
        'en-AU',
        md5(random()::text || clock_timestamp()::text),
        replace(replace(boost_rec.site_url, 'https://', ''), 'http://', '')
      );
    end loop;

    -- Mark progress; deactivate if complete
    update boosts
    set
      visitors_delivered = visitors_delivered + num_visits,
      active = case
        when visitors_delivered + num_visits >= visitors_target then false
        else true
      end
    where id = boost_rec.id;
  end loop;
end;
$$ language plpgsql security definer;

-- Step 5: Schedule — runs every minute
select cron.schedule(
  'deliver-campaign',
  '* * * * *',
  'select insert_campaign_visits()'
);

-- Step 6: Keep the database awake (runs every 10 minutes)
select cron.schedule(
  'keep-alive',
  '*/10 * * * *',
  'select 1'
);

-- ============================================================
--  To stop all active deliveries:
--    select cron.unschedule('deliver-campaign');
--
--  To cancel a specific boost:
--    update boosts set active = false where id = 'the-boost-uuid';
--
--  To remove the keep-alive job:
--    select cron.unschedule('keep-alive');
-- ============================================================
