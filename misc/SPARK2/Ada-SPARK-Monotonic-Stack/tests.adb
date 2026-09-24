with Monotonic_Stack;
procedure Tests is
   use type Monotonic_Stack.Result_Array;
   Input : constant Monotonic_Stack.Input_Array := [2, 1, 3, 2, 4];
   Expected : constant Monotonic_Stack.Result_Array := [3, 3, 4, 4, -11];
begin
   pragma Assert (Monotonic_Stack.Next_Greater (Input) = Expected);
end Tests;
