pragma Ada_2022;
--  Own tests for Tribonacci (see tests/SOURCES.txt).
--  Compute: T0 = 0, T1 = T2 = 1, Tn = Tn-1 + Tn-2 + Tn-3 (own recursion), every N in the domain.
with Ada.Text_IO; use Ada.Text_IO;
with Tribonacci; use Tribonacci;

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
   function T (N : Natural) return Natural is
     (if N = 0 then 0 elsif N <= 2 then 1 else T (N - 1) + T (N - 2) + T (N - 3));
begin
   for N in Input loop
      Report (Compute (N) = T (N), "N" & Integer'Image (N));
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
