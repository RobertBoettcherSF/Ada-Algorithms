with Unique_Binary_Search_Trees_II_Lite;
procedure Tests is
   use Unique_Binary_Search_Trees_II_Lite;
begin
   pragma Assert (Root_Choices (0) = 0);
   pragma Assert (Root_Choices (1) = 1);
   pragma Assert (Root_Choices (16) = 16);
end Tests;
