pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Delete_And_Earn_Stub; use Delete_And_Earn_Stub;

procedure Tests is
   Values : constant Value_Array := (3, 4, 2, 3, 3, 4);
begin
   if Compute (Values) /= 10 then raise Program_Error; end if;
   Put_Line ("Delete and earn stub: PASS");
end Tests;
