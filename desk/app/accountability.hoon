::  /app/accountability: watch every galaxy
::
::    Each round, for each of the 256 galaxies, we:
::    - read its Azimuth point from %azimuth, or life and rift from Jael;
::    - read Ames's last contact with it;
::    - tally whether it answered anything since the previous round;
::    - poke its %ping agent, unless a poke is already in flight.
::
::    We also hold one Clay read open against each galaxy's %kids desk.
::    The first asks for %w at the current date, which returns the
::    latest revision.  Each later read asks for the revision after the
::    last one seen, so it answers only when the galaxy commits.  Each
::    new revision triggers a %z read (desk hash) and an %x read of
::    /sys/kelvin.
::
::    A probe to a dead galaxy never answers, so we never resend a
::    probe while one is in flight.  We resend when the galaxy's rift
::    changes, since a breach orphans its flows, or on a %reset poke.
::    Galaxies with no networking keys get no probes and tally as down.
::
::    Every change after a galaxy's first observation is logged as an
::    +event: liveness flips, breaches, rekeys, transfers, and OTAs.
::
::  scries:
::    .^((map ship galaxy:accountability) %gx /=accountability=/galaxies/noun)
::    .^((unit galaxy:accountability) %gx /=accountability=/galaxy/~zod/noun)
::    .^((list event:accountability) %gx /=accountability=/events/noun)
::
::  subscription, local only:
::    /events gives each new event as a %noun fact
::
::  HTTP, no login required:
::    GET /apps/accountability/galaxies.json
::    GET /apps/accountability/galaxy/~zod.json
::    GET /apps/accountability/events.json?ship=~zod&since=<ms>&before=<ms>&limit=500
::    GET /apps/accountability                    the dashboard
::
::  pokes:
::    :accountability &accountability-action [%interval ~m5]
::    :accountability &accountability-action [%round ~]
::    :accountability &accountability-action [%reset `~zod]
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
      ?~(who.action ~(tap in ~(key by galaxies)) ~[u.who.action])
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
    (json-out (galaxies:to-json now.bowl our.bowl interval galaxies))
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
    =/  since=(unit @da)
      %+  bind  (biff (~(get by arg) 'since') |=(t=@t (rush t dem)))
      from-unix-ms:chrono:userlib
    =/  before=(unit @da)
      %+  bind  (biff (~(get by arg) 'before') |=(t=@t (rush t dem)))
      from-unix-ms:chrono:userlib
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
++  select
  |=  [who=(unit ship) since=(unit @da) before=(unit @da) limit=@ud]
  ^-  (list event)
  =|  out=(list event)
  =/  n=@ud  0
  =/  evs  events
  |-  ^-  (list event)
  ?:  |(?=(~ evs) =(n limit))  (flop out)
  ?:  ?&(?=(^ since) (lte at.i.evs u.since))  (flop out)
  ?:  ?&(?=(^ before) (gte at.i.evs u.before))  $(evs t.evs)
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
      [%probe who=@ %z aeon=@ ~]
    ?>  ?=([%clay %writ *] sign-arvo)
    (take-z (slav %p who.pole) (slav %ud aeon.pole) p.sign-arvo)
  ::
      [%probe who=@ %x aeon=@ ~]
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
  (save who gal)
::  +take-w: a %kids revision; read its hash and kelvin if it is new
::
++  take-w
  |=  [who=ship =riot:clay]
  ^+  cor
  =/  gal  (~(gut by galaxies) who *galaxy)
  =.  heard.gal  `now.bowl
  =.  wait.gal   (~(del by wait.gal) %w)
  ?~  riot
    (save who gal(missing `now.bowl))
  =/  cas  ;;(cass:clay q.q.r.u.riot)
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
  =.  hash.u.draft.gal  `?~(riot 0v0 ;;(@uvI q.q.r.u.riot))
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
    `?~(riot ~ (waft-to-wefts:clay ;;(waft:clay q.q.r.u.riot)))
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
