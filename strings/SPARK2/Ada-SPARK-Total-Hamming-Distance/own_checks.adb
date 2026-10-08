--  Own tests for Total_Hamming_Distance (see tests/SOURCES.txt).
--  Distance must count the bit positions where Left and Right differ.
pragma Ada_2022;
with Ada.Text_IO;
with Interfaces;
with Total_Hamming_Distance; use Total_Hamming_Distance;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   Seed : Long_Long_Integer := 20_261_008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Long_Long_Integer (Lo)
                      + Seed mod (Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1));
   end Next;

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


   use type Interfaces.Unsigned_32;
   function Ref (L, R : Word) return Natural is
      N : Natural := 0;
   begin
      for B in 0 .. 31 loop
         if ((L / 2 ** B) mod 2) /= ((R / 2 ** B) mod 2) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Ref;
   L, R : Word;
begin
   Report (Distance (0, Word'Last) = Ref (0, Word'Last), "all bits");
   Report (Distance (Word'Last, Word'Last) = Ref (Word'Last, Word'Last), "equal");
   for B in 0 .. 31 loop
      Report (Distance (0, 2 ** B) = Ref (0, 2 ** B), "single bit" & B'Image);
   end loop;
   for K in 1 .. 5_000 loop
      L := Word (Next (0, Integer'Last)) * 2 + Word (Next (0, 1));
      R := Word (Next (0, Integer'Last)) * 2 + Word (Next (0, 1));
      Report (Distance (L, R) = Ref (L, R), "random" & K'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own bit-by-bit reference)");
end Own_Checks;
