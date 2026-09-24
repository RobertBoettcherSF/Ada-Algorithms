with Ada.Assertions; use Ada.Assertions;
with Baseball_Game; use Baseball_Game;
procedure Tests is G : Game := New_Game;
begin Home_Run (G); Home_Run (G); Away_Run (G); Assert (Home_Score (G) = 2); Assert (Winner (G) = 1); end Tests;
