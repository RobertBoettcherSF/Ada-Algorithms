with Unique_Paths;
procedure Tests is
begin
   pragma Assert (Unique_Paths.Count (1, 4) = 1);
   pragma Assert (Unique_Paths.Count (2, 4) = 4);
   pragma Assert (Unique_Paths.Count (3, 3) = 6);
   pragma Assert (Unique_Paths.Count (3, 4) = 10);
   pragma Assert (Unique_Paths.Count (4, 4) = 20);
end Tests;
