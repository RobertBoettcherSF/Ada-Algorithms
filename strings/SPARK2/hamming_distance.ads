pragma Ada_2022;
package Hamming_Distance with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 3;
   subtype Component is Integer range 0 .. 1;
   type Vector is array (Index) of Component;
   function Distance (A, B : Vector) return Integer with Global => null;
end Hamming_Distance;
