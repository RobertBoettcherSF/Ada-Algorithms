with Move_Zeroes;
procedure Tests is
   use type Move_Zeroes.Input_Array;
   Input : constant Move_Zeroes.Input_Array := [0, 1, 0, 3, 12];
   Expected : constant Move_Zeroes.Input_Array := [1, 3, 12, 0, 0];
   All_Zero : constant Move_Zeroes.Input_Array := [0, 0, 0, 0, 0];
   Expected_Zero : constant Move_Zeroes.Input_Array := [0, 0, 0, 0, 0];
begin
   pragma Assert (Move_Zeroes.Move (Input) = Expected);
   pragma Assert (Move_Zeroes.Move (All_Zero) = Expected_Zero);
end Tests;
