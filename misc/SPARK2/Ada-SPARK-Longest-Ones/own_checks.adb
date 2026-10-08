pragma Ada_2022;
--  Own tests for Longest_Ones (see tests/SOURCES.txt).
--  Find (Bits, Flips): longest window of Bits containing at most Flips zeros; exhaustive.
with Ada.Text_IO; use Ada.Text_IO;
with Longest_Ones; use Longest_Ones;

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
   A : Bit_Array;
begin
   for Code in 0 .. 255 loop
      for I in Index loop A (I) := (Code / 2**(I - 1)) mod 2; end loop;
      for K in Longest_Ones.Count loop
         declare
            Best, Z : Natural := 0;
         begin
            for S in Index loop
               for E in S .. Index'Last loop
                  Z := 0;
                  for P in S .. E loop
                     if A (P) = 0 then Z := Z + 1; end if;
                  end loop;
                  if Z <= K then Best := Natural'Max (Best, E - S + 1); end if;
               end loop;
            end loop;
            Report (Find (A, K) = Best, "bits" & Integer'Image (Code) & " K" & Integer'Image (K));
         end;
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
