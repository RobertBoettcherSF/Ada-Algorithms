with Sum_Of_Two_Integers; use Sum_Of_Two_Integers;
procedure Tests is
begin
   pragma Assert (Add (12, 30) = 42);
   pragma Assert (Add (-100, 25) = -75);
end Tests;
