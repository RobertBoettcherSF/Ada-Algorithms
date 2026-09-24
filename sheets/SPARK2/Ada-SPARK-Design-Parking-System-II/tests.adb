with Ada.Text_IO; use Ada.Text_IO;
with Design_Parking_System_II; use Design_Parking_System_II;
procedure Tests is
   P : Parking := Create (1, 2, 1);
begin
   Add_Car (P, Medium); Add_Car (P, Large);
   if Remaining (P, Medium) /= 1 or else Remaining (P, Large) /= 0 then raise Program_Error; end if;
   Put_Line ("Design Parking System II: PASS");
end Tests;
