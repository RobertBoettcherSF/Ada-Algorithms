pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO; with Time_Based_Key_Value_Store; use Time_Based_Key_Value_Store;
procedure Tests is
begin Initialize; Put (2, 44, 10); Assert (Get (2, 9) = 0); Assert (Get (2, 10) = 44); Put (2, 52, 20); Assert (Get (2, 20) = 52); Put_Line ("PASS time based store"); end Tests;
