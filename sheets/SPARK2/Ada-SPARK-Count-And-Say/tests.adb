with Ada.Assertions; use Ada.Assertions;
with Count_And_Say; use Count_And_Say;
procedure Tests is
   Answer : Run;
begin
   Answer := First_Run ([1, 1, 1, 2, 2, 3]);
   Assert (Answer.Count = 3 and then Answer.Value = 1);
   Answer := First_Run ([4, 2, 2, 2, 2, 2]);
   Assert (Answer.Count = 1 and then Answer.Value = 4);
end Tests;
