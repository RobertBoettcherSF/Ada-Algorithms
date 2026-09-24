pragma Ada_2022;
package body Bisection_Method with SPARK_Mode => On is
   function Sqrt (N : Input) return Integer is
      Low  : Integer := 0;
      High : Integer := 100;
      Mid  : Integer;
   begin
      for Step in 1 .. 9 loop
         pragma Loop_Invariant (Low in 0 .. 100 and High in 0 .. 100 and Low <= High);
         Mid := Low + (High - Low + 1) / 2;
         if Mid = 0 or else Mid <= N / Mid then
            Low := Mid;
         else
            High := Mid;
         end if;
      end loop;
      return Low;
   end Sqrt;
end Bisection_Method;
