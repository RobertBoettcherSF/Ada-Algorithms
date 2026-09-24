pragma Ada_2022;
package body Manhattan_Distance with SPARK_Mode => On is
   function Distance (A, B : Vector) return Integer is
   begin
      return abs (Integer (A (1)) - Integer (B (1)))
        + abs (Integer (A (2)) - Integer (B (2)))
        + abs (Integer (A (3)) - Integer (B (3)));
   end Distance;
end Manhattan_Distance;
