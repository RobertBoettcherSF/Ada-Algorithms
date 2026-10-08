pragma Ada_2022;

package body Prefix_Sums with SPARK_Mode => On is
   function Compute (Input : Input_Array) return Sum_Array is
      Result : Sum_Array;
      Running : Sum := 0;
   begin
      for I in Index loop
         Running := Running + Input (I);
         Result (I) := Running;
      end loop;
      return Result;
   end Compute;
end Prefix_Sums;
