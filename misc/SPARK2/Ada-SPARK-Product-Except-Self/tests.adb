with Product_Except_Self;
procedure Tests is
   use type Product_Except_Self.Result_Array;
   Input : constant Product_Except_Self.Input_Array := [1, 2, 3, 4, 5];
   Expected : constant Product_Except_Self.Result_Array := [120, 60, 40, 30, 24];
   With_Zero : constant Product_Except_Self.Input_Array := [1, 0, 3, 4, 5];
   Zero_Expected : constant Product_Except_Self.Result_Array := [0, 60, 0, 0, 0];
begin
   pragma Assert (Product_Except_Self.Compute (Input) = Expected);
   pragma Assert (Product_Except_Self.Compute (With_Zero) = Zero_Expected);
end Tests;
