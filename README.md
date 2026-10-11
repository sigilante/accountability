# %accountability

![](./img/hero.jpg)

**Status ~2026.10.11:  `%accountability` is published from ~magbel.**

`%accountability` watches all 256 Urbit galaxies from one observer ship and publishes what it sees. Every 10 minutes it checks each galaxy's keys on chain, whether it answers, and which `%kids` OTA it serves. It logs every change with a timestamp. A dashboard and a public JSON API serve the results.

Galaxies sponsor the network and distribute its OTA updates. This project records which galaxies answer, which serve the same OTA as ~zod, and which do neither.

## What it measures

Each round, for every galaxy, the agent:

- **Reads the galaxy's Azimuth point** (life, rift, owner, management proxy) from the `%azimuth` agent. If `%azimuth` has no point, it reads life and rift from Jael and reports `dominion: "jael"`.
- **Pokes the galaxy's `%ping` agent.** A galaxy is **up** for a round if it answered any probe since the previous round began.
- **Watches the galaxy's `%kids` desk**, the desk its children sync OTAs from. One Clay read stays open per galaxy and answers when the galaxy commits a new revision. Each new revision triggers two more reads: the desk hash (`%cz`, as `+vats` prints it) and `/sys/kelvin`.

**OTA reference.** ~zod is the canonical OTA source. A galaxy is **behind ~zod** when its `%kids` hash or kelvin differs from ~zod's. If ~zod has not answered a `%kids` read, no galaxy is marked behind.

**Events.** After a galaxy's first observation, which is its baseline, the agent logs these changes:

| event | when |
|---|---|
| `up`, `down` | the galaxy started or stopped answering |
| `breach` | rift changed on chain |
| `rekey` | life changed on chain |
| `owner`, `management` | the owner or management proxy changed |
| `ota` | the galaxy committed a new `%kids` revision (any commit, not only a release) |
| `gap` | the observer itself ran no round for three intervals; the next round is not scored |

The agent does not track spawn, voting, or transfer proxies, sponsor, escape, or dominion.

## Limits of the measurements

- **One observer per score.** "Up" means reachable from the observer ship. A galaxy that the observer cannot reach reads as down. Peers' reports appear beside the score but never change it; see [Peers](#peers).
- **"Answered" is not "serving".** Any acknowledgment from `%ping`, or any Clay answer, counts.
- **One-round resolution.** Times for `up`, `down`, and `since` are the round in which the agent noticed, not the moment of change. One missed round marks a galaxy down.
- **Calendar-day tallies.** "Today", "7 days", and "30 days" count rounds in UTC calendar days, today included. "Today" at 00:05 UTC holds one or two rounds.
- **Warm-up.** A galaxy is **unscored** until one interval after the agent first sees it.
- **History starts at install.** `%azimuth` drops raw Ethereum logs after each snapshot, so on-chain changes are recorded only from when the agent starts. The first `%kids` revision read from each galaxy is a baseline: when it reached the galaxy is unknown.
- **Ames `last-contact` is not a liveness signal.** Ames sets it when it first sends to a peer. The agent reports it as `contact` and never scores it.

## Install

The desk declares `[%zuse 409]` and `[%zuse 408]`. It needs a ship with `%azimuth` running, such as a livenet comet or planet.

```
|new-desk %accountability
|mount %accountability
```

Copy `desk/` into the mounted directory, resolving any symlinks:

```sh
rsync -aL desk/ <pier>/accountability/
```

Then commit and install:

```
|commit %accountability
|install our %accountability
```

The dashboard is at `/apps/accountability` on the ship's web port. Galaxies stay unscored for the first interval.

## Peers

Observers can exchange their measurements. Each ship keeps a whitelist of peer observers. The relation is bilateral: a ship subscribes to each peer's reports and serves its own only to ships on its list. Two ships exchange reports once both have added each other.

### Adding a peer

Run the same poke on both ships, each naming the other. A comet needs its full `@p`.

