with Plus_One;
procedure Tests is
   use type Plus_One.Digit_Array;
   Input : constant Plus_One.Digit_Array := [1, 2, 3, 4];
   Carry : constant Plus_One.Digit_Array := [1, 2, 9, 9];
   Nine : constant Plus_One.Digit_Array := [9, 9, 9, 9];
   Expected : constant Plus_One.Digit_Array := [1, 2, 3, 5];
   Expected_Carry : constant Plus_One.Digit_Array := [1, 3, 0, 0];
   Expected_Nine : constant Plus_One.Digit_Array := [1, 0, 0, 0];
begin
   pragma Assert (Plus_One.Increment (Input) = Expected);
   pragma Assert (Plus_One.Increment (Carry) = Expected_Carry);
   pragma Assert (Plus_One.Increment (Nine) = Expected_Nine);
end Tests;
