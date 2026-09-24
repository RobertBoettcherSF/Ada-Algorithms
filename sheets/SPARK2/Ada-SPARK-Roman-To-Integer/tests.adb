with Ada.Assertions; use Ada.Assertions;
with Roman_To_Integer; use Roman_To_Integer;

procedure Tests is
begin
   Assert (Value_Of ("    I") = 1);
   Assert (Value_Of ("  VII") = 7);
   Assert (Value_Of ("   XV") = 15);
   Assert (Value_Of (" M V ") = 1_005);
end Tests;
