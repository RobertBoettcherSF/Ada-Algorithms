pragma Ada_2022;
package body Spearman_Rank_Stub with SPARK_Mode => On is
   function Distance (A, B : Vector) return Integer is
      D1 : constant Integer := Integer (A (1)) - Integer (B (1));
      D2 : constant Integer := Integer (A (2)) - Integer (B (2));
      D3 : constant Integer := Integer (A (3)) - Integer (B (3));
   begin
      -- Stub metric: sum of squared rank differences, before tie handling.
      return D1 * D1 + D2 * D2 + D3 * D3;
   end Distance;
end Spearman_Rank_Stub;
