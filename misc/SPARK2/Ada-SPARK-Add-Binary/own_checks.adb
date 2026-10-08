--  Own tests for Add_Binary (see tests/SOURCES.txt).
--  Add on 8-character "0"/"1" buffers = binary addition modulo 2**8 (README: overflow is discarded).
with Ada.Text_IO; use Ada.Text_IO;
with Add_Binary; use Add_Binary;

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
   function To_Bits (V : Natural) return Bits is
      R : Bits;
      X : Natural := V;
   begin
      for I in reverse Index loop
         R (I) := (if X mod 2 = 1 then '1' else '0');
         X := X / 2;
      end loop;
      return R;
   end To_Bits;
begin
   for A in 0 .. 255 loop
      for B in 0 .. 255 loop
         Report (Add (To_Bits (A), To_Bits (B)) = To_Bits ((A + B) mod 256),
                 "add" & Integer'Image (A) & Integer'Image (B));
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
