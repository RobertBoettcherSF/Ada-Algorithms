pragma Ada_2022;
--  Own checks for Target-Sum (V&V sweep, agent A3, 2026-10-09; see
--  tests/SOURCES.txt). Reference: enumerate all 2 ** N sign choices
--  (bit K of the mask set = minus sign on A (K)) and count those whose
--  signed sum equals Goal. Exhaustive: every array in 0 .. 4 ** 4 (625),
--  every N in 0 .. 4 and every Goal in -16 .. 16 (103,125 cases).
with Ada.Text_IO;
with Target_Sum; use Target_Sum;

procedure Own_Checks with SPARK_Mode => Off is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   function Reference (A : Values; N : Length; Goal : Target) return Natural is
      Ways : Natural := 0;
   begin
      for Mask in 0 .. 2 ** N - 1 loop
         declare
            Sum : Integer := 0;
         begin
            for K in 1 .. N loop
               if (Mask / 2 ** (K - 1)) mod 2 = 1 then
                  Sum := Sum - A (K);
               else
                  Sum := Sum + A (K);
               end if;
            end loop;
            if Sum = Goal then
               Ways := Ways + 1;
            end if;
         end;
      end loop;
      return Ways;
   end Reference;

   A : Values;
begin
   for Code in 0 .. 5 ** 4 - 1 loop
      for K in A'Range loop
         A (K) := (Code / 5 ** (K - 1)) mod 5;
      end loop;
      for N in Length loop
         for Goal in Target loop
            Checked := Checked + 1;
            if Ways_To_Target (A, N, Goal) /= Reference (A, N, Goal) then
               Failures := Failures + 1;
               if Failures <= 10 then
                  Ada.Text_IO.Put_Line
                    ("  FAIL own check: A =" & A'Image & " N =" & N'Image
                     & " Goal =" & Goal'Image & " expected"
                     & Reference (A, N, Goal)'Image);
               end if;
            end if;
         end loop;
      end loop;
   end loop;
   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
