with Triangle;
procedure Tests is
begin
   pragma Assert (Triangle.Minimum_Path (0) = 0);
   pragma Assert (Triangle.Minimum_Path (1) = 1);
   pragma Assert (Triangle.Minimum_Path (16) = 16);
end Tests;
