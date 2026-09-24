with Max_Points_On_A_Line_Lite; use Max_Points_On_A_Line_Lite;
procedure Tests with SPARK_Mode => Off is
   A : constant Point := (X => 0, Y => 0);
   B : constant Point := (X => 1, Y => 1);
   C : constant Point := (X => 2, Y => 2);
   D : constant Point := (X => 2, Y => 1);
begin
   pragma Assert (Max_Collinear (A, B, C) = 3);
   pragma Assert (Max_Collinear (A, B, D) = 2);
end Tests;
