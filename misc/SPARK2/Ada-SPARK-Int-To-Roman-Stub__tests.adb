with Ada.Assertions; use Ada.Assertions;
with Int_To_Roman_Stub; use Int_To_Roman_Stub;
procedure Tests is
begin
   Assert (To_Roman (3) = "III     ");
   Assert (To_Roman (14) = "XIV     ");
   Assert (To_Roman (20) = "XX      ");
end Tests;
