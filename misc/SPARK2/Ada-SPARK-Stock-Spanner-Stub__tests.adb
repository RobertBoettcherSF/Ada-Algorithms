pragma SPARK_Mode (On);
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Stock_Spanner_Stub; use Stock_Spanner_Stub;

procedure Tests is
   Prices : constant Price_Array := (100, 80, 60, 70, 60, 75, 85, 90);
begin
   Assert (Span (Prices, 1) = 1);
   Assert (Span (Prices, 4) = 2);
   Assert (Span (Prices, 6) = 4);
   Assert (Span (Prices, 8) = 7);
   Put_Line ("Stock Spanner: PASS");
end Tests;
