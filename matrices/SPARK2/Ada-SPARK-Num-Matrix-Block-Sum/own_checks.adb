--  Own tests for Num_Matrix_Block_Sum (see tests/SOURCES.txt).
--  Block_Sum (A, Row, Col, K) = sum of A (I, J) over |I - Row| <= K, |J - Col| <= K, clipped to the matrix.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Num_Matrix_Block_Sum; use Num_Matrix_Block_Sum;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := Long_Long_Integer (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & Long_Long_Integer'Image (S) & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed : Long_Long_Integer := AA_Seed (20261008);
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   M : Matrix;
begin
   for Trial in 1 .. 2_000 loop
      for I in Index loop
         for J in Index loop
            M (I, J) := (if Trial mod 3 = 0 then 9 else Next (0, 9));
         end loop;
      end loop;
      for R in Index loop
         for C in Index loop
            for K in Radius loop
               declare
                  S : Long_Long_Integer := 0;
               begin
                  for I in Index loop
                     for J in Index loop
                        if abs (I - R) <= K and then abs (J - C) <= K then
                           S := S + Long_Long_Integer (M (I, J));
                        end if;
                     end loop;
                  end loop;
                  Report (Block_Sum (M, R, C, K) = S, "block sum");
               end;
            end loop;
         end loop;
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
