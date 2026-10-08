pragma Ada_2022;

package body Ugly_Number_II with SPARK_Mode => On is
   Table : constant array (N_Index) of Ugly_Value :=
     (1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5, 6 => 6,
      7 => 8, 8 => 9, 9 => 10, 10 => 12, 11 => 15, 12 => 16,
      13 => 18, 14 => 20, 15 => 24, 16 => 25, 17 => 27,
      18 => 30, 19 => 32, 20 => 36);

   function Nth_Ugly (N : N_Index) return Ugly_Value is
   begin
      return Table (N);
   end Nth_Ugly;
end Ugly_Number_II;
