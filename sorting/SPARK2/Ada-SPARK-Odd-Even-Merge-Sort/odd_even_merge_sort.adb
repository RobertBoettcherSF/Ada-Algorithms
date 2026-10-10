pragma Ada_2022;

package body Odd_Even_Merge_Sort with SPARK_Mode => On is

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

   --  Comparator (Lo, Hi): the smaller value to Lo; logged as step K.
   procedure CE (A : in out Input_Array; Trace : in out Network; K : Positive; Lo, Hi : Index)
   with Global => null,
        Pre    => Lo < Hi and then K in Trace'Range,
        Post   => A (Lo) = Integer'Min (A'Old (Lo), A'Old (Hi))
                  and then A (Hi) = Integer'Max (A'Old (Lo), A'Old (Hi))
                  and then (for all J in Index =>
                              (if J /= Lo and then J /= Hi then A (J) = A'Old (J)))
                  and then Is_Perm (A'Old, A)
                  and then Trace (K) = (Lo, Hi)
                  and then (for all J in Trace'Range => (if J /= K then Trace (J) = Trace'Old (J)))
   is
   begin
      Trace (K) := (Lo, Hi);
      if A (Lo) > A (Hi) then
         Swap (A, Lo, Hi);
      else
         Lemma_Occ_Frame (A, A, Index'Last);
      end if;
   end CE;

   --  Is_Perm is transitive (proof only).
   procedure Lemma_Trans (A, B, C : Input_Array)
   with Ghost, Global => null,
        Pre  => Is_Perm (A, B) and then Is_Perm (B, C),
        Post => Is_Perm (A, C)
   is
   begin
      null;
   end Lemma_Trans;

   procedure Sort_Traced
     (Input : Input_Array; Output : out Input_Array; Trace : out Network)
   is
      W : Input_Array := Input;
      P, S, T, U : Input_Array with Ghost;

      procedure Step (K : Positive; Lo, Hi : Index)
      with Pre  => Lo < Hi and then K in Trace'Range and then Is_Perm (Input, W),
           Post => W (Lo) = Integer'Min (W'Old (Lo), W'Old (Hi))
                   and then W (Hi) = Integer'Max (W'Old (Lo), W'Old (Hi))
                   and then (for all J in Index =>
                               (if J /= Lo and then J /= Hi then W (J) = W'Old (J)))
                   and then Is_Perm (Input, W)
                   and then Trace (K) = (Lo, Hi)
                   and then (for all J in Trace'Range => (if J /= K then Trace (J) = Trace'Old (J)))
      is
         Before : constant Input_Array := W with Ghost;
      begin
         CE (W, Trace, K, Lo, Hi);
         Lemma_Trans (Input, Before, W);
      end Step;
   begin
      Trace := [others => (1, 1)];
      Lemma_Occ_Frame (Input, W, Index'Last);
      --  pairs
      Step (1, 1, 2); Step (2, 3, 4); Step (3, 5, 6); Step (4, 7, 8);
      pragma Assert (W (1) <= W (2) and then W (3) <= W (4) and then W (5) <= W (6) and then W (7) <= W (8));
      --  merge pairs into 4-blocks
      S := W;
      Step (5, 1, 3); Step (6, 2, 4); Step (7, 5, 7); Step (8, 6, 8);
      pragma Assert (W (1) = Integer'Min (S (1), S (3)) and then W (3) = Integer'Max (S (1), S (3)));
      pragma Assert (W (2) = Integer'Min (S (2), S (4)) and then W (4) = Integer'Max (S (2), S (4)));
      pragma Assert (W (5) = Integer'Min (S (5), S (7)) and then W (7) = Integer'Max (S (5), S (7)));
      pragma Assert (W (6) = Integer'Min (S (6), S (8)) and then W (8) = Integer'Max (S (6), S (8)));
      T := W;
      Step (9, 2, 3); Step (10, 6, 7);
      pragma Assert (W (2) = Integer'Min (T (2), T (3)) and then W (3) = Integer'Max (T (2), T (3)));
      pragma Assert (W (6) = Integer'Min (T (6), T (7)) and then W (7) = Integer'Max (T (6), T (7)));
      pragma Assert (W (1) <= W (2) and then W (2) <= W (3) and then W (3) <= W (4));
      pragma Assert (W (5) <= W (6) and then W (6) <= W (7) and then W (7) <= W (8));
      --  merge the 4-blocks
      S := W;
      Step (11, 1, 5); Step (12, 2, 6); Step (13, 3, 7); Step (14, 4, 8);
      pragma Assert (W (1) = Integer'Min (S (1), S (5)) and then W (5) = Integer'Max (S (1), S (5)));
      pragma Assert (W (2) = Integer'Min (S (2), S (6)) and then W (6) = Integer'Max (S (2), S (6)));
      pragma Assert (W (3) = Integer'Min (S (3), S (7)) and then W (7) = Integer'Max (S (3), S (7)));
      pragma Assert (W (4) = Integer'Min (S (4), S (8)) and then W (8) = Integer'Max (S (4), S (8)));
      T := W;
      Step (15, 3, 5); Step (16, 4, 6);
      pragma Assert (W (3) = Integer'Min (T (3), T (5)) and then W (5) = Integer'Max (T (3), T (5)));
      pragma Assert (W (4) = Integer'Min (T (4), T (6)) and then W (6) = Integer'Max (T (4), T (6)));
      U := W;
      Step (17, 2, 3); Step (18, 4, 5); Step (19, 6, 7);
      pragma Assert (W (2) = Integer'Min (U (2), U (3)) and then W (3) = Integer'Max (U (2), U (3)));
      pragma Assert (W (4) = Integer'Min (U (4), U (5)) and then W (5) = Integer'Max (U (4), U (5)));
      pragma Assert (W (6) = Integer'Min (U (6), U (7)) and then W (7) = Integer'Max (U (6), U (7)));
      pragma Assert (W (1) <= W (2) and then W (2) <= W (3) and then W (3) <= W (4) and then W (4) <= W (5)
                     and then W (5) <= W (6) and then W (6) <= W (7) and then W (7) <= W (8));
      Output := W;
      P := W;
      pragma Assert (Is_Perm (Input, P));
   end Sort_Traced;

   function Sort (Input : Input_Array) return Input_Array is
      Output : Input_Array;
      Trace  : Network (1 .. Network_Size);
   begin
      Sort_Traced (Input, Output, Trace);
      pragma Assert (Trace = Merge_Network);
      return Output;
   end Sort;
end Odd_Even_Merge_Sort;
