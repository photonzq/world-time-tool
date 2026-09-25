# World Time Tool

A single-file time-zone comparison grid. Pick a set of zones, read across an
hour axis, pin a meeting and take it away as a sentence, a link or a calendar
event.

**[Live demo](https://photonzq.github.io/world-time-tool/)**

Open `index.html` — that is the whole application. No build, no install, no
network access, no dependencies.

## Running it

Use the [live demo](https://photonzq.github.io/world-time-tool/), or download
`index.html` and double-click it. It is the same file either way; nothing is
fetched at runtime.

To reach it from a phone on the same Wi-Fi, run `serve.bat`. It prints a LAN
address to open:

    this PC   http://localhost:8000
    phone     http://192.168.x.x:8000

Serving it also makes `localStorage` persistence and the clipboard reliable,
both of which are restricted on `file://`.

## What it does

- **~426 zones** — the Windows time-zone selector list, merged with every
  other zone the browser's ICU knows about. Searchable by:
  - city, including major cities that are not zones of their own
    (`houston`, `munich`, `bombay`, `nyc`, `sf`)
  - state or region (`california`, `texas`, `queensland`, `ontario`)
  - country (`brazil`, `united kingdom`, `usa`), taken from the browser's CLDR
    data rather than shipped
  - ICU's own zone names (`gulf`, `arabian`, `central european`)
  - IANA id, abbreviation (`CEST`, `JST`, `MSK`), or UTC offset (`utc+8`,
    `+5:30`, `gmt-3`)

  Results are ranked, whole-word matches first, so `india` finds India before
  Indiana. Among equal matches the more commonly compared zone comes first, and
  Enter adds the top result. An offset search shows the offset it matched on.
- **Three clock formats** — `am/pm`, `24`, and `MX`, which writes each row the
  way its own country writes clock time (Zurich `05:42`, New York `11:47p`).
- **Correct DST**, including the awkward cases: 23/24/25-hour days, Lord Howe's
  half-hour shift, zones whose local midnight does not exist, and dates a zone
  skipped entirely when it crossed the date line.
- **Pin a meeting.** Click a column, or on desktop drag across several. The
  pinned bar sets the start (`:00` `:15` `:30` `:45`) and the length (30 minutes
  to 4 hours). Each zone gets a chip with its local range, coloured by working
  hours over the *whole* meeting: 9–5 in that zone's own time, so a meeting
  counts only if it ends by 17:00. A 2-hour meeting at 4 PM is fringe even
  though the 4 PM column is green. From the bar:
  - **Copy sentence** — prose for an email or a prompt, ending in an ISO 8601
    interval
  - **Add to calendar** — an `.ics` file generated in the page, times in UTC so
    any calendar converts them
  - **Share** — on phones, the system share sheet
- **Least-bad hours.** On a weekday with no hour where everyone is inside 9–5,
  the three least-bad hours are starred on the ruler and listed in the footer;
  click one to pin it. Night is weighted by how late it is, so a 7 AM start
  beats asking someone to join at midnight.
- **DST drift warnings.** A recurring meeting stays fixed in the home clock,
  and when another zone changes its clocks on a different date, the gap moves.
  If that happens within 8 weeks of the pinned date, the bar says when and for
  how long ("Berlin: gap to New York drops to 5 h from Sun 25 Oct, for one
  week").
- **Keyboard:** `←` `→` move the pin, `[` `]` change day, `T` today, `/` search,
  `C` copy the sentence, `Esc` clear the pin.
- **Reorder and undo.** Drag the ▲ on desktop, or press and hold a row on a
  phone, to move it. Removing a row can be undone for six seconds.
- **Drag the divider** on the right of the place column to widen it when a
  zone's full name does not fit; double-click the divider to reset. The width
  is remembered. Hovering a place or its subtitle shows the full text and the
  IANA id regardless.
- Weekend hatching, ISO week number, live clock, permalinks in the URL hash.

## Links

**Link** copies the current view, including the pinned column if one is set.
There are two hash forms, and both load.

### Packed — what you normally get

    .../#9PGV2E00GC8

The whole state bit-packed and written in base 32 over `0-9A-V`, most
significant bit first:

| field | bits | |
|---|---|---|
| version | 2 | |
| row count | 4 | minus one, so 1–16 rows |
| home flag | 1 | set when home is row 0, which it nearly always is; otherwise 4 more bits |
| clock format | 2 | |
| date / pin present | 1 + 1 | |
| date | 14 | days from 2024-01-01, so 2024–2068 |
| pinned column | 5 | |
| each row | 6 or 9 | `0` + 5-bit rank for the 32 most-compared zones, else `1` + 8-bit `ZONES` index |
| meeting | 2 + 3 | start minute and length, only when the meeting is not the default 1 h from `:00` |

Four common zones with a date and a pin is 54 bits — **11 characters**, one more
with a non-default meeting. Without a date or pin it is 7.

The meeting tail is read leniently: reading past the end yields 0, which is
the default. So a link without it decodes exactly as it always did, and an
older copy of the page, which stops after the rows, still gets the right pin.

Zone codes point into two literals frozen in `index.html`: `ZONES`, the Windows
time-zone list, and `POP`, the 32 zones that get the short code. **Both are
append-only** — reordering either silently repoints links that are already out
there, so the self test checksums `ZONES` and asserts every `POP` entry
resolves. Indexing the merged 426-zone catalogue instead is not possible: it
depends on what the browser's ICU reports, so one code would mean different
cities on different browsers.

Anything that does not fit falls back to the readable form: a zone outside
`ZONES` (about 287 of the 426), more than 16 rows, or a date outside 2024–2068.

### Readable — hand-editable, and what old links use

    .../#z=am.New_York,am.Los_Angeles,eu.Berlin,as.Shanghai&d=20260921&p=14

`z` is the rows, `h` the home zone when it is not the first row, `d` the date,
`t` the clock format, `p` the pinned column, `m` the meeting's start minute and
`l` its length in minutes. IANA area prefixes fold to two letters (`am.` =
`America/`), and the fragment carries `/` and `,` unescaped.

Arriving on a readable link keeps writing readable ones, so hand-editing does
not turn opaque the moment it is applied. Links written before this encoding
existed, with percent-encoded full zone names, still load.

### Rules that apply to both

Omitted keys take their default, so a link with no date always opens on today —
useful for a bookmark. Pinning forces the date to be written, because a pin
names one instant and would otherwise land on the wrong day. A 1-hour meeting
from `:00` is the default and adds nothing.

### QR codes

Length is what sets the QR version, and the packed form is 55 characters
against 158 for the first encoding. Measured with a real encoder at error
correction M, that is version 4 (33x33 modules) instead of version 9 (53x53) —
0.39x the area, so each module prints about 60% wider at the same physical
size.

Past that point **the fragment is no longer the constraint — the URL prefix
is.** `https://photonzq.github.io/world-time-tool/#` is 44 of the 55
characters, and shrinking the fragment to 8 still leaves version 4. What would
actually help:

| URL | chars | version |
|---|---|---|
| current | 55 | v4 33x33 |
| repo renamed to something short | 43 | v4 33x33 (misses v3 by 4 bits) |
| served from a `photonzq.github.io` user site | 39 | v3 29x29 |
| user site, state in the path, all uppercase | 38 | **v2 25x25** |

The base-32 alphabet is deliberately inside the QR alphanumeric charset
(`0-9 A-Z $%*+-./:` and space), which encodes at 5.5 bits per character rather
than 8. That is free but unused today: the lowercase host and path force byte
mode for the whole string. It only pays off in the last row above, where a user
site has no case-sensitive path, the state moves out of the fragment into the
path (`#` is not in the charset), and the entire URL can be uppercased — the
host being case-insensitive. That needs a `404.html` to route the path, which
is not implemented here.

## Design notes

All date arithmetic derives from one primitive: `Intl.DateTimeFormat`
converting an instant to wall-clock fields. Everything else — local midnight,
day length, UTC offsets, the inverse wall-clock-to-instant conversion — is
built on top. No time-zone database is bundled, so the rules never go stale:
they come from the browser and update with it.

The zone list embedded in the file is **labels only**. Regenerating it is
unnecessary when time-zone rules change.

Grid columns are UTC-hour steps anchored to the home zone's local midnight,
and the column count is derived rather than assumed — which is why transition
days come out right.

## Tests

Open [`?selftest=1`](https://photonzq.github.io/world-time-tool/?selftest=1), or
`index.html?selftest=1` locally. It runs 219 assertions, covering:
- DST transitions, offset arithmetic, ISO weeks
- the zone catalogue, search ranking and name mapping
- the link codec, including every meeting start and length
- the calendar file format, DST drift notes and slot scoring
- the clock-format logic

It prints a pass/fail table. Golden values were cross-checked against an
independent implementation.

## Browser support

Roughly 2021 and newer (Chrome 84+, Safari 14.1+), set by flexbox `gap`.
Newer APIs degrade rather than break:
- without `Intl.supportedValuesOf`, the catalogue falls back to the Windows list
- without `Intl.Locale.getTimeZones`, the `MX` format behaves as 24-hour and
  country names are not searchable
- without `navigator.share`, the Link button copies instead

## Licence

Public domain — [the Unlicense](https://unlicense.org). See `LICENSE`.
