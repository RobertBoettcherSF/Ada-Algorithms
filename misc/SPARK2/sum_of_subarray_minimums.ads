pragma Ada_2022;

package Sum_Of_Subarray_Minimums with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   subtype Value is Natural range 0 .. 32;
   subtype Sum_Value is Natural range 0 .. 33_792;
   type Values is array (Index) of Value;

   function Sum_Minimums (A : Values; Length : Length_Type) return Sum_Value
     with Global => null;
end Sum_Of_Subarray_Minimums;
