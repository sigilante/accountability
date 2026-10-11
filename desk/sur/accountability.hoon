::  /sur/accountability: what we record about each galaxy
::
|%
::  +chain: a galaxy's Azimuth state, as our ship sees it
::
::    .dominion is %jael when the %azimuth agent had no point for the
::    galaxy and we read life and rift from Jael instead; .owner and
::    .management are then 0x0 and mean nothing.  Otherwise 0x0 is a
::    real unset address.
::
+$  chain
  $:  life=@ud
      rift=@ud
      dominion=@tas
      owner=@ux
      management=@ux
  ==
::  +kids: a galaxy's %kids desk at one revision
::
::    .date is the commit time the galaxy reports.  .hash is the %cz
::    hash that +vats prints, or 0v0 if the read was refused.  .kelvin
::    is empty if /sys/kelvin was missing or unreadable.
::
+$  kids
  $:  aeon=@ud
      date=@da
      hash=@uvI
      kelvin=(set weft)
  ==
::  +draft: a %kids revision whose hash and kelvin are still in flight
::
+$  draft
  $:  aeon=@ud
      date=@da
      hash=(unit @uvI)
      kelvin=(unit (set weft))
  ==
::  +probe: a request we send a galaxy
::
::    %ping pokes its %ping agent.  %w, %z, and %x are Clay reads of
::    its %kids desk: revision, hash, and /sys/kelvin.
::
+$  probe  ?(%ping %w %z %x)
::  +tally: rounds in which a galaxy answered, out of all rounds
::
+$  tally  [up=@ud all=@ud]
::
+$  galaxy
  $:  chain=(unit chain)
      chain-log=(list [at=@da =chain])      ::  changes seen, newest first
      contact=(unit @da)                    ::  Ames last-contact; Ames
                                            ::  sets it on first send, so
                                            ::  it is not scored
      heard=(unit @da)                      ::  last answer to any probe
      up=?                                  ::  answered in the last
                                            ::  scored round
      since=(unit @da)                      ::  when .up last changed, or
                                            ::  first scored; ~ = unscored
      days=(map @da tally)                  ::  keyed by UTC midnight
      kids=(unit kids)
      kids-log=(list [at=@da =kids])        ::  revisions seen, newest first
      draft=(unit draft)
      missing=(unit @da)                    ::  when %kids last read as
                                            ::  empty or malformed
      wait=(map probe @da)                  ::  open requests, by send
                                            ::  time; %w is a standing
                                            ::  watch for the next commit
  ==
::  +event: a change we observed, stamped with when we saw it
::
::    The first observation of a galaxy is its baseline and makes no
::    event; only later changes do.
::
+$  event  [at=@da who=ship =change]
+$  change
  $%  [%up since=@da]                       ::  answered; down since .since
      [%down since=@da last=(unit @da)]     ::  silent; up since .since,
                                            ::  last answer at .last
      [%breach from=@ud to=@ud]             ::  rift
      [%rekey from=@ud to=@ud]              ::  life
      [%owner from=@ux to=@ux]
      [%management from=@ux to=@ux]
      [%ota from=kids to=kids]              ::  new %kids revision
      [%gap from=@da]                       ::  .who is us: we ran no
                                            ::  rounds since .from
  ==
::
::  +report: what an observer tells its peers, as a %noun fact
::
::    .at is when its last round started, and .up is each scored
::    galaxy's state as of that round.  .days holds its tallies from
::    one UTC day on.  The sender is the Ames-authenticated source of
::    the fact, so the report does not name it.
::
+$  report
  $:  %0
      at=(unit @da)
      up=(list [who=@p up=?])
      days=(list [on=@da who=@p =tally])
  ==
::  +peer: an observer on our whitelist, and what it has told us
::
+$  peer
  $:  heard=(unit @da)                      ::  when its last report came
      nack=(unit @da)                       ::  when it last refused our
                                            ::  subscription; ~ once it
                                            ::  accepts
      round=(unit @da)                      ::  its last round
      up=(map ship ?)                       ::  as of .round
      days=(map ship (map @da tally))       ::  by galaxy, then UTC day
  ==
::
+$  action
  $%  [%interval t=@dr]                     ::  time between rounds
      [%round ~]                            ::  run a round now
      [%reset who=(unit ship)]              ::  drop probes and draft,
                                            ::  cancel the %kids watch;
                                            ::  ~ for all galaxies
      [%peer who=ship ok=?]                 ::  add to or drop from the
                                            ::  whitelist
      [%fill who=ship since=@da]            ::  ask a peer again for its
                                            ::  tallies from .since on
  ==
::  +point: a copy of +point:naive, to read the %azimuth agent
::
+$  point
  $:  dominion=?(%l1 %l2 %spawn)
      $=  own
      $:  owner=[address=@ux nonce=@ud]
          spawn-proxy=[address=@ux nonce=@ud]
          management-proxy=[address=@ux nonce=@ud]
          voting-proxy=[address=@ux nonce=@ud]
          transfer-proxy=[address=@ux nonce=@ud]
      ==
      $=  net
      $:  rift=@ud
          keys=[life=@ud suite=@ud auth=@ crypt=@]
          sponsor=[has=? who=@p]
          escape=(unit @p)
      ==
  ==
--
