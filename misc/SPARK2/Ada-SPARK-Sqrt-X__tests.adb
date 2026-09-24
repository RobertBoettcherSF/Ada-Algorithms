with Sqrt_X; use Sqrt_X;
procedure Tests with SPARK_Mode => Off is
begin
   pragma Assert (Floor_Sqrt (0) = 0);
   pragma Assert (Floor_Sqrt (15) = 3);
   pragma Assert (Floor_Sqrt (100) = 10);
end Tests;
