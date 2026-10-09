pragma Ada_2022;

package body Search_A_2D_Matrix_II with SPARK_Mode => On is

   --  Along a row the entries never decrease.
   procedure Lemma_Row (M : Staircase_Matrix; R : Row; C1, C2 : Column)
   with
     Ghost,
     Pre  => C1 <= C2,
     Post => M (R, C1) <= M (R, C2)
   is
   begin
      for J in C1 .. C2 - 1 loop
         pragma Assert (Position_Of (R, J) + 1 = Position_Of (R, J + 1));
         pragma Assert (Cell (M, Position_Of (R, J)) <= Cell (M, Position_Of (R, J) + 1));
         pragma Assert (M (R, J) <= M (R, J + 1));
         pragma Loop_Invariant (M (R, C1) <= M (R, J + 1));
      end loop;
   end Lemma_Row;

   --  Down a column the entries never decrease.
   procedure Lemma_Column (M : Staircase_Matrix; C : Column; R1, R2 : Row)
   with
     Ghost,
     Pre  => R1 <= R2,
     Post => M (R1, C) <= M (R2, C)
   is
   begin
      for I in R1 .. R2 - 1 loop
         pragma Assert (Position_Of (I, C) + Cols = Position_Of (I + 1, C));
         pragma Assert (Cell (M, Position_Of (I, C)) <= Cell (M, Position_Of (I, C) + Cols));
         pragma Assert (M (I, C) <= M (I + 1, C));
         pragma Loop_Invariant (M (R1, C) <= M (I + 1, C));
      end loop;
   end Lemma_Column;

   --  M (R, C) > Target: so is every entry of column C from row R down.
   procedure Lemma_Drop_Column (M : Staircase_Matrix; R : Row; C : Column; Target : Value)
   with
     Ghost,
     Pre  => M (R, C) > Target,
     Post => (for all K in Cell_Index =>
                (if Row_Of (K) >= R and then Column_Of (K) = C then Cell (M, K) > Target))
   is
   begin
      for K in Cell_Index loop
         if Row_Of (K) >= R and then Column_Of (K) = C then
            Lemma_Column (M, C, R, Row_Of (K));
         end if;
         pragma Loop_Invariant
           (for all J in 1 .. K =>
              (if Row_Of (J) >= R and then Column_Of (J) = C then Cell (M, J) > Target));
      end loop;
   end Lemma_Drop_Column;

   --  M (R, C) < Target: so is every entry of row R up to column C.
   procedure Lemma_Drop_Row (M : Staircase_Matrix; R : Row; C : Column; Target : Value)
   with
     Ghost,
     Pre  => M (R, C) < Target,
     Post => (for all K in Cell_Index =>
                (if Row_Of (K) = R and then Column_Of (K) <= C then Cell (M, K) < Target))
   is
   begin
      for K in Cell_Index loop
         if Row_Of (K) = R and then Column_Of (K) <= C then
            Lemma_Row (M, R, Column_Of (K), C);
         end if;
         pragma Loop_Invariant
           (for all J in 1 .. K =>
              (if Row_Of (J) = R and then Column_Of (J) <= C then Cell (M, J) < Target));
      end loop;
   end Lemma_Drop_Row;

   function Contains (Grid : Staircase_Matrix; Target : Value) return Search_Result is
      R      : Positive range 1 .. Rows + 1 := 1;   --  rows above R and
      C      : Natural range 0 .. Cols := Cols;     --  columns right of C are done
      Probes : Probe_Count := 0;
   begin
      while R <= Rows and then C >= 1 loop
         pragma Loop_Invariant
           (for all K in Cell_Index =>
              (if Row_Of (K) < R or else Column_Of (K) > C then Cell (Grid, K) /= Target));
         pragma Loop_Invariant (Probes + (Rows + 1 - R) + C = Rows + Cols);
         pragma Loop_Variant (Increases => R, Decreases => C);
         Probes := Probes + 1;
         if Grid (R, C) = Target then
            pragma Assert (Cell (Grid, Position_Of (R, C)) = Target);
            return (Found => True, Probes => Probes);
         elsif Grid (R, C) > Target then
            Lemma_Drop_Column (Grid, R, C, Target);
            C := C - 1;
         else
            Lemma_Drop_Row (Grid, R, C, Target);
            R := R + 1;
         end if;
      end loop;
      return (Found => False, Probes => Probes);
   end Contains;
end Search_A_2D_Matrix_II;
