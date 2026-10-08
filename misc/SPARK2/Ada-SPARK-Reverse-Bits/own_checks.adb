--  Own tests for Reversed_Bits (see tests/SOURCES.txt).
--  Reversed must mirror the 8 bits of every byte.
pragma Ada_2022;
with Ada.Text_IO;
with Reversed_Bits; use Reversed_Bits;

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

   function Ref (V : Byte) return Byte is
      R : Byte := 0;
   begin
      for B in 0 .. 7 loop
         if (V / 2 ** B) mod 2 = 1 then
            R := R + 2 ** (7 - B);
         end if;
      end loop;
      return R;
   end Ref;
begin
   for V in Byte loop
      Report (Reversed (V) = Ref (V), "byte" & V'Image);
      Report (Reversed (Reversed (V)) = V, "involution" & V'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own bit-mirror reference, exhaustive)");
end Own_Checks;
