pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Guess_Number_Higher_Or_Lower; use Guess_Number_Higher_Or_Lower;

procedure Tests is
   R : Result;
begin
   --  1 .. 32 halves at 16, 24, 20, 22, 23: five guesses for 23.
   R := Guess_Number (32, 23);
   Assert (R.Answer = 23 and then R.Probes = 5);
   --  16 is the first guess.
   R := Guess_Number (32, 16);
   Assert (R.Answer = 16 and then R.Probes = 1);
   --  32 needs the sixth guess (16, 24, 28, 30, 31, 32).
   R := Guess_Number (32, 32);
   Assert (R.Answer = 32 and then R.Probes = 6);
   --  1 .. 1: one guess.
   R := Guess_Number (1, 1);
   Assert (R.Answer = 1 and then R.Probes = 1);
   --  1 .. 10, secret 1: guesses 5, 2, 1.
   R := Guess_Number (10, 1);
   Assert (R.Answer = 1 and then R.Probes = 3);
   Put_Line ("PASS Guess_Number_Higher_Or_Lower");
end Tests;
