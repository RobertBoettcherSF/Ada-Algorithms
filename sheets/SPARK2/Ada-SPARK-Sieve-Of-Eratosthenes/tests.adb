pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Sieve_Of_Eratosthenes; use Sieve_Of_Eratosthenes;
procedure Tests is
   Result : Flags;
begin
   Sieve (Result);
   Assert (Result (2));
   Assert (Result (3));
   Assert (not Result (1));
   Assert (not Result (9));
   Assert (Result (19));
   Put_Line ("PASS Sieve_Of_Eratosthenes");
end Tests;
