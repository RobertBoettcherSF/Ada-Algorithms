with Title_To_Number;
procedure Tests is
begin
   pragma Assert (Title_To_Number.Title_Number ('A') = 1);
   pragma Assert (Title_To_Number.Title_Number ('L') = 12);
   pragma Assert (Title_To_Number.Title_Number ('Z') = 26);
end Tests;
