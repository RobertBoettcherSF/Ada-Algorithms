pragma Ada_2022;

package body Difference_Array with SPARK_Mode => On is
   function Compute (Input : Input_Array) return Difference_Values is
      Result : Difference_Values := [others => 0];
   begin
      Result (Index'First) := Difference (Input (Index'First));
      for I in Index range 2 .. Index'Last loop
         Result (I) := Input (I) - Input (I - 1);
      end loop;
      return Result;
   end Compute;
end Difference_Array;
