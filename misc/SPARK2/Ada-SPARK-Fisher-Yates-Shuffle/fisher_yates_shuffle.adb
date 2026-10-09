pragma Ada_2022;

package body Fisher_Yates_Shuffle with SPARK_Mode => On is

   --  Changing position K changes the counts of the old and new value.
   procedure Lemma_Set (A, B : Item_Array; K : Index)
   with
     Ghost,
     Pre  => (for all N in Index => (if N /= K then B (N) = A (N))),
     Post =>
       (for all V in Item =>
          Occ (B, V, Length) =
            Occ (A, V, Length) - (if A (K) = V then 1 else 0)
            + (if B (K) = V then 1 else 0))
   is
   begin
      for U in Index loop
         pragma Loop_Invariant
           (for all V in Item =>
              Occ (B, V, U) =
                Occ (A, V, U)
                + (if K <= U then
                     (if B (K) = V then 1 else 0) - (if A (K) = V then 1 else 0)
                   else 0));
      end loop;
   end Lemma_Set;

   procedure Shuffle (Data : in out Item_Array; Choices : Swap_Array) is
      Temporary : Item;
      Before    : Item_Array with Ghost;
      Middle    : Item_Array with Ghost;
   begin
      for I in reverse Index loop
         pragma Loop_Invariant (Is_Perm (Data, Data'Loop_Entry));
         Before := Data;
         Temporary := Data (I);
         Data (I) := Data (Choices (I));
         Middle := Data;
         Lemma_Set (Before, Middle, I);
         Data (Choices (I)) := Temporary;
         Lemma_Set (Middle, Data, Choices (I));
      end loop;
   end Shuffle;
end Fisher_Yates_Shuffle;
