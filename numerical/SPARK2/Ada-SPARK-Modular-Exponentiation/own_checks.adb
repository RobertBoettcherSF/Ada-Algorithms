--  Own tests for Modular_Exponentiation (see tests/SOURCES.txt).
--  Power (V, E, M) = V ** E mod M.
pragma Ada_2022;
with Ada.Text_IO;
with Modular_Exponentiation; use Modular_Exponentiation;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;


   function Ref (V, E, M : Natural) return Natural is
      R : Natural := 1 mod M;
   begin
      for I in 1 .. E loop
         R := (R * V) mod M;
      end loop;
      return R;
   end Ref;
begin
   for V in Base loop
      for E in Exponent loop
         for M in Modulus loop
            Report (Power (V, E, M) = Ref (V, E, M), "case");
         end loop;
      end loop;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own repeated-multiplication reference, exhaustive)");
end Own_Checks;
