pragma SPARK_Mode (On);
pragma Ada_2022;
package body Combination_Iterator_Stub is
   function Create (Items : Value_Array; Item_Count : Count; Choose : Choose_Count) return Iterator is
      It : Iterator := (Items => Items, Item_Count => Item_Count, Choose => Choose,
                        Pos => [others => 1], Done => False);
   begin
      for J in 1 .. Choose loop
         It.Pos (J) := J;
         pragma Loop_Invariant (for all L in 1 .. J => It.Pos (L) = L);
      end loop;
      return It;
   end Create;

   function Has_Next (It : Iterator) return Boolean is (not It.Done);

   function Pivot (It : Iterator) return Natural is
      K : constant Choose_Count := It.Choose;
      N : constant Count := It.Item_Count;
      J : Natural := K;
   begin
      while J >= 1 and then It.Pos (J) = N - K + J loop
         pragma Loop_Invariant (J <= K);
         pragma Loop_Invariant
           (for all M in J + 1 .. K => It.Pos (M) = N - K + M);
         pragma Loop_Variant (Decreases => J);
         J := J - 1;
      end loop;
      return J;
   end Pivot;

   procedure Next (It : in out Iterator; R : out Combination) is
      K : constant Choose_Count := It.Choose;
      --  the rightmost position that can still move right
      J : constant Natural := Pivot (It);
   begin
      R := (Values => [others => 0], Size => K);
      for L in 1 .. K loop
         R.Values (L) := It.Items (It.Pos (L));
         pragma Loop_Invariant
           (for all M in 1 .. L => R.Values (M) = It.Items (It.Pos (M)));
      end loop;
      if J = 0 then
         It.Done := True;
      else
         declare
            Base : constant Index := It.Pos (J) + 1;
         begin
            for M in J .. K loop
               It.Pos (M) := Base + (M - J);
               pragma Loop_Invariant
                 (for all L in J .. M => It.Pos (L) = Base + (L - J));
            end loop;
         end;
      end if;
   end Next;
end Combination_Iterator_Stub;
