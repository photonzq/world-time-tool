# World Time Tool

A single-file time-zone comparison grid. Pick a set of zones, read across an
hour axis, pin a moment and copy it out as a sentence.

Open `index.html` — that is the whole application. No build, no install, no
network access, no dependencies.

## Running it

Double-click `index.html`.

To reach it from a phone on the same Wi-Fi, run `serve.bat`. It prints a LAN
address to open:

    this PC   http://localhost:8000
    phone     http://192.168.x.x:8000

Serving it also makes `localStorage` persistence and the clipboard reliable,
both of which are restricted on `file://`.

## What it does

- **~426 zones** — the Windows time-zone selector list, merged with every
  other zone the browser's ICU knows about. Searchable by city, IANA id,
  abbreviation (`CEST`, `JST`, `MSK`) and a few aliases (`Kolkata`, `Boston`).
- **Three clock formats** — `am/pm`, `24`, and `MX`, which writes each row the
  way its own country writes clock time (Zurich `05:42`, New York `11:47p`).
- **Correct DST**, including the awkward cases: 23/24/25-hour days, Lord Howe's
  half-hour shift, zones whose local midnight does not exist, and dates a zone
  skipped entirely when it crossed the date line.
- **Pin a column** to get every zone's local time for that instant, colour-coded
  by working hours, plus a copy-ready sentence for an email or a prompt.
- Weekend hatching, ISO week number, live clock, permalinks in the URL hash.

## Links

**Link** copies the current view, including the pinned column if one is set:

    .../#z=am.New_York,am.Los_Angeles,eu.Berlin,as.Shanghai&d=20260921&p=14

`z` is the rows, `h` the home zone when it is not the first row, `d` the date,
`t` the clock format, `p` the pinned column. IANA area prefixes fold to two
letters (`am.` = `America/`), and the fragment carries `/` and `,` unescaped,
which together roughly halve the length.

Omitted keys take their default, so a link with no `d` always opens on today —
useful for a bookmark. Pinning forces `d` to be written, because a pin names one
instant and would otherwise land on the wrong day. Links written by earlier
versions, with percent-encoded full zone names, still load and are rewritten to
the short form.

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

Open `index.html?selftest=1`. It runs 93 assertions covering DST transitions,
offset arithmetic, ISO weeks, the zone catalogue, the link codec and the
clock-format logic, and prints a pass/fail table. Golden values were
cross-checked against an independent implementation.

## Browser support

Roughly 2021 and newer (Chrome 84+, Safari 14.1+), set by flexbox `gap`.
Two newer APIs degrade rather than break: without `Intl.supportedValuesOf` the
catalogue falls back to the Windows list, and without `Intl.Locale.getTimeZones`
the `MX` format behaves as 24-hour.

## Licence

Public domain — [the Unlicense](https://unlicense.org). See `LICENSE`.
