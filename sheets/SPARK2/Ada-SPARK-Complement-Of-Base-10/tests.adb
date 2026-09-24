with Complement_Of_Base_10; use Complement_Of_Base_10;
procedure Tests is
begin
   pragma Assert (Complement (123) = 876);
   pragma Assert (Complement (999) = 0);
end Tests;
