pragma Ada_2022;

package body Missing_Number with SPARK_Mode => On is
   function Find (Input : Input_Array) return Missing_Value is
      Total : Integer := 15;
   begin
      Total := Total - Input (1);
      Total := Total - Input (2);
      Total := Total - Input (3);
      Total := Total - Input (4);
      Total := Total - Input (5);
      return Missing_Value (Total);
   end Find;
end Missing_Number;
