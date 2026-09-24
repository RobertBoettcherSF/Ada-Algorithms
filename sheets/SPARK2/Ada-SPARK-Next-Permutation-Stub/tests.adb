with Next_Permutation_Stub;
procedure Tests is
   use type Next_Permutation_Stub.Input_Array;
begin
   pragma Assert (Next_Permutation_Stub.Next ([1, 2, 3, 4]) = [1, 2, 4, 3]);
   pragma Assert (Next_Permutation_Stub.Next ([1, 2, 4, 3]) = [1, 3, 2, 4]);
   pragma Assert (Next_Permutation_Stub.Next ([4, 3, 2, 1]) = [1, 2, 3, 4]);
end Tests;
