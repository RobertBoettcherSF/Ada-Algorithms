pragma Ada_2022;
package body Newton_Raphson with SPARK_Mode => On is
   function Sqrt (N : Input) return Integer is
      X : Integer := 100;
      Next : Integer;
   begin
      for Step in 1 .. 8 loop
         pragma Loop_Invariant (X in 1 .. 10_000);
         Next := (X + N / X) / 2;
         if Next < 1 then
            X := 1;
         elsif Next > 10_000 then
            X := 10_000;
         else
            X := Next;
         end if;
      end loop;
      return X;
   end Sqrt;
end Newton_Raphson;