```
:: on ~sampel-palnet
:accountability &accountability-action [%peer ~magbel &]
:: on ~magbel
:accountability &accountability-action [%peer ~sampel-palnet &]
```

The first ship to add the other is refused until the second does. Each ship retries once a round, so reports flow within one interval of the second poke. A ship cannot add itself.

### Removing a peer

```
:accountability &accountability-action [%peer ~sampel-palnet |]
```

This drops the peer's reports, ends our subscription to it, and kicks its subscription to ours. The peer's next retry is refused. To exchange reports again, add it back; it starts over with 30 days of history.

### Asking for older tallies

```
:accountability &accountability-action [%fill ~sampel-palnet ~2026.9.1]
```

This replaces our subscription to the peer with one that starts on that UTC day, and the peer sends its tallies from then on. A new subscription starts 29 days back, which with today makes 30; after a dropped subscription, it starts from the newest day the peer has reported.

### Checking a peer

- `galaxies.json` lists each peer under `peers`. `heard` is when its last report came; `refused` is when it last refused our subscription, usually because it has not added us yet, and is null once it accepts.
- `:accountability +dbug [%outgoing ~]` shows our subscriptions to peers; `ackd=%.y` means the peer accepted. `:accountability +dbug [%incoming ~]` shows peers subscribed to us.
- A peer's galaxies read `up: null` until it has scored a round, one interval after it starts.

### What a report holds and changes

- **Contents.** The peer's daily tallies for each galaxy, each scored galaxy's up or down state as of the peer's last round, and that round's time. After the first report, the peer sends today's tallies after every round.
- **Reach.** Only the ship that subscribed. Nothing is relayed, so a report always comes straight from the ship that measured it, and Ames authenticates that ship.
- **Effect.** Nothing in our own scores. The dashboard shows peers in a ledger column ("2/3" peers see the galaxy up), a **disputed** filter for galaxies where most fresh peers disagree with us, and a table in the detail drawer. A peer is fresh if its last round came within three of our intervals.
- **Untrusted input.** A malformed report is dropped whole; an entry with a non-galaxy ship, more answered rounds than rounds, or a future day is dropped alone.

## Pokes and scries

