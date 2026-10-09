pragma Ada_2022;
with Ada.Text_IO;
with Sqrt_X; use Sqrt_X;
with Own_Checks;
procedure Tests with SPARK_Mode => Off is
   --  Integer Newton (Heron) iteration X := (X + N / X) / 2 from the fixed
   --  start X = 46340 (floor of the square root of Natural'Last), stopping
   --  when X reaches 0 or a step no longer lowers X. Exact step counts,
   --  with the X sequence worked step by step:
   --    N = 0:   46340 23170 11585 5792 2896 1448 724 362 181 90 45 22 11
   --             5 2 1 0 (16 lowering steps, then X = 0): 16
   --    N = 4:   ... 22 11 5 2, then (2 + 2) / 2 = 2 does not lower: 15
   --    N = 15:  ... 22 11 6 4 3, then (3 + 5) / 2 = 4 >= 3: 16
   --    N = 99:  ... 45 23 13 10 9, then (9 + 11) / 2 = 10 >= 9: 15
   --    N = 100: ... 45 23 13 10, then (10 + 10) / 2 = 10: 14
   --  ("..." is the N = 0 prefix 46340 .. 90: N / X = 0 or 1 there, so
   --  the halvings agree up to 90 -> 45; from 45 on N / X matters.)
   procedure Check (N : Number; Want, Steps : Natural) is
      R : constant Sqrt_Result := Sqrt (N);
   begin
      if R.Root /= Want or else R.Steps /= Steps then
         raise Program_Error with "N =" & N'Image & ": root" & R.Root'Image
           & ", steps" & R.Steps'Image & " (expected root" & Want'Image & "," & Steps'Image & " steps)";
      end if;
   end Check;
begin
   Check (0, 0, 16);
   Check (4, 2, 15);
   Check (15, 3, 16);
   Check (99, 9, 15);
   Check (100, 10, 14);
   Own_Checks;
   Ada.Text_IO.Put_Line ("PASS Sqrt_X");
end Tests;
