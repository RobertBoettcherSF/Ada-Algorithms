pragma Ada_2022;

package body Binary_Search_Upper_Bound with SPARK_Mode => On is
   function Find (Input : Input_Array; Target : Target_Value) return Result_Index is
   begin
      if Input (1) > Target then
         return 1;
      elsif Input (2) > Target then
         return 2;
      elsif Input (3) > Target then
         return 3;
      elsif Input (4) > Target then
         return 4;
      elsif Input (5) > Target then
         return 5;
      elsif Input (6) > Target then
         return 6;
      else
         return 7;
      end if;
   end Find;
end Binary_Search_Upper_Bound;
