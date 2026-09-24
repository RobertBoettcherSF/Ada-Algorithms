pragma Ada_2022;
package Covariance with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 3;
   subtype Component is Integer range 0 .. 10;
   type Vector is array (Index) of Component;
   function Value (A, B : Vector) return Integer with Global => null;
end Covariance;
