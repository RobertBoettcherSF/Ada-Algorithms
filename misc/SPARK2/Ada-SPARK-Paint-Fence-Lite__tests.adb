with Paint_Fence_Lite;
procedure Tests is
begin
   pragma Assert (Paint_Fence_Lite.Count (1) = 2);
   pragma Assert (Paint_Fence_Lite.Count (4) = 10);
   pragma Assert (Paint_Fence_Lite.Count (16) = 3_194);
end Tests;
