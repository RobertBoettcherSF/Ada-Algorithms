pragma SPARK_Mode (On);

package body Count_Operations_To_Obtain_Zero is
   function Operations
     (Num1, Num2 : Number) return Operation_Count is
      X : Number := Num1;
      Y : Number := Num2;
      Count : Operation_Count := 0;
   begin
      while X /= 0 and Y /= 0 loop
         pragma Loop_Invariant (Count + X + Y <= Operation_Count'Last);
         pragma Loop_Variant (Decreases => X + Y);
         if X >= Y then
            X := X - Y;
         else
            Y := Y - X;
         end if;
         Count := Count + 1;
      end loop;
      return Count;
   end Operations;
end Count_Operations_To_Obtain_Zero;
