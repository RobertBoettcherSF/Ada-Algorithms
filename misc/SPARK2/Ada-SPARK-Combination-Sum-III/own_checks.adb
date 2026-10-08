--  Own tests for Combination_Sum_III (see tests/SOURCES.txt).
--  Feasible (K, N): some set of K distinct digits 1 .. 9 sums to N; Count_Choices (K, N): how many
--  such sets. Reference: own enumeration of all 2**9 subsets.
with Ada.Text_IO; use Ada.Text_IO;
with Combination_Sum_III; use Combination_Sum_III;

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
   function Brute (K : Combination_Sum_III.Count; N : Target) return Natural is
      Found : Natural := 0;
   begin
      for Mask in 0 .. 2**9 - 1 loop
         declare
            Size, Sum : Natural := 0;
         begin
            for D in 1 .. 9 loop
               if (Mask / 2**(D - 1)) mod 2 = 1 then Size := Size + 1; Sum := Sum + D; end if;
            end loop;
            if Size = K and then Sum = N then Found := Found + 1; end if;
         end;
      end loop;
      return Found;
   end Brute;
begin
   for K in Combination_Sum_III.Count loop
      for N in Target loop
         Report (Feasible (K, N) = (Brute (K, N) > 0), "feasible" & Integer'Image (K) & Integer'Image (N));
         Report (Count_Choices (K, N) = Brute (K, N), "count" & Integer'Image (K) & Integer'Image (N));
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
