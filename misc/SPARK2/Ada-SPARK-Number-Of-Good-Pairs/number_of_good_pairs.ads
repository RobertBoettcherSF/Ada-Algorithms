pragma Ada_2022;

package Number_Of_Good_Pairs with SPARK_Mode => On is
   Length : constant := 2;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range 0 .. 9;
   subtype Pair_Count is Natural range 0 .. 1;
   type Input_Array is array (Index) of Value;

   function Count_Good_Pairs (Input : Input_Array) return Pair_Count
     with Global => null;
end Number_Of_Good_Pairs;
