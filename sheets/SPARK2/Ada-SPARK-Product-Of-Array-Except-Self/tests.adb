with Product_Of_Array_Except_Self;
procedure Tests is
   Input : constant Product_Of_Array_Except_Self.Input_Array := [1, 2, 1, 2, 0, 2, 1, 2];
   Result : constant Product_Of_Array_Except_Self.Output_Array := Product_Of_Array_Except_Self.Products (Input);
begin
   pragma Assert (Result (1) = 0);
   pragma Assert (Result (5) = 16);
end Tests;
