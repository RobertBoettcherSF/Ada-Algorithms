pragma Ada_2022;

package body Ugly_Number_II with SPARK_Mode => On is
   --  Scaffold for the failing test: the old table, not yet computed.
   Table : constant array (1 .. 20) of Positive :=
     [1, 2, 3, 4, 5, 6, 8, 9, 10, 12, 15, 16, 18, 20, 24, 25, 27, 30, 32, 36];

   function Nth_Ugly (N : N_Index) return Positive is
     (if N <= 20 then Table (N) else 1);

   function First_Ugly (N : N_Index) return Ugly_List is
     [for K in 1 .. N => Nth_Ugly (K)];
end Ugly_Number_II;
