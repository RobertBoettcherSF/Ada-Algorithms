pragma Ada_2022;

package body Number_Of_Good_Pairs with SPARK_Mode => On is
   function Count_Good_Pairs (Input : Input_Array) return Pair_Count is
   begin
      return (if Input (1) = Input (2) then 1 else 0);
   end Count_Good_Pairs;
end Number_Of_Good_Pairs;
