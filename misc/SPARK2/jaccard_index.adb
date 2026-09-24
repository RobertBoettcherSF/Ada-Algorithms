pragma Ada_2022;
package body Jaccard_Index with SPARK_Mode => On is
   function Similarity (A, B : Vector) return Integer is
      Intersection : constant Integer := Integer (A (1)) * Integer (B (1))
        + Integer (A (2)) * Integer (B (2))
        + Integer (A (3)) * Integer (B (3));
      Union : constant Integer :=
        (if A (1) = 1 or else B (1) = 1 then 1 else 0)
        + (if A (2) = 1 or else B (2) = 1 then 1 else 0)
        + (if A (3) = 1 or else B (3) = 1 then 1 else 0);
   begin
      -- The empty-set convention gives identical empty vectors full similarity.
      return (if Union = 0 then 100 else (100 * Intersection) / Union);
   end Similarity;
end Jaccard_Index;
