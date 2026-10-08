--  Own tests for Add_Without_Plus (see tests/SOURCES.txt).
--  Add (L, R) = L + R for every pair of operands.
with Ada.Text_IO; use Ada.Text_IO;
with Add_Without_Plus; use Add_Without_Plus;

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
   for L in Operand loop
      for R in Operand loop
         Report (Add (L, R) = L + R, "add" & Integer'Image (L) & Integer'Image (R));
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
