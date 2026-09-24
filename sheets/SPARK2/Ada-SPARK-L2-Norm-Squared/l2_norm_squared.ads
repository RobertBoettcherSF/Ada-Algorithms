pragma Ada_2022;
package L2_Norm_Squared with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 3;
   subtype Component is Integer range -10 .. 10;
   type Vector is array (Index) of Component;
   function Norm_Squared (A : Vector) return Integer with Global => null;
end L2_Norm_Squared;
