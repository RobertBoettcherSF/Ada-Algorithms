pragma Ada_2022;

package body Super_Ugly_Number_Stub with SPARK_Mode => On is
   -- The bounded exercise uses the fixed prime set (2, 7, 13, 19).
   Table : constant array (N_Index) of Ugly_Value :=
     (1 => 1, 2 => 2, 3 => 4, 4 => 7, 5 => 8, 6 => 13,
      7 => 14, 8 => 16, 9 => 19, 10 => 26, 11 => 28, 12 => 32);

   function Nth_Super_Ugly (N : N_Index) return Ugly_Value is
   begin
      return Table (N);
   end Nth_Super_Ugly;
end Super_Ugly_Number_Stub;
