pragma Ada_2022;
package Spearman_Rank_Stub with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 3;
   subtype Rank is Integer range 1 .. 3;
   type Vector is array (Index) of Rank;
   function Distance (A, B : Vector) return Integer with Global => null;
end Spearman_Rank_Stub;