Pokes come from the observer ship only. See [Peers](#peers) for `%peer` and `%fill`.

```
:accountability &accountability-action [%interval ~m5]   :: time between rounds; default ~m10
:accountability &accountability-action [%round ~]        :: run a round now; restarts the cadence
:accountability &accountability-action [%reset `~zod]    :: drop a galaxy's open probes; ~ for all
:accountability &accountability-action [%peer ~sampel-palnet &]          :: add a peer; | removes
:accountability &accountability-action [%fill ~sampel-palnet ~2026.9.1]  :: re-request a peer's tallies
```

`%round` scores a round, so a galaxy slow to answer can read down for one round.

```
.^((map ship galaxy:accountability) %gx /=accountability=/galaxies/noun)
.^((unit galaxy:accountability) %gx /=accountability=/galaxy/~zod/noun)
.^((list event:accountability) %gx /=accountability=/events/noun)
.^((map ship peer:accountability) %gx /=accountability=/peers/noun)
```

Agents on the observer ship can subscribe to `/events`, which gives each new event as a `%noun` fact. It does not replay past events.

## HTTP API

All routes are GET and need no login. JSON responses send `access-control-allow-origin: *` on purpose: the data is public.

| route | returns |
|---|---|
| `/apps/accountability` | the dashboard |
| `/apps/accountability/galaxies.json` | `{now, round, observer, interval, peers: [Peer], galaxies: [Summary]}` |
| `/apps/accountability/galaxy/~zod.json` | one `Summary` plus `days`, `kidsLog`, `chainLog`, `events` |
| `/apps/accountability/events.json` | `[Event]`, newest first |

`events.json` takes `ship=~zod`, `since=<ms>`, `before=<ms>`, and `limit=<n>` (default 500). `since` and `before` are exclusive. Pass the newest `at` you hold as `since` to poll for new events. The agent ignores filters it cannot parse.

`now` is the time of the request; `round` is when the last round started, or null before the first.

**Units.** Times are Unix milliseconds, `interval` is seconds, addresses are `0x` plus 40 hex digits, and hashes are `@uv` text (`0v…`). A hash of `0v0` means the read was refused or malformed.

**Summary** fields:

| field | meaning |
|---|---|
| `ship` | `"~zod"` |
| `chain` | `{life, rift, dominion, owner, management}`, or null |
| `up` | answered in the last scored round |
| `since` | when `up` last changed, or was first scored; null while unscored |
| `heard` | last answer to any probe |
| `uptime` | `{day, week, month}`, each `{up, all}`: rounds answered of rounds run, over 1, 7, or 30 UTC days |
| `kids` | `{aeon, date, hash, kelvin: [{lal, num}]}`, or null; `date` is the galaxy's commit time |
| `missing` | when `%kids` last read as empty or malformed |
| `wait` | open probes by send time: `ping`, `z`, `x`, and `w`, the standing watch for the next commit |
| `contact` | Ames last-contact; informational, not a liveness signal |
| `peers` | `[{ship, up, uptime}]`: each peer's report of this galaxy; `up` is null if the peer has not scored it |

**Peer** fields: `{ship, heard, refused, round}`: when its last report came, when it last refused our subscription (null once it accepts), and when its last round started.

**Event** fields: `{at, ship, type, ...}`, where `type` is one of the events above. `up` has `since`; `down` has `since` and `last`; `breach`, `rekey`, `owner`, and `management` have `from` and `to`; `ota` has `from` and `to` as `kids` records; `gap` has `from`, and its `ship` is the observer.

```sh
curl -s localhost/apps/accountability/galaxies.json | jq '.galaxies[] | select(.up) | .ship'
curl -s 'localhost/apps/accountability/events.json?ship=~zod&limit=20'
```

## Dashboard

The dashboard has four parts:

- **Network grid.** All 256 galaxies, colored by state: up and matching ~zod, up and behind ~zod, down, unkeyed, or unscored. Hovering a cell shows the galaxy's sigil.
- **Event feed.** New events every minute.
- **Ledger.** Sortable and filterable. The search box in the header and the ledger's filter box share one query.
- **Detail drawer.** Opens from any galaxy. Shows liveness by day, events, the `%kids` timeline against ~zod, and on-chain keys.

The **sound** button plays tones on hover. Its setting is saved in the browser.

## State

The agent is at state `%2`; `%1` lacked peers and `%0` the event log. The event log, the daily tallies, peers' tallies, and the `%kids` and chain logs grow without bound.

## Repository layout

- `desk/`: the desk
  - `app/`: the agent
  - `sur/`: types
  - `lib/accountability.hoon`: JSON encoding
  - `web/`: the dashboard and vendored sigil-js
  - `fnt/`: fonts
  - `mar/`: marks
- `desk/lib/{dbug,default-agent,docket,server,skeleton,verb}.hoon` are unmodified copies from the Urbit repository.
- `design/`: the design prototype the dashboard implements; see `design/README.md`.
- `licenses/`: third-party license texts.

## Credits and licenses

`%accountability` is MIT-licensed; see `LICENSE`. Third-party parts:

- **@urbit/sigil-js** 2.2.0, © 2019 Tlon, MIT (`licenses/sigil-js-MIT.txt`). It is vendored as `desk/web/sigil.js` with changes listed in its header.
- **Space Mono**, © 2016 The Space Mono Project Authors, SIL Open Font License 1.1 (`licenses/space-mono-OFL.txt`).
- **Urbit Sans** is used by permission of its rights holder. The MIT license here does not cover it.
- **Urbit library files** in `desk/lib/`, © 2015 Urbit, MIT (`licenses/urbit-MIT.txt`).

The agent began from the [Sunrise](https://github.com/sigilante/sunrise) template.
