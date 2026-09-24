with Ada.Assertions; use Ada.Assertions;
with Tweet_Counts_Stub; use Tweet_Counts_Stub;
procedure Tests is
   Tweets : Tweet_Times := (5, 65, 125, 3_605, others => 0);
begin
   Assert (Count_In_Range (Tweets, 4, 0, 60) = 1);
   Assert (Count_In_Range (Tweets, 4, 60, 180) = 2);
   Assert (Count_In_Range (Tweets, 4, 3_600, 3_700) = 1);
end Tests;
