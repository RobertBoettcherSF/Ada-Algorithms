with Three_Sum_Closest_Stub;
procedure Tests is
   Input : constant Three_Sum_Closest_Stub.Input_Array := [-4, 1, 2, 5, 5];
   Other : constant Three_Sum_Closest_Stub.Input_Array := [-5, -2, 3, 4, 5];
begin
   pragma Assert (Three_Sum_Closest_Stub.Closest (Input, 6) = 6);
   pragma Assert (Three_Sum_Closest_Stub.Closest (Other, 1) = 2);
end Tests;
