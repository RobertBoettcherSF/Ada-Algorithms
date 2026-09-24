with Ada.Assertions; use Ada.Assertions;
with Excel_Sheet_Column_Number; use Excel_Sheet_Column_Number;

procedure Tests is
begin
   Assert (Number (" A") = 1);
   Assert (Number (" Z") = 26);
   Assert (Number ("AB") = 28);
   Assert (Number ("ZZ") = 702);
end Tests;
