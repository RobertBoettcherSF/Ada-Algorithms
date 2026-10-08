pragma Ada_2022;

package body How_Many_Numbers_Are_Smaller with SPARK_Mode => On is
   function Count_Smaller (Input : Input_Array; Pivot : Value) return Count is
   begin
      return (if Input (1) < Pivot then 1 else 0)
        + (if Input (2) < Pivot then 1 else 0)
        + (if Input (3) < Pivot then 1 else 0)
        + (if Input (4) < Pivot then 1 else 0)
        + (if Input (5) < Pivot then 1 else 0);
   end Count_Smaller;
end How_Many_Numbers_Are_Smaller;
