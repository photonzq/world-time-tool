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

**Link** copies the current view, including the pinned column if one is set.
There are two hash forms, and both load.

### Packed — what you normally get

    .../#5032CNE2K4J4Q0

The whole state bit-packed and written in base 32 over `0-9A-V`: 3 bits of
format version, then row count, home row, clock format, and two presence flags,
then a 15-bit date (days from 2020-01-01, so 2020–2109), a 5-bit pinned column,
and one 8-bit zone index per row. Four zones with a pin is 67 bits — 14
characters.

Zone indices point into `ZONES`, the Windows time-zone list frozen as a literal
in `index.html`. **That table is append-only.** Reordering it would silently
repoint every link ever issued, so the self test checksums it. Indexing the
merged 426-zone catalogue instead is not possible: it depends on what the
browser's ICU reports, so the same code would mean different cities on
different browsers. The ~287 zones outside the frozen table are simply not
packable and fall back to the readable form.

### Readable — hand-editable, and what old links use

    .../#z=am.New_York,am.Los_Angeles,eu.Berlin,as.Shanghai&d=20260921&p=14

`z` is the rows, `h` the home zone when it is not the first row, `d` the date,
`t` the clock format, `p` the pinned column. IANA area prefixes fold to two
letters (`am.` = `America/`), and the fragment carries `/` and `,` unescaped.

Arriving on a readable link keeps writing readable ones, so hand-editing does
not turn opaque the moment it is applied. Links written before this encoding
existed, with percent-encoded full zone names, still load.

### Rules that apply to both

Omitted keys take their default, so a link with no date always opens on today —
useful for a bookmark. Pinning forces the date to be written, because a pin
names one instant and would otherwise land on the wrong day.

### QR codes

Length is what matters, and the packed form is 58 characters against 158 for
the original encoding. Measured with a real encoder, at error correction M that
is QR version 4 (33x33 modules) instead of version 9 (53x53) — 0.39x the area,
so each module prints about 60% wider at the same physical size:

| EC level | original, 158 ch | packed, 58 ch | area |
|---|---|---|---|
| L | v8 49x49 | v4 33x33 | 0.45x |
| M | v9 53x53 | v4 33x33 | 0.39x |
| Q | v11 61x61 | v5 37x37 | 0.37x |
| H | v13 69x69 | v6 41x41 | 0.35x |

The base-32 alphabet is deliberately inside QR's alphanumeric charset
(`0-9 A-Z $%*+-./:` and space), which encodes at 5.5 bits per character rather
than 8. At this URL that is a free property rather than the win: the lowercase
host and path are 74% of the string and force byte mode anyway, and the 30 bits
saved do not cross a version boundary. It would start to matter on a shorter
host.

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

Open `index.html?selftest=1`. It runs 115 assertions covering DST transitions,
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
