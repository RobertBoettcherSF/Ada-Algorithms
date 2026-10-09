pragma Ada_2022;

package Ugly_Number_II with SPARK_Mode => On is
   Max_N : constant := 1_691;
   subtype N_Index is Positive range 1 .. Max_N;
   type Ugly_List is array (Positive range <>) of Positive;

   function First_Ugly (N : N_Index) return Ugly_List with Global => null;

   function Nth_Ugly (N : N_Index) return Positive with Global => null;
end Ugly_Number_II;
