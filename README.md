# yeet-trip-dates

A tiny site for planning the Dec 2026 – Jan 2027 trip. Each person picks their name, taps the days they're free (12 Dec – 10 Jan), and hits **Submit**. Picks are saved in Supabase and loaded back next time.

- **Friends** see only their own calendar.
- **Adeev** (password protected) sees his own calendar plus a combined view of everyone's free days.

## How it works

- `index.html` is the whole site: plain HTML/CSS/JS, hosted on GitHub Pages.
- Data lives in the Supabase project `yeet-trip-dates`, table `availability` (one row per person).
- The table has row-level security on and no public policies, so the browser can't read it directly. The page only talks to four database functions (`supabase/schema.sql`):
  - `get_dates(name, password)`: one person's dates (Adeev's needs the password)
  - `save_dates(name, dates, password)`: save a person's dates (only days in the trip window are kept)
  - `check_admin(password)`: checks Adeev's password
  - `get_all(password)`: everyone's dates, only with Adeev's password
- The password is checked on the server as a SHA-256 hash; it isn’t in the page source or this repo (the schema file has a placeholder).

The Supabase publishable key in `index.html` is meant to be public. It can only call the functions above.
