pragma Ada_2022;
--  Own tests for Sieve_Of_Eratosthenes (see tests/SOURCES.txt).
--  Sieve and Is_Prime against own trial division for every number 1 .. Capacity.
with Ada.Text_IO; use Ada.Text_IO;
with Sieve_Of_Eratosthenes; use Sieve_Of_Eratosthenes;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
begin
   declare
      R : Flags;
   begin
      Sieve (R);
      for N in Number loop
         declare
            P : Boolean := N >= 2;
         begin
            for D in 2 .. N - 1 loop
               if N mod D = 0 then P := False; end if;
            end loop;
            Report (R (N) = P, "Sieve" & N'Image);
            Report (Is_Prime (N) = P, "Is_Prime" & N'Image);
         end;
      end loop;
   end;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
