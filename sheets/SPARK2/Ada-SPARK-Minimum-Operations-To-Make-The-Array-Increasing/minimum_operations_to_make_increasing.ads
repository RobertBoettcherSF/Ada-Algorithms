pragma SPARK_Mode (On);

package Minimum_Operations_To_Make_Increasing is
   subtype Value is Natural range 0 .. 1_000;
   subtype Operation_Count is Natural range 0 .. 1_001;

   function Required_Increase
     (Previous, Current : Value) return Operation_Count
     with Global => null,
          Post => Required_Increase'Result <= Operation_Count'Last;
end Minimum_Operations_To_Make_Increasing;
