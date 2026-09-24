with Sliding_Window_Max;
procedure Tests is
   use type Sliding_Window_Max.Output_Array;
   Input : constant Sliding_Window_Max.Input_Array := [1, 5, 2, 4, 3];
   Expected : constant Sliding_Window_Max.Output_Array := [5, 5, 4];
begin
   pragma Assert (Sliding_Window_Max.Max_Window (Input) = Expected);
end Tests;
