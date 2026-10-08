pragma Ada_2022;
package body Euclidean_Distance with SPARK_Mode => On is
   function Distance (A, B : Point) return Integer is
      DX : constant Integer := Integer (A (1)) - Integer (B (1));
      DY : constant Integer := Integer (A (2)) - Integer (B (2));
   begin
      -- Squared distance is exact and avoids an unbounded square root.
      return DX * DX + DY * DY;
   end Distance;
end Euclidean_Distance;
