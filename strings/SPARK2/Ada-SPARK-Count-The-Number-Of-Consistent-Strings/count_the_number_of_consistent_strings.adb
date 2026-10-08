pragma Ada_2022;

package body Count_The_Number_Of_Consistent_Strings with SPARK_Mode => On is
   function Count_Consistent (Input : Input_Array; Allowed : Symbol) return Count is
   begin
      return (if Input (1) <= Allowed then 1 else 0)
        + (if Input (2) <= Allowed then 1 else 0)
        + (if Input (3) <= Allowed then 1 else 0)
        + (if Input (4) <= Allowed then 1 else 0);
   end Count_Consistent;
end Count_The_Number_Of_Consistent_Strings;
