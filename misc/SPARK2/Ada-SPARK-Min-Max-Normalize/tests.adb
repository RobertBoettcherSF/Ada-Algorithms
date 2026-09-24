pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Min_Max_Normalize; use Min_Max_Normalize;

procedure Tests is
   Samples : constant Sample_Array := (1, 2, 3, 4, 5);
begin
   if Normalize (Samples, 1) /= 0 then raise Program_Error; end if;
   if Normalize (Samples, 3) /= 50 then raise Program_Error; end if;
   if Normalize (Samples, 5) /= 100 then raise Program_Error; end if;
   Put_Line ("Min_Max_Normalize: PASS");
end Tests;
