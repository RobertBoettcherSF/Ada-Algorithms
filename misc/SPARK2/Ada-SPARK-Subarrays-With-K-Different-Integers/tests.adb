pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Subarrays_With_K_Different_Integers; use Subarrays_With_K_Different_Integers;
procedure Tests is
   A : constant Element_Array := (1, 2, 1, 2, 3, 3, 1, 2);
   B : constant Element_Array := (1, 1, 1, 1, 1, 1, 1, 1);
begin
   if Subarrays_With_K_Different_Integers.Count (A, 2) /= 11 then raise Program_Error; end if;
   if Subarrays_With_K_Different_Integers.Count (A, 1) /= 9 then raise Program_Error; end if;
   if Subarrays_With_K_Different_Integers.Count (B, 1) /= 36 then raise Program_Error; end if;
   Put_Line ("Subarrays with K different integers: PASS");
end Tests;
