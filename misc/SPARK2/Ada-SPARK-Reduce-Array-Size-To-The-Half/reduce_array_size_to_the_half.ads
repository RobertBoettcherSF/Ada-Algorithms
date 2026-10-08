pragma SPARK_Mode (On);

package Reduce_Array_Size_To_The_Half is
   subtype Array_Length is Natural range 0 .. 32;
   subtype Group_Size is Natural range 0 .. 32;
   subtype Group_Count is Natural range 0 .. 2;

   function Groups_To_Remove
     (Length, Largest_Group : Array_Length) return Group_Count
     with Global => null,
          Pre => Largest_Group <= Length,
          Post => Groups_To_Remove'Result <= Group_Count'Last;
end Reduce_Array_Size_To_The_Half;
