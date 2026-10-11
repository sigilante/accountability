::  /app/accountability: watch every galaxy from one observer ship
::
::    Each round, for each of the 256 galaxies, we:
::    - read its Azimuth point from %azimuth, or life and rift from Jael;
::    - record Ames's last-contact time, which we report but do not score;
::    - score the previous round: up if the galaxy answered any probe
::      since that round began;
::    - poke its %ping agent, unless a poke is already in flight.
::
::    We also hold one Clay read open against each galaxy's %kids desk.
::    The first asks for %w at the current date, which returns the
::    latest revision.  Each later read asks for the revision after the
::    last one seen, so it answers only when the galaxy commits.  Each
::    new revision triggers a %z read (desk hash) and an %x read of
::    /sys/kelvin.  Answers are untrusted: a malformed one reads as empty.
::
::    A probe to a dead galaxy never answers, so we never resend one
::    while it is in flight.  We resend:
::    - every probe, when the galaxy's rift changes (a breach orphans
::      our flows and resets its Clay);
::    - a %z or %x read open an hour while the galaxy answers others;
::    - a %w read six hours after %kids last read as empty.
::    Galaxies with no networking keys get no probes and score as down.
::
::  measurement limits:
::    "up" means reachable from this ship, not serving anything; times
::    have the resolution of one round; one missed round marks a galaxy
::    down.  A galaxy is unscored (.since is ~) until its first scored
::    round, one interval after it is first seen.  On-chain history
::    starts when the agent starts, because %azimuth drops raw logs after
::    snapshots.
::
::  events, after each galaxy's first observation (its baseline):
::    up, down        liveness changed
::    breach, rekey   rift or life changed on chain
::    owner,          owner or management proxy changed; not logged when
::    management      either side came from the Jael fallback, which has
::                    no addresses.  Spawn, voting, and transfer proxies,
::                    sponsor, escape, and dominion are not tracked.
::    ota             the galaxy committed a new %kids revision; any
::                    commit, not only a release
::    gap             .who is us: we ran no round for three intervals;
::                    the next round is not scored
::
::  scries:
::    .^((map ship galaxy:accountability) %gx /=accountability=/galaxies/noun)
::    .^((unit galaxy:accountability) %gx /=accountability=/galaxy/~zod/noun)
::    .^((list event:accountability) %gx /=accountability=/events/noun)
::
::  subscription, our ship only:
::    /events gives each new event as a %noun fact; no replay
::
::  HTTP, GET only, no login, CORS open to any origin by design:
::    /apps/accountability                      the dashboard
::    /apps/accountability/galaxies.json        every galaxy, summarized
::    /apps/accountability/galaxy/~zod.json     one galaxy with its logs
::    /apps/accountability/events.json          newest first; filters:
::      ship=~zod, since=<ms>, before=<ms> (both exclusive, Unix ms),
::      limit=<n> (default 500).  Unparseable filters are ignored.
::    /apps/accountability/sigil.js, fnt/*      page assets
::
::  pokes, our ship only:
::    :accountability &accountability-action [%interval ~m5]
::      time between rounds, from the next round on; default ~m10
::    :accountability &accountability-action [%round ~]
::      run a round now and restart the cadence.  It scores a round,
::      so a galaxy slow to answer can read down for one round.
::    :accountability &accountability-action [%reset `~zod]
::      drop one galaxy's open probes and draft (~ for all galaxies) and
::      cancel its %kids watch; the next round sends fresh probes
::
/-  *accountability
/+  default-agent, dbug, verb, server, *accountability
|%
+$  versioned-state  $%(state-0 state-1)
+$  state-1
  $:  %1
      interval=@dr
      timer=(unit @da)
      last=(unit @da)                       ::  start of the previous round
      galaxies=(map ship galaxy)
      events=(list event)                   ::  newest first
  ==
::  +state-0: %1 added .events.  It reuses the current +galaxy, so
::  freeze a copy here before changing +galaxy.
::
+$  state-0
  $:  %0
      interval=@dr
      timer=(unit @da)
      last=(unit @da)
      galaxies=(map ship galaxy)
  ==
+$  card  card:agent:gall
--
%+  verb  |
%-  agent:dbug
=|  state-1
=*  state  -
^-  agent:gall
=<
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
    cor   ~(. +> bowl)
++  on-init
  ^-  (quip card _this)
  =.  interval  ~m10
  =^  cards  state  abet:(set-timer:cor now.bowl)
  :_  this
  [[%pass /eyre %arvo %e %connect [~ /apps/[dap.bowl]] dap.bowl] cards]
::
++  on-save  !>(state)
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  =/  ole  !<(versioned-state old)
  =?  ole  ?=(%0 -.ole)
    [%1 interval.ole timer.ole last.ole galaxies.ole ~]
  ?>  ?=(%1 -.ole)
  =.  state  ole
  =^  cards  state  abet:reset-timer:cor
  [cards this]
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+    mark  (on-poke:def mark vase)
      %accountability-action
    ?>  =(our src):bowl
    =^  cards  state  abet:(act:cor !<(action vase))
    [cards this]
  ::
      %handle-http-request
    =+  !<([eyre-id=@ta req=inbound-request:eyre] vase)
    [(handle-http:cor eyre-id req) this]
  ==
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ::  Eyre opens this for public requests too, as a guest ship
  ::
  ?+  path  (on-watch:def path)
    [%http-response *]  `this
    [%events ~]         ?>(=(our src):bowl `this)
  ==
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+    path  (on-peek:def path)
    [%x %galaxies ~]  ``noun+!>(galaxies)
    [%x %events ~]    ``noun+!>(events)
  ::
      [%x %galaxy @ ~]
    =/  who  (slaw %p i.t.t.path)
    ?~  who  [~ ~]
    ``noun+!>((~(get by galaxies) u.who))
  ==
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  =^  cards  state  abet:(agent:cor wire sign)
  [cards this]
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  =^  cards  state  abet:(arvo:cor wire sign-arvo)
  [cards this]
::
++  on-leave  on-leave:def
++  on-fail   on-fail:def
--
=|  cards=(list card)
|_  =bowl:gall
+*  cor  .
++  abet  [(flop cards) state]
++  emit  |=(=card cor(cards [card cards]))
::  +note: log an event and send it to /events subscribers
::
++  note
  |=  [who=ship =change]
  ^+  cor
  =/  =event  [now.bowl who change]
  =.  events  [event events]
  (emit %give %fact ~[/events] %noun !>(event))
::
++  set-timer
  |=  t=@da
  ^+  cor
  =.  timer  `t
  (emit %pass /round/(scot %da t) %arvo %b %wait t)
::  +reset-timer: keep exactly one timer, at the time already set
::
++  reset-timer
  ^+  cor
  =/  old  timer
  ?~  old  (set-timer now.bowl)
  =.  cor  (emit %pass /round/(scot %da u.old) %arvo %b %rest u.old)
  (set-timer u.old)
::
++  act
  |=  =action
  ^+  cor
  ?-    -.action
      %interval  cor(interval t.action)
  ::
      %round
    =/  old  timer
    =?  cor  ?=(^ old)
      (emit %pass /round/(scot %da u.old) %arvo %b %rest u.old)
    (set-timer now.bowl)
  ::
      %reset
    =/  whos=(list ship)
      ?~  who.action  ~(tap in ~(key by galaxies))
      ?.  =(%czar (clan:title u.who.action))  ~
      ~[u.who.action]
    |-  ^+  cor
    ?~  whos  cor
    =/  gal  (~(gut by galaxies) i.whos *galaxy)
    =.  cor  (cancel i.whos gal)
    =.  cor  (save i.whos gal(wait ~, draft ~, missing ~))
    $(whos t.whos)
  ==
::
++  handle-http
  |=  [eyre-id=@ta req=inbound-request:eyre]
  ^-  (list card)
  %+  give-simple-payload:app:server  eyre-id
  ^-  simple-payload:http
  ?.  =(%'GET' method.request.req)
    [[405 ~] ~]
  =/  line  (parse-request-line:server url.request.req)
  =/  key  [site ext]:line
  ?+    key  not-found:gen:server
      [[%apps %accountability %galaxies ~] [~ %json]]
    (json-out (galaxies:to-json now.bowl our.bowl interval last galaxies))
  ::
      [[%apps %accountability %galaxy @ ~] [~ %json]]
    =/  who  (slaw %p (snag 3 site.line))
    ?~  who  not-found:gen:server
    =/  gal  (~(get by galaxies) u.who)
    ?~  gal  not-found:gen:server
    =/  evs  (select `u.who ~ ~ 500)
    (json-out (detail:to-json now.bowl u.who u.gal evs))
  ::
      [[%apps %accountability %events ~] [~ %json]]
    =/  arg  (~(gas by *(map @t @t)) args.line)
    =/  who=(unit ship)  (biff (~(get by arg) 'ship') (cury slaw %p))
    =/  since=(unit @ud)   (biff (~(get by arg) 'since') |=(t=@t (rush t dem)))
    =/  before=(unit @ud)  (biff (~(get by arg) 'before') |=(t=@t (rush t dem)))
    =/  limit=@ud
      (fall (biff (~(get by arg) 'limit') |=(t=@t (rush t dem))) 500)
    (json-out (events:to-json (select who since before limit)))
  ::
      [[%apps %accountability ~] ~]
    (asset 'text/html; charset=utf-8' | (text /web/dashboard/html))
  ::
      [[%apps %accountability %sigil ~] [~ %js]]
    (asset 'application/javascript' & (text /web/sigil/js))
  ::
      [[%apps %accountability %fnt %urbit-sans ~] [~ %woff2]]
    (asset 'font/woff2' & (bits /fnt/urbit-sans/woff2))
  ::
      [[%apps %accountability %fnt %space-mono ~] [~ %ttf]]
    (asset 'font/ttf' & (bits /fnt/space-mono/ttf))
  ==
::  +text, +bits: read a file from our desk
::
++  text
  |=  =path
  ^-  octs
  (as-octs:mimes:html .^(@t %cx (weld here path)))
::
++  bits
  |=  =path
  ^-  octs
  .^(octs %cx (weld here path))
::
++  here  /(scot %p our.bowl)/[q.byk.bowl]/(scot %da now.bowl)
::  +asset: a static file; .keep caches it for a week
::
::    Fonts are served from raw octs: as-octs would drop the trailing
::    zero bytes that both font files end in.
::
++  asset
  |=  [type=@t keep=? dat=octs]
  ^-  simple-payload:http
  :_  `dat
  :-  200
  :~  ['content-type' type]
      ['cache-control' ?:(keep 'public, max-age=604800' 'no-cache')]
  ==
::  +select: newest events first, for .who, after .since, before
::  .before, up to .limit
::
::    .since and .before are Unix milliseconds, compared against each
::    event's time rounded the way the JSON rounds it, so a client can
::    pass back the newest .at it holds without getting it again.
::
++  select
  |=  [who=(unit ship) since=(unit @ud) before=(unit @ud) limit=@ud]
  ^-  (list event)
  =|  out=(list event)
  =/  n=@ud  0
  =/  evs  events
  |-  ^-  (list event)
  ?:  |(?=(~ evs) =(n limit))  (flop out)
  =/  ms  (unm:chrono:userlib at.i.evs)
  ?:  ?&(?=(^ since) (lte ms u.since))  (flop out)
  ?:  ?&(?=(^ before) (gte ms u.before))  $(evs t.evs)
  ?.  |(?=(~ who) =(u.who who.i.evs))  $(evs t.evs)
  $(evs t.evs, out [i.evs out], n +(n))
::  +json-out: JSON any origin may read, for local front-end work
::
++  json-out
  |=  jon=json
  ^-  simple-payload:http
  :_  `(json-to-octs:server jon)
  :-  200
  :~  ['content-type' 'application/json']
      ['access-control-allow-origin' '*']
  ==
::
++  agent
  |=  [=(pole knot) =sign:agent:gall]
  ^+  cor
  ?+    pole  ~|(bad-agent-wire+pole !!)
      [%probe who=@ %ping ~]
    ?.  ?=(%poke-ack -.sign)  cor
    =/  who  (slav %p who.pole)
    =/  gal  (~(gut by galaxies) who *galaxy)
    (save who gal(heard `now.bowl, wait (~(del by wait.gal) %ping)))
  ==
::
++  arvo
  |=  [=(pole knot) =sign-arvo]
  ^+  cor
  ?+    pole  ~|(bad-arvo-wire+pole !!)
      [%eyre ~]  cor
  ::
      [%round t=@ ~]
    ?>  ?=([%behn %wake *] sign-arvo)
    ?.  =(timer `(slav %da t.pole))  cor
    =?  cor  ?=(^ error.sign-arvo)
      %-  (slog leaf+"%accountability: timer error" u.error.sign-arvo)
      cor
    =.  cor  (set-timer (add now.bowl interval))
    round
  ::
      [%probe who=@ %w ~]
    ?>  ?=([%clay %writ *] sign-arvo)
    (take-w (slav %p who.pole) p.sign-arvo)
  ::
      [%probe who=@ %z aeon=@ *]
    ?>  ?=([%clay %writ *] sign-arvo)
    (take-z (slav %p who.pole) (slav %ud aeon.pole) p.sign-arvo)
  ::
      [%probe who=@ %x aeon=@ *]
    ?>  ?=([%clay %writ *] sign-arvo)
    (take-x (slav %p who.pole) (slav %ud aeon.pole) p.sign-arvo)
  ==
::
++  round
  ^+  cor
  =/  prev  last
  =.  last  `now.bowl
  ::  after a long silence of our own, don't score galaxies against it
  ::
  =?  cor  ?&(?=(^ prev) (gth (sub now.bowl u.prev) (mul 3 interval)))
    (note our.bowl %gap (need prev))
  =?  prev  ?&(?=(^ prev) (gth (sub now.bowl u.prev) (mul 3 interval)))
    ~
  =/  who=@p  ~zod
  |-  ^+  cor
  ?:  =(256 who)  cor
  =.  cor  (tick who prev)
  $(who `@p`+(who))
::  +tick: one galaxy's share of a round
::
++  tick
  |=  [who=ship prev=(unit @da)]
  ^+  cor
  =/  gal  (~(gut by galaxies) who *galaxy)
  =/  new  (read-chain who)
  =/  breach=?
    ?&  ?=(^ chain.gal)
        ?=(^ new)
        !=(rift.u.chain.gal rift.u.new)
    ==
  =?  chain-log.gal  &(?=(^ new) !=(chain.gal new))
    [[now.bowl (need new)] chain-log.gal]
  =?  cor  ?&(?=(^ chain.gal) ?=(^ new))
    (note-chain who u.chain.gal u.new)
  =.  chain.gal    new
  =.  contact.gal  (last-contact who)
  =/  was  [up=up.gal since=since.gal]
  =?  gal  ?=(^ prev)  (score gal u.prev)
  =?  cor  ?&(?=(^ since.was) !=(up.was up.gal))
    %+  note  who
    ?:  up.gal  [%up (need since.was)]
    [%down (need since.was) heard.gal]
  ::  a breach resets the galaxy's Clay and orphans our flows
  ::
  =?  cor  breach  (cancel who gal)
  =?  gal  breach  gal(wait ~, draft ~, kids ~, missing ~)
  (send who gal)
::  +note-chain: log each field that changed on chain
::
++  note-chain
  |=  [who=ship old=chain new=chain]
  ^+  cor
  =?  cor  !=(rift.old rift.new)
    (note who %breach rift.old rift.new)
  =?  cor  !=(life.old life.new)
    (note who %rekey life.old life.new)
  ::  a Jael fallback carries no addresses, so moving to or from one
  ::  is not a transfer
  ::
  ?:  |(?=(%jael dominion.old) ?=(%jael dominion.new))  cor
  =?  cor  !=(owner.old owner.new)
    (note who %owner owner.old owner.new)
  =?  cor  !=(management.old management.new)
    (note who %management management.old management.new)
  cor
::  +score: tally whether .gal answered since .prev
::
++  score
  |=  [gal=galaxy prev=@da]
  ^-  galaxy
  ::  Ames sets last-contact when it first learns a peer, even one that
  ::  never answers, so only answers to our own probes count.
  ::
  =/  ok=?  ?~(heard.gal | (gte u.heard.gal prev))
  =/  d  (day now.bowl)
  =/  t  (~(gut by days.gal) d [up=0 all=0])
  =.  days.gal  (~(put by days.gal) d [?:(ok +(up.t) up.t) +(all.t)])
  =?  since.gal  |(?=(~ since.gal) !=(ok up.gal))  `now.bowl
  gal(up ok)
::  +send: probe .who unless a probe of that kind is in flight
::
++  send
  |=  [who=ship gal=galaxy]
  ^+  cor
  ?.  ?&(?=(^ chain.gal) !=(0 life.u.chain.gal))
    (save who gal)
  =/  w  (scot %p who)
  =/  ping=?  !(~(has by wait.gal) %ping)
  =/  read=?
    ?&  !(~(has by wait.gal) %w)
        ?|  ?=(~ missing.gal)
            (gte (sub now.bowl u.missing.gal) ~h6)
    ==  ==
  =/  =case
    ?^  missing.gal  da+now.bowl
    ?~  kids.gal  da+now.bowl
    ud+(add 1 aeon.u.kids.gal)
  =?  cor  ping
    (emit %pass /probe/[w]/ping %agent [who %ping] %poke %noun !>(~))
  =?  cor  read  (emit (warp who /probe/[w]/w %w case /))
  =?  wait.gal  ping  (~(put by wait.gal) %ping now.bowl)
  =?  wait.gal  read  (~(put by wait.gal) %w now.bowl)
  ::  A %z or %x read open for an hour while the galaxy answers other
  ::  probes has lost its answer; ask again on a fresh wire.
  ::
  =/  aeon=(unit @ud)  (bind draft.gal |=(d=draft aeon.d))
  =/  lost
    |=  p=?(%z %x)
    ^-  ?
    =/  sent  (~(get by wait.gal) p)
    ?&  ?=(^ aeon)
        ?=(^ sent)
        ?=(^ heard.gal)
        (gte (sub now.bowl u.sent) ~h1)
        (gth u.heard.gal u.sent)
    ==
  =/  rz  (lost %z)
  =/  rx  (lost %x)
  =/  a  ?~(aeon %$ (scot %ud u.aeon))
  =/  t  (scot %da now.bowl)
  =?  cor  rz  (emit (warp who /probe/[w]/z/[a]/[t] %z ud+(need aeon) /))
  =?  cor  rx  (emit (warp who /probe/[w]/x/[a]/[t] %x ud+(need aeon) /sys/kelvin))
  =?  wait.gal  rz  (~(put by wait.gal) %z now.bowl)
  =?  wait.gal  rx  (~(put by wait.gal) %x now.bowl)
  (save who gal)
::  +take-w: a %kids revision; read its hash and kelvin if it is new
::
++  take-w
  |=  [who=ship =riot:clay]
  ^+  cor
  =/  gal  (~(gut by galaxies) who *galaxy)
  =.  heard.gal  `now.bowl
  =.  wait.gal   (~(del by wait.gal) %w)
  ::  galaxies are untrusted, so a malformed answer reads as empty
  ::
  =/  cas=(unit cass:clay)
    ?~  riot  ~
    (mole |.(;;(cass:clay q.q.r.u.riot)))
  ?~  cas
    (save who gal(missing `now.bowl))
  =/  cas  u.cas
  =.  missing.gal  ~
  =/  new=?
    ?&  !=(`ud.cas (bind kids.gal |=(k=kids aeon.k)))
        !=(`ud.cas (bind draft.gal |=(d=draft aeon.d)))
    ==
  =/  w  (scot %p who)
  =/  a  (scot %ud ud.cas)
  =?  draft.gal  new  `[ud.cas da.cas ~ ~]
  =?  cor  new  (emit (warp who /probe/[w]/z/[a] %z ud+ud.cas /))
  =?  cor  new  (emit (warp who /probe/[w]/x/[a] %x ud+ud.cas /sys/kelvin))
  =?  wait.gal  new
    (~(gas by wait.gal) ~[[%z now.bowl] [%x now.bowl]])
  ::  wait for the revision after this one
  ::
  =.  cor  (emit (warp who /probe/[w]/w %w ud+(add 1 ud.cas) /))
  =.  wait.gal  (~(put by wait.gal) %w now.bowl)
  (save who gal)
::
++  take-z
  |=  [who=ship aeon=@ud =riot:clay]
  ^+  cor
  =/  gal  (~(gut by galaxies) who *galaxy)
  =.  heard.gal  `now.bowl
  ?.  ?&(?=(^ draft.gal) =(aeon aeon.u.draft.gal))
    (save who gal)
  =.  wait.gal  (~(del by wait.gal) %z)
  =.  hash.u.draft.gal
    :-  ~
    ?~  riot  0v0
    (fall (mole |.(;;(@uvI q.q.r.u.riot))) 0v0)
  (finish who gal)
::
++  take-x
  |=  [who=ship aeon=@ud =riot:clay]
  ^+  cor
  =/  gal  (~(gut by galaxies) who *galaxy)
  =.  heard.gal  `now.bowl
  ?.  ?&(?=(^ draft.gal) =(aeon aeon.u.draft.gal))
    (save who gal)
  =.  wait.gal  (~(del by wait.gal) %x)
  =.  kelvin.u.draft.gal
    :-  ~
    ?~  riot  ~
    (fall (mole |.((waft-to-wefts:clay ;;(waft:clay q.q.r.u.riot)))) ~)
  (finish who gal)
::  +finish: commit .gal's draft if complete; log an OTA if it is new
::
::    We compare against the last revision logged, not .kids, which a
::    breach clears.
::
++  finish
  |=  [who=ship gal=galaxy]
  ^+  cor
  =/  old=(unit kids)  ?~(kids-log.gal ~ `kids.i.kids-log.gal)
  =.  gal  (commit gal)
  =/  new=(unit kids)  ?~(kids-log.gal ~ `kids.i.kids-log.gal)
  =?  cor  ?&(?=(^ old) ?=(^ new) !=(old new))
    (note who %ota (need old) (need new))
  (save who gal)
::  +commit: promote a finished draft to .kids
::
++  commit
  |=  gal=galaxy
  ^-  galaxy
  ?~  draft.gal  gal
  ?~  hash.u.draft.gal  gal
  ?~  kelvin.u.draft.gal  gal
  =/  k=kids
    [aeon.u.draft.gal date.u.draft.gal u.hash.u.draft.gal u.kelvin.u.draft.gal]
  gal(kids `k, kids-log [[now.bowl k] kids-log.gal], draft ~)
::
++  cancel
  |=  [who=ship gal=galaxy]
  ^+  cor
  ?.  (~(has by wait.gal) %w)  cor
  (emit %pass /probe/(scot %p who)/w %arvo %c %warp who %kids ~)
::
++  warp
  |=  [who=ship =wire =care:clay =case =path]
  ^-  card
  [%pass wire %arvo %c %warp who %kids `[%sing care case path]]
::
++  save
  |=  [who=ship gal=galaxy]
  ^+  cor
  cor(galaxies (~(put by galaxies) who gal))
::
++  read-chain
  |=  who=ship
  ^-  (unit chain)
  =+  [our=(scot %p our.bowl) now=(scot %da now.bowl) her=(scot %p who)]
  =/  pon=(unit point)
    ?.  .^(? %gu /[our]/azimuth/[now]/$)  ~
    ;;((unit point) .^(* %gx /[our]/azimuth/[now]/point/[her]/noun))
  ?^  pon
    :-  ~
    :*  life.keys.net.u.pon
        rift.net.u.pon
        dominion.u.pon
        address.owner.own.u.pon
        address.management-proxy.own.u.pon
    ==
  =/  lyf  .^((unit @ud) %j /[our]/lyfe/[now]/[her])
  =/  ryf  .^((unit @ud) %j /[our]/ryft/[now]/[her])
  ?:  |(?=(~ lyf) ?=(~ ryf))  ~
  `[u.lyf u.ryf %jael 0x0 0x0]
::
++  last-contact
  |=  who=ship
  ^-  (unit @da)
  =+  [our=(scot %p our.bowl) now=(scot %da now.bowl) her=(scot %p who)]
  .^((unit @da) %ax /[our]//[now]/peers/[her]/last-contact)
--
