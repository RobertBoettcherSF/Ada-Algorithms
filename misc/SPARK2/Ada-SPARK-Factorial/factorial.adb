pragma SPARK_Mode (On);

package body Factorial is
   function Compute (N : Input) return Result is
      Product : Result := 1;
   begin
      for I in 1 .. N loop
         pragma Loop_Invariant (Product = Fact (I - 1));
         Product := Product * Long_Long_Integer (I);
      end loop;
      return Product;
   end Compute;
end Factorial;
