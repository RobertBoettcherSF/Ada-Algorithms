pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Max_Product_Subarray; use Max_Product_Subarray;

procedure Tests is
   A : constant Element_Array := (2, 3, -2, 4, -1, 2);
   B : constant Element_Array := (-2, 0, -1, 4, 3, -2);
begin
   if Compute (A) /= 96 or else Compute (B) /= 24 then raise Program_Error; end if;
   Put_Line ("Max product subarray: PASS");
end Tests;
