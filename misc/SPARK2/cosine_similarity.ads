pragma Ada_2022;
package Cosine_Similarity with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 3;
   subtype Component is Integer range -1 .. 1;
   type Vector is array (Index) of Component;
   function Similarity (A, B : Vector) return Integer with Global => null;
end Cosine_Similarity;
