-- ============================================================
--  Exalt Digital — Simulated Traffic
--  Run this in: Supabase Dashboard → SQL Editor
-- ============================================================

-- Step 1: Enable pg_cron (if not already on)
create extension if not exists pg_cron;

-- Step 2: Create a boosts table so we know when a boost was purchased
create table if not exists boosts (
  id         uuid        primary key default gen_random_uuid(),
  site_url   text,
  amount     integer,
  created_at timestamptz default now(),
  active     boolean     default true
);

-- Allow anon to insert (called from success page)
alter table boosts enable row level security;
create policy "anon_insert_boost" on boosts for insert to anon with check (true);
create policy "anon_select_boost" on boosts for select to anon using (true);

-- Step 3: Function that inserts realistic-looking fake visits
create or replace function insert_fake_visits()
returns void as $$
declare
  paths      text[] := array['/', '/', '/', '/pricing', '/pricing', '/services', '/contact', '/about'];
  browsers   text[] := array['Chrome', 'Chrome', 'Chrome', 'Safari', 'Firefox', 'Edge'];
  devices    text[] := array['desktop', 'desktop', 'mobile', 'mobile', 'tablet'];
  os_list    text[] := array['Windows', 'Windows', 'macOS', 'iOS', 'Android'];
  referrers  text[] := array[
    'https://google.com', 'https://google.com', 'https://google.com',
    'https://facebook.com', 'https://instagram.com',
    '', '', ''
  ];
  screens    text[] := array['1920x1080', '1440x900', '390x844', '414x896', '1280x800'];
  boost_count integer;
  num_visits  integer;
  chosen_path text;
  i           integer;
begin
  -- Check how many active boosts exist (more boosts = more traffic)
  select count(*) into boost_count from boosts where active = true;
  if boost_count = 0 then return; end if;

  -- Insert 1-4 visits per cron tick depending on boost count
  num_visits := 1 + floor(random() * (2 + boost_count))::int;

  for i in 1..num_visits loop
    chosen_path := paths[1 + floor(random() * array_length(paths, 1))::int];
    insert into page_views (
      url, path, title, referrer, browser, os,
      device_type, screen_size, language, session_id, site_id
    ) values (
      'https://exaltdigital.github.io' || chosen_path,
      chosen_path,
      case chosen_path
        when '/'         then 'Exalt Digital — SEO That Gets Results'
        when '/pricing'  then 'Pricing — Exalt Digital'
        when '/services' then 'Services — Exalt Digital'
        when '/contact'  then 'Contact — Exalt Digital'
        else 'Exalt Digital'
      end,
      referrers[1 + floor(random() * array_length(referrers, 1))::int],
      browsers[1 + floor(random() * array_length(browsers, 1))::int],
      os_list[1 + floor(random() * array_length(os_list, 1))::int],
      devices[1 + floor(random() * array_length(devices, 1))::int],
      screens[1 + floor(random() * array_length(screens, 1))::int],
      'en-AU',
      md5(random()::text || clock_timestamp()::text),
      'exaltdigital.github.io'
    );
  end loop;
end;
$$ language plpgsql security definer;

-- Step 4: Schedule it — runs every minute
select cron.schedule(
  'trickle-traffic',
  '* * * * *',
  'select insert_fake_visits()'
);

-- ============================================================
--  To STOP the traffic simulation, run:
--  select cron.unschedule('trickle-traffic');
--
--  To PAUSE a boost (stop traffic for a specific purchase):
--  update boosts set active = false where id = 'the-boost-uuid';
-- ============================================================
