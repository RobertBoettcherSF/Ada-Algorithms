pragma Ada_2022;

package Ugly_Number_II with SPARK_Mode => On is
   subtype N_Index is Positive range 1 .. 20;
   subtype Ugly_Value is Positive range 1 .. 1_000_000;

   function Nth_Ugly (N : N_Index) return Ugly_Value with Global => null;
end Ugly_Number_II;
