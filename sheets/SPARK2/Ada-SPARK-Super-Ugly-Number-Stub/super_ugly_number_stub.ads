pragma Ada_2022;

package Super_Ugly_Number_Stub with SPARK_Mode => On is
   subtype N_Index is Positive range 1 .. 12;
   subtype Ugly_Value is Positive range 1 .. 1_000_000;

   function Nth_Super_Ugly (N : N_Index) return Ugly_Value with Global => null;
end Super_Ugly_Number_Stub;
