pragma Ada_2022;

package body Circle_Sort with SPARK_Mode => On is

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

   --  Compare A (Lo) with A (Hi), exchange when out of order.
   procedure CE (A : in out Input_Array; Did : out Boolean; Lo, Hi : Index)
   with Global => null,
        Pre    => Lo < Hi,
        Post   => Did = (A'Old (Lo) > A'Old (Hi))
                  and then A (Lo) = Integer'Min (A'Old (Lo), A'Old (Hi))
                  and then A (Hi) = Integer'Max (A'Old (Lo), A'Old (Hi))
                  and then (for all J in Index =>
                              (if J /= Lo and then J /= Hi then A (J) = A'Old (J)))
                  and then Is_Perm (A'Old, A)
   is
   begin
      Did := A (Lo) > A (Hi);
      if Did then
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

   --  One pass; logs its 12 comparisons at Trace (Base + 1 .. Base + 12).
   procedure Pass (W : in out Input_Array; Trace : in out Network; Base : Natural; Swapped : out Boolean)
   with Global => null,
        Pre    => Trace'First = 1 and then Trace'Last = Max_Trace and then Base <= Max_Trace - Pass_Size,
        Post   => Is_Perm (W'Old, W)
                  and then Inversions (W) + (if Swapped then 1 else 0) <= Inversions (W'Old)
                  and then (if not Swapped then Is_Sorted (W))
                  and then (for all J in 1 .. Pass_Size => Trace (Base + J) = Circle_Pass (J))
                  and then (for all K in Trace'Range =>
                              (if K <= Base or else K > Base + Pass_Size then Trace (K) = Trace'Old (K)))
   is
      W0  : constant Input_Array := W with Ghost;
      S   : Input_Array with Ghost;
      Did : Boolean;
   begin
      Swapped := False;
      S := W;
      CE (W, Did, 1, 8);
      Trace (Base + 1) := (1, 8);
      pragma Assert (Inversions (W) + (if Did then 1 else 0) <= Inversions (S));
      Swapped := Swapped or Did;
      pragma Assert (Inversions (W) + (if Swapped then 1 else 0) <= Inversions (W0));
      pragma Assert (if not Swapped then W = W0);
      S := W;
      CE (W, Did, 2, 7);
      Trace (Base + 2) := (2, 7);
      pragma Assert (Inversions (W) + (if Did then 1 else 0) <= Inversions (S));
      Swapped := Swapped or Did;
      pragma Assert (Inversions (W) + (if Swapped then 1 else 0) <= Inversions (W0));
      pragma Assert (if not Swapped then W = W0);
      S := W;
      CE (W, Did, 3, 6);
      Trace (Base + 3) := (3, 6);
      pragma Assert (Inversions (W) + (if Did then 1 else 0) <= Inversions (S));
      Swapped := Swapped or Did;
      pragma Assert (Inversions (W) + (if Swapped then 1 else 0) <= Inversions (W0));
      pragma Assert (if not Swapped then W = W0);
      S := W;
      CE (W, Did, 4, 5);
      Trace (Base + 4) := (4, 5);
      pragma Assert (Inversions (W) + (if Did then 1 else 0) <= Inversions (S));
      Swapped := Swapped or Did;
      pragma Assert (Inversions (W) + (if Swapped then 1 else 0) <= Inversions (W0));
      pragma Assert (if not Swapped then W = W0);
      S := W;
      CE (W, Did, 1, 4);
      Trace (Base + 5) := (1, 4);
      pragma Assert (Inversions (W) + (if Did then 1 else 0) <= Inversions (S));
      Swapped := Swapped or Did;
      pragma Assert (Inversions (W) + (if Swapped then 1 else 0) <= Inversions (W0));
      pragma Assert (if not Swapped then W = W0);
      S := W;
      CE (W, Did, 2, 3);
      Trace (Base + 6) := (2, 3);
      pragma Assert (Inversions (W) + (if Did then 1 else 0) <= Inversions (S));
      Swapped := Swapped or Did;
      pragma Assert (Inversions (W) + (if Swapped then 1 else 0) <= Inversions (W0));
      pragma Assert (if not Swapped then W = W0);
      S := W;
      CE (W, Did, 1, 2);
      Trace (Base + 7) := (1, 2);
      pragma Assert (Inversions (W) + (if Did then 1 else 0) <= Inversions (S));
      Swapped := Swapped or Did;
      pragma Assert (Inversions (W) + (if Swapped then 1 else 0) <= Inversions (W0));
      pragma Assert (if not Swapped then W = W0);
      S := W;
      CE (W, Did, 3, 4);
      Trace (Base + 8) := (3, 4);
      pragma Assert (Inversions (W) + (if Did then 1 else 0) <= Inversions (S));
      Swapped := Swapped or Did;
      pragma Assert (Inversions (W) + (if Swapped then 1 else 0) <= Inversions (W0));
      pragma Assert (if not Swapped then W = W0);
      S := W;
      CE (W, Did, 5, 8);
      Trace (Base + 9) := (5, 8);
      pragma Assert (Inversions (W) + (if Did then 1 else 0) <= Inversions (S));
      Swapped := Swapped or Did;
      pragma Assert (Inversions (W) + (if Swapped then 1 else 0) <= Inversions (W0));
      pragma Assert (if not Swapped then W = W0);
      S := W;
      CE (W, Did, 6, 7);
      Trace (Base + 10) := (6, 7);
      pragma Assert (Inversions (W) + (if Did then 1 else 0) <= Inversions (S));
      Swapped := Swapped or Did;
      pragma Assert (Inversions (W) + (if Swapped then 1 else 0) <= Inversions (W0));
      pragma Assert (if not Swapped then W = W0);
      S := W;
      CE (W, Did, 5, 6);
      Trace (Base + 11) := (5, 6);
      pragma Assert (Inversions (W) + (if Did then 1 else 0) <= Inversions (S));
      Swapped := Swapped or Did;
      pragma Assert (Inversions (W) + (if Swapped then 1 else 0) <= Inversions (W0));
      pragma Assert (if not Swapped then W = W0);
      S := W;
      CE (W, Did, 7, 8);
      Trace (Base + 12) := (7, 8);
      pragma Assert (Inversions (W) + (if Did then 1 else 0) <= Inversions (S));
      Swapped := Swapped or Did;
      pragma Assert (Inversions (W) + (if Swapped then 1 else 0) <= Inversions (W0));
      pragma Assert (if not Swapped then W = W0);
      pragma Assert (if not Swapped then
                       W (1) <= W (2) and then W (2) <= W (3) and then W (3) <= W (4)
                       and then W (4) <= W (5) and then W (5) <= W (6) and then W (6) <= W (7)
                       and then W (7) <= W (8));
      pragma Assert (Is_Perm (W0, W));
   end Pass;

   procedure Sort_Traced
     (Input  : Input_Array; Output : out Input_Array; Trace : out Network;
      Length : out Natural; Passes : out Natural)
   is
      W       : Input_Array := Input;
      Swapped : Boolean;
      Before  : Input_Array with Ghost;
   begin
      Trace  := [others => (1, 1)];
      Passes := 0;
      Lemma_Occ_Frame (Input, W, Index'Last);
      loop
         pragma Loop_Invariant (Is_Perm (Input, W));
         pragma Loop_Invariant (Passes <= Inversions (Input) - Inversions (W));
         pragma Loop_Invariant
           (for all P in 0 .. Passes - 1 =>
              (for all J in 1 .. Pass_Size => Trace (Pass_Size * P + J) = Circle_Pass (J)));
         pragma Loop_Variant (Decreases => Inversions (W));
         Before := W;
         Pass (W, Trace, Pass_Size * Passes, Swapped);
         Lemma_Trans (Input, Before, W);
         Passes := Passes + 1;
         exit when not Swapped;
      end loop;
      Output := W;
      Length := Pass_Size * Passes;
   end Sort_Traced;

   function Sort (Input : Input_Array) return Input_Array is
      Output : Input_Array;
      Trace  : Network (1 .. Max_Trace);
      Length, Passes : Natural;
   begin
      Sort_Traced (Input, Output, Trace, Length, Passes);
      pragma Assert (Length = Pass_Size * Passes);
      pragma Assert (Trace (1) = Circle_Pass (1));
      return Output;
   end Sort;
end Circle_Sort;
