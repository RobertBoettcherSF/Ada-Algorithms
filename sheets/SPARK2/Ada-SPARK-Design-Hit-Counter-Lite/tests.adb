with Ada.Assertions; use Ada.Assertions;
with Design_Hit_Counter_Lite; use Design_Hit_Counter_Lite;
procedure Tests is C : Counter := Empty;
begin Hit (C, 2); Hit (C, 2); Hit (C, 4); Assert (Read (C, 2) = 2); Assert (Total (C) = 3); end Tests;
