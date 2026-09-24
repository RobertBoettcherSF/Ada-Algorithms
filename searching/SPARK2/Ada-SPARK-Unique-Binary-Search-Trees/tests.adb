with Unique_Binary_Search_Trees;
procedure Tests is
   use Unique_Binary_Search_Trees;
begin
   pragma Assert (Number_Of_Trees (0) = 1);
   pragma Assert (Number_Of_Trees (3) = 5);
   pragma Assert (Number_Of_Trees (16) = 35357670);
end Tests;
