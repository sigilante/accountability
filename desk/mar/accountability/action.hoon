::  /mar/accountability/action
::
::    The sample is .act, not =action: a face named action would shadow
::    the mold, and +noun:grab must produce the mold.
::
/-  *accountability
|_  act=action
++  grab
  |%
  ++  noun  action
  --
++  grow
  |%
  ++  noun  act
  --
++  grad  %noun
--
