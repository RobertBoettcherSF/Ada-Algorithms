with Ada.Assertions; use Ada.Assertions;
with Excel_Sheet_Column_Title; use Excel_Sheet_Column_Title;

procedure Tests is
begin
   Assert (Title (1) = " A");
   Assert (Title (26) = " Z");
   Assert (Title (27) = "AA");
   Assert (Title (52) = "AZ");
   Assert (Title (702) = "ZZ");
end Tests;
