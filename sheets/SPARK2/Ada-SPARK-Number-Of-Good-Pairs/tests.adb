with Number_Of_Good_Pairs;
procedure Tests is
   Input : constant Number_Of_Good_Pairs.Input_Array := [1, 1];
   Other : constant Number_Of_Good_Pairs.Input_Array := [1, 2];
begin
   pragma Assert (Number_Of_Good_Pairs.Count_Good_Pairs (Input) = 1);
   pragma Assert (Number_Of_Good_Pairs.Count_Good_Pairs (Other) = 0);
end Tests;
