pragma Ada_2022;
package body Fixed_Point_Iteration with SPARK_Mode => On is
   function Iterate (Initial : Value; Target : Value) return Integer is
      Current : Integer := Initial;
   begin
      for Step in 1 .. 10 loop
         Current := (Current + Target) / 2;
      end loop;
      return Current;
   end Iterate;
end Fixed_Point_Iteration;
