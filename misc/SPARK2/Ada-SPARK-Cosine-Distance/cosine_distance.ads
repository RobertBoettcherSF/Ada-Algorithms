pragma Ada_2022;
package Cosine_Distance with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 3;
   subtype Component is Integer range 0 .. 3;
   type Vector is array (Index) of Component;
   function Distance (A, B : Vector) return Integer with Global => null;
end Cosine_Distance;
