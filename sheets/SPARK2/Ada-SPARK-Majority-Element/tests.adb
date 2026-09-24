with Majority_Element;
procedure Tests is
   Input : constant Majority_Element.Input_Array := [2, 1, 2, 3, 2, 2, 4];
   Other : constant Majority_Element.Input_Array := [-1, -1, 3, -1, 4, -1, -1];
begin
   pragma Assert (Majority_Element.Find (Input) = 2);
   pragma Assert (Majority_Element.Find (Other) = -1);
end Tests;
