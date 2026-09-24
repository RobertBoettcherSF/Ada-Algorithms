with Rectangle_Area; use Rectangle_Area;
procedure Tests with SPARK_Mode => Off is
begin
   pragma Assert (Area ((Width => 3, Height => 4)) = 12);
   pragma Assert (Area ((Width => 10, Height => 10)) = 100);
end Tests;
