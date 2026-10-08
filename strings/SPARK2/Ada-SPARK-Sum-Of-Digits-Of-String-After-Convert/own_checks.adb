--  Own tests for Sum_Digits_Convert (see tests/SOURCES.txt).
--  Sum_Digits must return the sum of the decimal digits.
pragma Ada_2022;
with Ada.Text_IO;
with Sum_Digits_Convert; use Sum_Digits_Convert;

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


   function Ref (V : Number) return Natural is
      Img : constant String := V'Image;
      S   : Natural := 0;
   begin
      for C of Img loop
         if C in '0' .. '9' then
            S := S + (Character'Pos (C) - Character'Pos ('0'));
         end if;
      end loop;
      return S;
   end Ref;
begin
   for V in Number loop
      Report (Sum_Digits (V) = Ref (V), "value" & V'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own digit sum via decimal image, every input)");
end Own_Checks;
