with Sqrt_Integer;
procedure Tests is
begin
   pragma Assert (Sqrt_Integer.Floor_Sqrt (0) = 0);
   pragma Assert (Sqrt_Integer.Floor_Sqrt (8) = 2);
   pragma Assert (Sqrt_Integer.Floor_Sqrt (99) = 9);
   pragma Assert (Sqrt_Integer.Floor_Sqrt (100) = 10);
end Tests;
