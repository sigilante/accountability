::  /sur/accountability: what we record about each galaxy
::
|%
::  +chain: a galaxy's Azimuth state, as our ship sees it
::
::    .dominion is %jael when the %azimuth agent had no point for the
::    galaxy and we read life and rift from Jael instead; .owner and
::    .management are then 0x0.
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
      contact=(unit @da)                    ::  Ames last-contact
      heard=(unit @da)                      ::  last answer to any probe
      up=?                                  ::  answered in the last round
      since=(unit @da)                      ::  when .up last changed
      days=(map @da tally)                  ::  keyed by UTC midnight
      kids=(unit kids)
      kids-log=(list [at=@da =kids])        ::  revisions seen, newest first
      draft=(unit draft)
      missing=(unit @da)                    ::  when %kids last read as empty
      wait=(map probe @da)                  ::  in flight, by send time
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
+$  action
  $%  [%interval t=@dr]                     ::  time between rounds
      [%round ~]                            ::  run a round now
      [%reset who=(unit ship)]              ::  drop waits; ~ for all
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
