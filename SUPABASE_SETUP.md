# Supabase Leaderboard Scaffold

The project now includes a leaderboard service scaffold in `lib/application/services/leaderboard_service.dart`.

Required future environment/config values:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- optional `SUPABASE_LEADERBOARD_TABLE` (defaults to `leaderboard_entries`)
- `SUPABASE_SUBMIT_URL` for a trusted submission endpoint or Supabase Edge Function
- authenticated user/session token source wired into `LeaderboardSessionProvider`
- optional player profile identifier / auth token source

Recommended table:

`leaderboard_entries`
- `id` uuid primary key
- `player_name` text not null
- `category` text not null
- `score` numeric not null
- `prestige` int not null default 0
- `era_reached` text
- `best_combo` int not null default 0
- `total_clicks` bigint not null default 0
- `event_clicks` bigint not null default 0
- `rare_event_clicks` bigint not null default 0
- `best_event_chain` int not null default 0
- `route_signature` text
- `season_key` text not null default 'season_alpha'
- `weekly_key` text not null
- `submitted_at` timestamptz not null default now()

Recommended indexes:
- `(category, score desc)`
- `(season_key, category, score desc)`
- `(weekly_key, category, score desc)`
- `(player_name, category)`

Recommended future validation:
- reject impossible jumps in `score`
- reject submissions with impossible `best_combo` / `event_chain`
- require signed sessions or edge-function verification for writes

Suggested future categories:
- `all_time_score`
- `weekly_score`
- `prestige`
- `combo`
- `event_clicks`
- `event_chain`

Current state:
- leaderboard service will use Supabase REST automatically when the `dart-define`
  values above are present
- local fallback snapshot is still used when configuration is missing or network
  requests fail
- score submission is intentionally disabled unless `SUPABASE_SUBMIT_URL` and
  a valid session token are provided; anonymous REST writes are no longer
  treated as trusted

Suggested run/build flags:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=SUPABASE_SUBMIT_URL=https://YOUR_PROJECT.functions.supabase.co/leaderboard-submit \
  --dart-define=SUPABASE_AUTH_ACCESS_TOKEN=USER_SESSION_JWT \
  --dart-define=SUPABASE_AUTH_USER_ID=USER_ID
```

Suggested trusted submission flow:

```text
client with user session -> signed edge function -> validation -> insert into leaderboard_entries
```

The edge function should verify:
- authenticated user or signed session token
- score/category bounds
- monotonic progression rules where relevant
- weekly/season routing

Example SQL:

```sql
create table if not exists public.leaderboard_entries (
  id uuid primary key default gen_random_uuid(),
  player_name text not null,
  category text not null,
  score numeric not null,
  prestige int not null default 0,
  era_reached text,
  best_combo int not null default 0,
  total_clicks bigint not null default 0,
  event_clicks bigint not null default 0,
  rare_event_clicks bigint not null default 0,
  best_event_chain int not null default 0,
  route_signature text,
  season_key text not null default 'season_alpha',
  weekly_key text not null,
  metadata jsonb not null default '{}'::jsonb,
  submitted_at timestamptz not null default now()
);

create index if not exists leaderboard_entries_category_score_idx
  on public.leaderboard_entries(category, score desc);

create index if not exists leaderboard_entries_weekly_category_score_idx
  on public.leaderboard_entries(weekly_key, category, score desc);
```
