with Knight_Probability_In_Chessboard_Lite;
procedure Tests is
begin
   pragma Assert (Knight_Probability_In_Chessboard_Lite.Survival_Percent (0) = 100);
   pragma Assert (Knight_Probability_In_Chessboard_Lite.Survival_Percent (1) = 0);
   pragma Assert (Knight_Probability_In_Chessboard_Lite.Survival_Percent (16) = 0);
end Tests;
