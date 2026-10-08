pragma Ada_2022;
package Tanimoto with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 3;
   subtype Component is Integer range 0 .. 3;
   type Vector is array (Index) of Component;
   function Similarity (A, B : Vector) return Integer with Global => null;
end Tanimoto;
