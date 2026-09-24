with Rotate_Array;
procedure Tests is
   use type Rotate_Array.Value_Array;
   Input : constant Rotate_Array.Value_Array := [1, 2, 3, 4, 5];
   Expected : constant Rotate_Array.Value_Array := [5, 1, 2, 3, 4];
begin
   pragma Assert (Rotate_Array.Rotate_Right (Input) = Expected);
end Tests;
