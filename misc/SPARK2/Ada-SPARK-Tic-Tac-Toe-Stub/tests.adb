pragma SPARK_Mode (On);
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Tic_Tac_Toe_Stub; use Tic_Tac_Toe_Stub;

procedure Tests is
   X_Row : constant Board :=
     ((X, X, X), (O, Empty, O), (Empty, Empty, Empty));
   O_Diagonal : constant Board :=
     ((X, X, O), (X, O, Empty), (O, Empty, Empty));
   No_Winner : constant Board :=
     ((X, O, X), (X, O, O), (O, X, X));
begin
   Assert (Winner (X_Row) = X);
   Assert (Winner (O_Diagonal) = O);
   Assert (Winner (No_Winner) = Empty);
   Put_Line ("Tic Tac Toe: PASS");
end Tests;
