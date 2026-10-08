pragma Ada_2022;
--  Own tests for Dutch_National_Flag (see tests/SOURCES.txt).
--  Sort must return the same colours (same count of 0, 1 and 2) in non-decreasing order.
with Ada.Text_IO; use Ada.Text_IO;
with Dutch_National_Flag; use Dutch_National_Flag;

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
   type Tally is array (Color) of Natural;
   function Count_Of (A : Color_Array) return Tally is
      T : Tally := [others => 0];
   begin
      for X of A loop T (X) := T (X) + 1; end loop;
      return T;
   end Count_Of;
begin
   for Code in 0 .. 3 ** Length - 1 loop
      declare
         A : Color_Array;
         R : Color_Array;
         V : Natural := Code;
         Ok : Boolean := True;
      begin
         for I in Index loop A (I) := V mod 3; V := V / 3; end loop;
         R := Sort (A);
         for I in 2 .. Length loop Ok := Ok and then R (I - 1) <= R (I); end loop;
         Report (Ok and then Count_Of (R) = Count_Of (A), "code" & Integer'Image (Code));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
