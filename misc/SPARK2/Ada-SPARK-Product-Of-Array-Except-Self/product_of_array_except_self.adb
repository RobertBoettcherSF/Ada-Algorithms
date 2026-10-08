pragma Ada_2022;

package body Product_Of_Array_Except_Self with SPARK_Mode => On is
   function Products (Input : Input_Array) return Output_Array is
      Result : Output_Array;
      Product : Integer;
      J : Index;
   begin
      for I in Index loop
         Product := 1;
         for K in Index loop
            J := K;
            if J /= I then
               Product := Product * Input (J);
            end if;
         end loop;
         Result (I) := Product;
      end loop;
      return Result;
   end Products;
end Product_Of_Array_Except_Self;
