::  /lib/accountability: reachability tallies and JSON
::
::    JSON times are Unix milliseconds; .interval is seconds; addresses
::    are 0x and 40 lowercase hex digits; hashes are @uv text (0v...).
::
/-  *accountability
|%
::  +day: UTC midnight on or before .t
::
++  day
  |=  t=@da
  ^-  @da
  (sub t (mod t ~d1))
::  +uptime: rounds answered over the last .n UTC calendar days, today
::  included.  n=1 is today only, not the trailing 24 hours.
::
++  uptime
  |=  [days=(map @da tally) now=@da n=@ud]
  ^-  tally
  =/  floor=@da  (sub (day now) (mul (dec n) ~d1))
  %+  roll  ~(tap by days)
  |=  [[d=@da t=tally] acc=tally]
  ?:  (lth d floor)  acc
  [(add up.acc up.t) (add all.acc all.t)]
::
++  to-json
  =,  enjs:format
  |%
  ::  +galaxies: every galaxy, without history
  ::
  ++  galaxies
    |=  [now=@da our=@p interval=@dr last=(unit @da) gals=(map @p galaxy)]
    ^-  json
    %-  pairs
    :~  now+(time now)
        round+(en-time last)
        observer+s+(scot %p our)
        interval+(numb (div interval ~s1))
        :-  %galaxies
        :-  %a
        %+  turn
          %+  sort  ~(tap by gals)
          |=([a=[@p galaxy] b=[@p galaxy]] (lth -.a -.b))
        |=([who=@p gal=galaxy] (summary now who gal))
    ==
  ::  +detail: one galaxy, with daily tallies and change logs
  ::
  ++  detail
    |=  [now=@da who=@p gal=galaxy evs=(list event)]
    ^-  json
    =/  sum  (summary now who gal)
    ?>  ?=(%o -.sum)
    :-  %o
    %-  ~(gas by p.sum)
    :~  ['events' (events evs)]
        :-  'days'
        :-  %a
        %+  turn
          %+  sort  ~(tap by days.gal)
          |=([a=[@da tally] b=[@da tally]] (lth -.a -.b))
        |=  [d=@da t=tally]
        (pairs ~[day+(time d) up+(numb up.t) all+(numb all.t)])
      ::
        :-  'kidsLog'
        :-  %a
        %+  turn  kids-log.gal
        |=([at=@da k=kids] (pairs ~[at+(time at) kids+(en-kids k)]))
      ::
        :-  'chainLog'
        :-  %a
        %+  turn  chain-log.gal
        |=([at=@da c=chain] (pairs ~[at+(time at) chain+(en-chain c)]))
    ==
  ::
  ::  +events: newest first
  ::
  ++  events
    |=  evs=(list event)
    ^-  json
    a+(turn evs en-event)
  ::
  ++  en-event
    |=  e=event
    ^-  json
    =*  c  change.e
    %-  pairs
    %+  welp
      ^-  (list [@t json])
      ~[at+(time at.e) ship+s+(scot %p who.e) type+s+-.c]
    ^-  (list [@t json])
    ?-  -.c
      %up          ~[since+(time since.c)]
      %down        ~[since+(time since.c) last+(en-time last.c)]
      %breach      ~[from+(numb from.c) to+(numb to.c)]
      %rekey       ~[from+(numb from.c) to+(numb to.c)]
      %owner       ~[from+(en-address from.c) to+(en-address to.c)]
      %management  ~[from+(en-address from.c) to+(en-address to.c)]
      %ota         ~[from+(en-kids from.c) to+(en-kids to.c)]
      %gap         ~[from+(time from.c)]
    ==
  ::
  ++  summary
    |=  [now=@da who=@p gal=galaxy]
    ^-  json
    %-  pairs
    :~  ship+s+(scot %p who)
        chain+?~(chain.gal ~ (en-chain u.chain.gal))
        contact+(en-time contact.gal)
        heard+(en-time heard.gal)
        up+b+up.gal
        since+(en-time since.gal)
        kids+?~(kids.gal ~ (en-kids u.kids.gal))
        missing+(en-time missing.gal)
        :-  'wait'
        %-  pairs
        %+  turn  ~(tap by wait.gal)
        |=([p=probe t=@da] [`@t`p (time t)])
      ::
        :-  'uptime'
        %-  pairs
        :~  day+(en-tally (uptime days.gal now 1))
            week+(en-tally (uptime days.gal now 7))
            month+(en-tally (uptime days.gal now 30))
        ==
    ==
  ::
  ++  en-chain
    |=  c=chain
    ^-  json
    %-  pairs
    :~  life+(numb life.c)
        rift+(numb rift.c)
        dominion+s+dominion.c
        owner+(en-address owner.c)
        management+(en-address management.c)
    ==
  ::
  ++  en-kids
    |=  k=kids
    ^-  json
    %-  pairs
    :~  aeon+(numb aeon.k)
        date+(time date.k)
        hash+s+(scot %uv hash.k)
        :-  'kelvin'
        :-  %a
        %+  turn  ~(tap in kelvin.k)
        |=(w=weft (pairs ~[lal+s+lal.w num+(numb num.w)]))
    ==
  ::
  ++  en-tally
    |=  t=tally
    ^-  json
    (pairs ~[up+(numb up.t) all+(numb all.t)])
  ::
  ++  en-address
    |=  a=@ux
    ^-  json
    s+(crip (weld "0x" ((x-co:co 40) a)))
  ::
  ++  en-time
    |=  t=(unit @da)
    ^-  json
    ?~(t ~ (time u.t))
  --
--
