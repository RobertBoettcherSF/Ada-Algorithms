pragma Ada_2022;

package body Exchange_Sort with SPARK_Mode => On is

   ---------------------------------------------------------------------------
   --  Permutation lemmas (ghost; proved, and run under -gnata only as
   --  cheap calls whose contracts are checked).
   ---------------------------------------------------------------------------

   --  Counts over 1 .. Last only see 1 .. Last.
   procedure Lemma_Occ_Frame (A, B : Input_Array; Last : Natural)
   with Ghost,
        Global             => null,
        Pre                => Last <= Index'Last
                              and then (for all K in 1 .. Last => A (K) = B (K)),
        Post               => (for all V in Value => Occ (A, V, Last) = Occ (B, V, Last)),
        Subprogram_Variant => (Decreases => Last);

   procedure Lemma_Occ_Frame (A, B : Input_Array; Last : Natural) is
   begin
      if Last > 0 then
         Lemma_Occ_Frame (A, B, Last - 1);
      end if;
   end Lemma_Occ_Frame;

   --  B is A with slot K changed.
   procedure Lemma_Occ_Set (A, B : Input_Array; K : Index; Last : Natural)
   with Ghost,
        Global             => null,
        Pre                => Last in K .. Index'Last
                              and then (for all J in Index => (if J /= K then A (J) = B (J))),
        Post               => (for all V in Value =>
                                 Occ (B, V, Last)
                                 = Occ (A, V, Last)
                                   - (if A (K) = V then 1 else 0)
                                   + (if B (K) = V then 1 else 0)),
        Subprogram_Variant => (Decreases => Last);

   procedure Lemma_Occ_Set (A, B : Input_Array; K : Index; Last : Natural) is
   begin
      if Last > K then
         Lemma_Occ_Set (A, B, K, Last - 1);
      else
         Lemma_Occ_Frame (A, B, K - 1);
      end if;
   end Lemma_Occ_Set;

   --  B is A with slots X and Y exchanged.
   procedure Lemma_Swap (A, B : Input_Array; X, Y : Index)
   with Ghost,
        Global => null,
        Pre    => B (X) = A (Y) and then B (Y) = A (X)
                  and then (for all J in Index =>
                              (if J /= X and then J /= Y then A (J) = B (J))),
        Post   => Is_Perm (A, B);

   procedure Lemma_Swap (A, B : Input_Array; X, Y : Index) is
      C : constant Input_Array := [A with delta X => A (Y)];
   begin
      if X = Y then
         Lemma_Occ_Frame (A, B, Index'Last);
      else
         Lemma_Occ_Set (A, C, X, Index'Last);
         Lemma_Occ_Set (C, B, Y, Index'Last);
      end if;
   end Lemma_Swap;

   --  Exchange A (X) and A (Y).
   procedure Swap (A : in out Input_Array; X, Y : Index)
   with Global => null,
        Post   => A (X) = A'Old (Y) and then A (Y) = A'Old (X)
                  and then (for all J in Index =>
                              (if J /= X and then J /= Y then A (J) = A'Old (J)))
                  and then Is_Perm (A'Old, A);

   procedure Swap (A : in out Input_Array; X, Y : Index) is
      Before    : constant Input_Array := A with Ghost;
      Temporary : constant Value := A (X);
   begin
      A (X) := A (Y);
      A (Y) := Temporary;
      Lemma_Swap (Before, A, X, Y);
   end Swap;

   function Sort (Input : Input_Array) return Input_Array is
      Work : Input_Array := Input;
   begin
      for I in Index'First .. Index'Last - 1 loop
         for J in I + 1 .. Index'Last loop
            if Work (I) > Work (J) then
               Swap (Work, I, J);
            end if;
            pragma Loop_Invariant (Is_Perm (Input, Work));
            --  Work (1 .. I - 1) is sorted and no larger than any later value.
            pragma Loop_Invariant
              (for all P in Index'First .. I - 2 => Work (P) <= Work (P + 1));
            pragma Loop_Invariant
              (if I > Index'First then
                 (for all K in I .. Index'Last => Work (I - 1) <= Work (K)));
            --  Work (I) is the smallest of Work (I .. J).
            pragma Loop_Invariant
              (for all K in I .. J => Work (I) <= Work (K));
         end loop;
         pragma Loop_Invariant (Is_Perm (Input, Work));
         pragma Loop_Invariant
           (for all P in Index'First .. I - 1 => Work (P) <= Work (P + 1));
         pragma Loop_Invariant
           (for all K in I .. Index'Last => Work (I) <= Work (K));
      end loop;
      return Work;
   end Sort;
end Exchange_Sort;
