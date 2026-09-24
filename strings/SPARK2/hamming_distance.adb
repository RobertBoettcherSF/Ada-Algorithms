pragma Ada_2022;
package body Hamming_Distance with SPARK_Mode => On is
   function Distance (A, B : Vector) return Integer is
   begin
      return (if A (1) = B (1) then 0 else 1)
        + (if A (2) = B (2) then 0 else 1)
        + (if A (3) = B (3) then 0 else 1);
   end Distance;
end Hamming_Distance;
