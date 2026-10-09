pragma Ada_2022;

package body Combination_Sum_II with SPARK_Mode => On is

   function Count_Limited (Value, Max_Part : Target) return Combination_Count is
      type Row_Type is array (Target) of Combination_Count;
      --  W (V) = Q (V, C) for V <= Value after part C; W (0) stays 1.
      W : Row_Type := [0 => 1, others => 0];
   begin
      for C in 1 .. Max_Part loop
         pragma Loop_Invariant (for all M in 0 .. Value => W (M) = Q (M, C - 1));
         declare
            Prev : constant Row_Type := W with Ghost;
            Cur  : constant Row_Type :=
              [for M in Target => (if M <= Value then Q (M, C) else 0)] with Ghost;
         begin
            --  Targets below C cannot use part C.
            pragma Assert (for all M in 0 .. Value => (if M < C then Cur (M) = Prev (M)));
            --  Right to left: W (V - C) still counts sets without part C,
            --  so part C is used at most once.
            for V in reverse C .. Value loop
               pragma Loop_Invariant
                 (for all M in 0 .. Value => W (M) = (if M > V then Cur (M) else Prev (M)));
               W (V) := W (V) + W (V - C);
            end loop;
            pragma Assert (for all M in 0 .. Value => W (M) = Cur (M));
         end;
      end loop;
      return W (Value);
   end Count_Limited;

   function Count_Distinct_Combinations (Value : Target) return Combination_Count is
     (Count_Limited (Value, Value));
end Combination_Sum_II;
