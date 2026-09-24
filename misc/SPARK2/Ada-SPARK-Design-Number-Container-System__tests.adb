pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO; with Design_Number_Container_System; use Design_Number_Container_System;
procedure Tests is C : Container; V : Integer;
begin Initialize (C); Add (C, 7); Add (C, 11); Assert (Contains (C, 7) and then Length (C) = 2); Remove_Last (C, V); Assert (V = 11 and then not Contains (C, 11)); Put_Line ("PASS number container"); end Tests;
