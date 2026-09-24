pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO; with Design_A_Leaderboard; use Design_A_Leaderboard;
procedure Tests is
begin Initialize; Assert (not Has_Score); Submit (40); Submit (15); Submit (90); Assert (Has_Score and then Best = 90); Put_Line ("PASS leaderboard"); end Tests;
