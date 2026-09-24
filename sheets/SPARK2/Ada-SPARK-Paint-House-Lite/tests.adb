with Paint_House_Lite;
procedure Tests is
begin
   pragma Assert (Paint_House_Lite.Minimum (3, 2, 5) = 2);
   pragma Assert (Paint_House_Lite.Minimum (7, 4, 4) = 4);
   pragma Assert (Paint_House_Lite.Minimum (0, 6, 1) = 0);
end Tests;
