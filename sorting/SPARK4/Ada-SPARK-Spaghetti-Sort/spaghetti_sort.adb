--  Spaghetti_Sort body — SPARK Level 4 height-bin spaghetti sort with
--  static Counts (0 .. Max_Key). The height-bin (tally / emit) phase is
--  proved to sort on its own (ghost Sum_Below with Lemma_Zero / Lemma_Inc
--  / Lemma_Mono: the bins hold exactly N rods); there is no fallback pass.

--  Run-time cost: the ghost count lemmas, loop invariants and assertions
--  count every key with recursive Occ; all are proved (make prove) and
--  skipped at run time. The Posts of Sort and Height_Bin_Phase (sorted,
--  Is_Perm) still execute.
pragma Assertion_Policy (Ghost => Ignore, Loop_Invariant => Ignore, Assert => Ignore);

package body Spaghetti_Sort
  with SPARK_Mode => On
is

   --  Adjacent nondecreasing on A (L .. R). Vacuous when L >= R.
   function Sorted_Slice
     (A : Element_Array; L, R : Natural) return Boolean
   is
     (L >= R
      or else (for all K in L .. R - 1 => A (K) <= A (K + 1)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then L >= A'First
       and then R <= A'Last;

   --  Number of rods in the bins below H: C (0) + ... + C (H - 1).
   subtype Bin_Bound is Natural range 0 .. Max_Key + 1;

   function Bins_Ok (C : Count_Array) return Boolean is
     (for all K in Count_Index => C (K) <= Max_N)
   with Ghost => True, Global => null;

   function Sum_Below (C : Count_Array; H : Bin_Bound) return Natural is
     (if H = 0 then 0 else Sum_Below (C, H - 1) + C (H - 1))
   with
     Ghost              => True,
     Global             => null,
     Pre                => Bins_Ok (C),
     Post               => Sum_Below'Result <= H * Max_N,
     Subprogram_Variant => (Decreases => H);

   --  All bins empty: no rods below any H.
   procedure Lemma_Zero (C : Count_Array; H : Bin_Bound)
     with
       Ghost              => True,
       Global             => null,
       Pre                => (for all K in Count_Index => C (K) = 0),
       Post               => Sum_Below (C, H) = 0,
       Subprogram_Variant => (Decreases => H)
   is
   begin
      if H > 0 then
         Lemma_Zero (C, H - 1);
      end if;
   end Lemma_Zero;

   --  One more rod in bin J adds one to every sum that covers J.
   procedure Lemma_Inc
     (Before, After : Count_Array; J : Count_Index; H : Bin_Bound)
     with
       Ghost              => True,
       Global             => null,
       Pre                =>
         Bins_Ok (Before)
         and then Bins_Ok (After)
         and then After (J) = Before (J) + 1
         and then (for all K in Count_Index =>
                     (if K /= J then After (K) = Before (K))),
       Post               =>
         Sum_Below (After, H) = Sum_Below (Before, H) + (if J < H then 1 else 0),
       Subprogram_Variant => (Decreases => H)
   is
   begin
      if H > 0 then
         Lemma_Inc (Before, After, J, H - 1);
      end if;
   end Lemma_Inc;

   --  Sums only grow with H.
   procedure Lemma_Mono (C : Count_Array; H1, H2 : Bin_Bound)
     with
       Ghost              => True,
       Global             => null,
       Pre                => Bins_Ok (C) and then H1 <= H2,
       Post               => Sum_Below (C, H1) <= Sum_Below (C, H2),
       Subprogram_Variant => (Decreases => H2)
   is
   begin
      if H2 > H1 then
         Lemma_Mono (C, H1, H2 - 1);
      end if;
   end Lemma_Mono;

   --  Height-bin phase: tally rod lengths, emit short -> tall. Proved to
   --  sort on its own: the bins hold exactly A'Length rods (Sum_Below over
   --  all bins = A'Length), so the emit cursor, which starts at A'First,
   --  ends at A'Last + 1, and every rod written
   --  is no shorter than the rods before it.
   --  Counts over A'First .. Last only see A'First .. Last.
   procedure Lemma_Occ_Frame (X, Y : Element_Array; Last : Natural)
   with Ghost, Global => null,
        Pre  => In_Bounds (X) and then In_Bounds (Y) and then X'First = Y'First
                and then Last <= X'Last and then Last <= Y'Last
                and then (for all K in X'First .. Last => X (K) = Y (K)),
        Post => (for all V in Count_Index => Occ (X, V, Last) = Occ (Y, V, Last)),
        Subprogram_Variant => (Decreases => Last)
   is
   begin
      if Last >= X'First then
         Lemma_Occ_Frame (X, Y, Last - 1);
      end if;
   end Lemma_Occ_Frame;

   procedure Height_Bin_Phase (A : in out Element_Array)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Length >= 2
         and then Keys_Ok (A),
       Post   => In_Bounds (A) and then Is_Sorted (A) and then Is_Perm (A, A'Old)
   is
      subtype Cursor is Natural range 1 .. Max_N + 1;

      A0     : constant Element_Array := A with Ghost;
      Prev   : Element_Array (A'Range) with Ghost;

      N      : constant Index := A'Last;
      Counts : Count_Array := [others => 0];
      Pos    : Cursor;
      H      : Count_Index;
      C      : Natural;
   begin
      Lemma_Zero (Counts, Max_Key + 1);

      --  Tally: Counts (H) = number of rods of length H. The key domain
      --  is the subtype Count_Index (Keys_Ok), so no clamping is needed.
      for I in A'First .. N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (N = A'Last);
         pragma Loop_Invariant (Keys_Ok (A));
         pragma Loop_Invariant
           (for all K in Count_Index => Counts (K) <= I - A'First);
         pragma Loop_Invariant (Bins_Ok (Counts));
         pragma Loop_Invariant
           (Sum_Below (Counts, Max_Key + 1) = I - A'First);
         pragma Loop_Invariant (A = A0);
         pragma Loop_Invariant (for all K in Count_Index => Counts (K) = Occ (A0, K, I - 1));

         H := A (I);
         declare
            Before : constant Count_Array := Counts with Ghost;
         begin
            Counts (H) := Counts (H) + 1;
            Lemma_Inc (Before, Counts, H, Max_Key + 1);
         end;
      end loop;

      pragma Assert (Sum_Below (Counts, Max_Key + 1) = A'Length);

      --  Emit ascending: read bins from short to tall.
      Pos := A'First;

      for HH in Count_Index loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (N = A'Last);
         pragma Loop_Invariant (Bins_Ok (Counts));
         pragma Loop_Invariant (Sum_Below (Counts, Max_Key + 1) = A'Length);
         pragma Loop_Invariant (Pos = A'First + Sum_Below (Counts, HH));
         pragma Loop_Invariant (Pos <= N + 1);
         pragma Loop_Invariant (for all K in A'First .. Pos - 1 => A (K) <= HH);
         pragma Loop_Invariant (for all K in A'First .. Pos - 1 => A (K) >= 0);
         pragma Loop_Invariant (Sorted_Slice (A, A'First, Pos - 1));
         pragma Loop_Invariant
           (for all K2 in Count_Index =>
              Occ (A, K2, Pos - 1) = (if K2 < HH then Counts (K2) else 0));
         pragma Loop_Invariant (for all K in Count_Index => Counts (K) = Occ (A0, K, N));

         Lemma_Mono (Counts, HH + 1, Max_Key + 1);
         pragma Assert (Sum_Below (Counts, HH + 1) = Sum_Below (Counts, HH) + Counts (HH));
         C := 0;

         while C < Counts (HH) loop
            pragma Loop_Invariant (C < Counts (HH));
            pragma Loop_Invariant
              (Pos = A'First + Sum_Below (Counts, HH) + C);
            pragma Loop_Invariant (Pos <= N);
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (N = A'Last);
            pragma Loop_Invariant (for all K in A'First .. Pos - 1 => A (K) <= HH);
            pragma Loop_Invariant (for all K in A'First .. Pos - 1 => A (K) >= 0);
            pragma Loop_Invariant (Sorted_Slice (A, A'First, Pos - 1));
            pragma Loop_Invariant
              (for all K2 in Count_Index =>
                 Occ (A, K2, Pos - 1) = (if K2 < HH then Counts (K2) elsif K2 = HH then C else 0));
            pragma Loop_Variant (Decreases => Counts (HH) - C);

            Prev := A;
            A (Pos) := HH;
            Lemma_Occ_Frame (Prev, A, Pos - 1);
            Pos := Pos + 1;
            C := C + 1;
         end loop;

         pragma Assert (Pos = A'First + Sum_Below (Counts, HH + 1));
      end loop;

      pragma Assert (Pos = N + 1);
      pragma Assert (Sorted_Slice (A, A'First, N));
      pragma Assert (for all K2 in Count_Index => Occ (A, K2, N) = Occ (A0, K2, N));
      pragma Assert (for all I in A'Range => A (I) in Count_Index and then A0 (I) in Count_Index);
      pragma Assert (Is_Perm (A, A0));
   end Height_Bin_Phase;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      Height_Bin_Phase (A);
   end Sort;

end Spaghetti_Sort;
