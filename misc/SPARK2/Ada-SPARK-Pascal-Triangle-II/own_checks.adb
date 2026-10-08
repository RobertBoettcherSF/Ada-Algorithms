--  Own tests for Pascal_Triangle_II.Get (written for this repository; see
--  tests/SOURCES.txt). Assumption: Get is wrong, saturates or does nothing.
--  Reference, different from the code's in-place row additions: the
--  multiplicative formula C(n, k) = C(n, k - 1) * (n - k + 1) / k in
--  Long_Long_Integer (no cap), plus two independent properties of every row:
--  symmetry and row sum 2**n. Columns beyond the row must give 0.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Pascal_Triangle_II; use Pascal_Triangle_II;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   procedure Fail (Msg : String) is
   begin
      Failures := Failures + 1;
      if Failures <= 10 then
         Put_Line ("FAIL Pascal_Triangle_II: " & Msg);
      end if;
   end Fail;
begin
   for N in Row_Index loop
      declare
         Want : Long_Long_Integer := 1;
         Sum  : Long_Long_Integer := 0;
      begin
         for K in Row_Index loop
            Cases := Cases + 1;
            if K > N then
               if Get (N, K) /= 0 then
                  Fail ("Get (" & N'Image & "," & K'Image & ") /= 0 beyond the row");
               end if;
            else
               if K > 0 then
                  Want := Want * Long_Long_Integer (N - K + 1) / Long_Long_Integer (K);
               end if;
               if Long_Long_Integer (Get (N, K)) /= Want then
                  Fail ("Get (" & N'Image & "," & K'Image & ") =" & Get (N, K)'Image & " want" & Want'Image);
               end if;
               if Get (N, K) /= Get (N, N - K) then
                  Fail ("row" & N'Image & " not symmetric at" & K'Image);
               end if;
               Sum := Sum + Long_Long_Integer (Get (N, K));
            end if;
         end loop;
         if Sum /= 2 ** N then
            Fail ("row" & N'Image & " sums to" & Sum'Image);
         end if;
      end;
   end loop;
   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image & " entries (multiplicative formula, symmetry, row sums)");
end Own_Checks;
