pragma SPARK_Mode (On);

package Count_Operations_To_Obtain_Zero is
   subtype Number is Natural range 0 .. 32;
   subtype Operation_Count is Natural range 0 .. 64;

   function Operations
     (Num1, Num2 : Number) return Operation_Count
     with Global => null,
          Post => Operations'Result <= Operation_Count'Last;
end Count_Operations_To_Obtain_Zero;
