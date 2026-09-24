pragma SPARK_Mode (On);

package body Product_Of_Numbers_Stub is
   function Product (Values : Number_Array) return Product_Value is
      Result : Product_Value := 1;
   begin
      for I in Number_Index loop
         Result := Result * Values (I);
      end loop;
      return Result;
   end Product;
end Product_Of_Numbers_Stub;
