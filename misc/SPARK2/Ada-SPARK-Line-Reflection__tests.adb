with Line_Reflection; use Line_Reflection;
procedure Tests with SPARK_Mode => Off is
begin
   pragma Assert (Is_Reflection (0, -3, 2, 3, 2));
   pragma Assert (not Is_Reflection (0, -3, 2, 2, 2));
end Tests;
