--  Own tests for Combination_Sum_IV (see tests/SOURCES.txt).
--  Count_Ordered_Ways (N) = number of ordered sequences of parts from {1, 2, 3} summing to N;
--  reference: own recursive enumeration.
with Ada.Text_IO; use Ada.Text_IO;
with Combination_Sum_IV; use Combination_Sum_IV;

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
   function Enumerate (Rest : Integer) return Natural is
   begin
      if Rest = 0 then return 1; elsif Rest < 0 then return 0; end if;
      return Enumerate (Rest - 1) + Enumerate (Rest - 2) + Enumerate (Rest - 3);
   end Enumerate;
begin
   for N in Target loop
      Report (Count_Ordered_Ways (N) = Enumerate (N), "target" & Integer'Image (N));
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
