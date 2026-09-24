with Delete_And_Earn;
procedure Tests is
begin
   pragma Assert (Delete_And_Earn.Maximum (1) = 1);
   pragma Assert (Delete_And_Earn.Maximum (6) = 12);
   pragma Assert (Delete_And_Earn.Maximum (16) = 72);
end Tests;
