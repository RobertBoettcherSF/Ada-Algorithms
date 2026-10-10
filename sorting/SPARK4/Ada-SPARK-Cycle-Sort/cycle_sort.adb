--  Cycle_Sort body — SPARK Level 4 classic write-optimal in-place cycle
--  sort. Outer loop grows a sorted / partitioned prefix (same shape as
--  selection sort); each Cycle_Step either skips an already-placed
--  element or rotates a displacement cycle. Closing writes use Dest=CS
--  so Item <= suffix is immediate from Dest_Index, discharging Is_Sorted.
--  The cycle is proved to close (ghost block counting, loop variant on
--  the number of settled positions); there is no step cap and no
--  selection-sort safety net.

package body Cycle_Sort
  with SPARK_Mode => On
is

   --  Same_Occ quantifies over every Integer value, so the contracts,
   --  invariants and assertions of this body (all proved by gnatprove) are
   --  not checked at run time; the Posts of Sort and Sort_Counting_Writes in the
   --  spec (sorted, Is_Perm) still are.
   pragma Assertion_Policy
     (Pre => Ignore, Post => Ignore, Loop_Invariant => Ignore, Assert => Ignore);

   --  A and B have the same bounds and every value occurs equally often.
   function Same_Occ (A, B : Element_Array) return Boolean is
     (A'First = B'First
      and then A'Last = B'Last
      and then (A'Length = 0
                or else (for all V in Integer =>
                           Occ (A, V, A'First, A'Last)
                           = Occ (B, V, B'First, B'Last))))
   with
     Ghost,
     Global => null,
     Pre    => In_Bounds (A) and then In_Bounds (B);

   package Perm_Lemmas
     with Ghost
   is
      --  Counts over First .. Last only see First .. Last.
      procedure Lemma_Occ_Eq (A, B : Element_Array; First : Positive; Last : Natural)
      with
        Global             => null,
        Pre                =>
          (if First <= Last then
             First >= A'First and then Last <= A'Last
             and then First >= B'First and then Last <= B'Last
             and then (for all T in First .. Last => A (T) = B (T))),
        Post               =>
          (for all V in Integer =>
             Occ (A, V, First, Last) = Occ (B, V, First, Last)),
        Subprogram_Variant => (Decreases => Last);

      --  The executable Is_Perm and the logical Same_Occ agree.
      procedure Lemma_Same_Perm (A, B : Element_Array)
      with
        Global => null,
        Pre    => In_Bounds (A) and then In_Bounds (B) and then Same_Occ (A, B),
        Post   => Is_Perm (A, B);

      procedure Lemma_Same_Trans (A, B, C : Element_Array)
      with
        Global => null,
        Pre    =>
          In_Bounds (A) and then In_Bounds (B) and then In_Bounds (C)
          and then Same_Occ (A, B) and then Same_Occ (B, C),
        Post   => Same_Occ (A, C);

      --  B is A with slot K changed.
      procedure Lemma_Occ_Set
        (A, B : Element_Array; K : Positive; First : Positive; Last : Natural)
      with
        Global             => null,
        Pre                =>
          In_Bounds (A) and then In_Bounds (B)
          and then A'First = B'First and then A'Last = B'Last
          and then K in First .. Last
          and then First >= A'First and then Last <= A'Last
          and then (for all J in A'Range => (if J /= K then A (J) = B (J))),
        Post               =>
          (for all V in Integer =>
             Occ (B, V, First, Last)
             = Occ (A, V, First, Last)
               - (if A (K) = V then 1 else 0)
               + (if B (K) = V then 1 else 0)),
        Subprogram_Variant => (Decreases => Last);

      --  B is A with slots X and Y exchanged.
      procedure Lemma_Swap (A, B : Element_Array; X, Y : Positive)
      with
        Global => null,
        Pre    =>
          In_Bounds (A) and then In_Bounds (B)
          and then A'First = B'First and then A'Last = B'Last
          and then X in A'Range and then Y in A'Range
          and then B (X) = A (Y) and then B (Y) = A (X)
          and then (for all J in A'Range =>
                      (if J /= X and then J /= Y then A (J) = B (J))),
        Post   => Same_Occ (A, B);

      procedure Lemma_Same_Refl (A : Element_Array)
      with
        Global => null,
        Pre    => In_Bounds (A),
        Post   => Same_Occ (A, A);

      --  Same_Occ (A0, A) carries over to an elementwise-equal B.
      procedure Lemma_Eq_Trans (A0, A, B : Element_Array)
      with
        Global => null,
        Pre    =>
          In_Bounds (A0) and then In_Bounds (A) and then In_Bounds (B)
          and then A'First = B'First and then A'Last = B'Last
          and then Same_Occ (A0, A)
          and then (for all J in A'Range => A (J) = B (J)),
        Post   => Same_Occ (A0, B);

      --  Same_Occ (A0, A) carries over to B, A with slots X, Y exchanged.
      procedure Lemma_Swap_Trans (A0, A, B : Element_Array; X, Y : Positive)
      with
        Global => null,
        Pre    =>
          In_Bounds (A0) and then In_Bounds (A) and then In_Bounds (B)
          and then A'First = B'First and then A'Last = B'Last
          and then X in A'Range and then Y in A'Range
          and then Same_Occ (A0, A)
          and then B (X) = A (Y) and then B (Y) = A (X)
          and then (for all J in A'Range =>
                      (if J /= X and then J /= Y then A (J) = B (J))),
        Post   => Same_Occ (A0, B);
   end Perm_Lemmas;

   package body Perm_Lemmas is

      procedure Lemma_Same_Refl (A : Element_Array) is
      begin
         Lemma_Occ_Eq (A, A, A'First, A'Last);
      end Lemma_Same_Refl;

      procedure Lemma_Eq_Trans (A0, A, B : Element_Array) is
      begin
         Lemma_Occ_Eq (A, B, A'First, A'Last);
         pragma Assert (Same_Occ (A, B));
         Lemma_Same_Trans (A0, A, B);
      end Lemma_Eq_Trans;

      procedure Lemma_Swap_Trans (A0, A, B : Element_Array; X, Y : Positive) is
      begin
         Lemma_Swap (A, B, X, Y);
         Lemma_Same_Trans (A0, A, B);
      end Lemma_Swap_Trans;

      procedure Lemma_Occ_Eq (A, B : Element_Array; First : Positive; Last : Natural) is
      begin
         if First <= Last then
            Lemma_Occ_Eq (A, B, First, Last - 1);
         end if;
      end Lemma_Occ_Eq;

      procedure Lemma_Occ_Set
        (A, B : Element_Array; K : Positive; First : Positive; Last : Natural) is
      begin
         if Last > K then
            Lemma_Occ_Set (A, B, K, First, Last - 1);
         else
            Lemma_Occ_Eq (A, B, First, K - 1);
         end if;
      end Lemma_Occ_Set;

      procedure Lemma_Swap (A, B : Element_Array; X, Y : Positive) is
      begin
         if X = Y then
            Lemma_Occ_Eq (A, B, A'First, A'Last);
            return;
         end if;
         declare
            C : constant Element_Array := (A with delta X => A (Y));
         begin
            Lemma_Occ_Set (A, C, X, A'First, A'Last);
            Lemma_Occ_Set (C, B, Y, A'First, A'Last);
         end;
      end Lemma_Swap;

      procedure Lemma_Same_Perm (A, B : Element_Array) is null;

      procedure Lemma_Same_Trans (A, B, C : Element_Array) is null;

   end Perm_Lemmas;
   use Perm_Lemmas;

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

   function Prefix_Leq_Suffix
     (A                      : Element_Array;
      Lo_P, Hi_P, Lo_S, Hi_S : Natural) return Boolean
   is
     (Hi_P < Lo_P
      or else Hi_S < Lo_S
      or else
        (for all K in Lo_P .. Hi_P =>
           (for all L in Lo_S .. Hi_S => A (K) <= A (L))))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Lo_P >= A'First
       and then Hi_P <= A'Last
       and then Lo_S >= A'First
       and then Hi_S <= A'Last;

   ---------------------------------------------------------------------------
   --  Ghost counting for the cycle of Cycle_Step. While a cycle runs, the
   --  keys of the unsorted part are A (CS + 1 .. A'Last) plus the Item in
   --  hand (A (CS) is not rewritten until the cycle closes). Key V belongs
   --  in the block D (V) .. D (V) + C (V) - 1, where D (V) is CS plus the
   --  number of those keys below V and C (V) the number equal to V. A
   --  position is settled when it holds a key of its own block. Each write
   --  settles one more position and the blocks do not change, so a cycle
   --  makes at most A'Last - CS writes.
   ---------------------------------------------------------------------------

   --  Keys below V in A (CS + 1 .. I).
   function Lt (A : Element_Array; CS, I : Index; V : Integer) return Natural is
     (if I <= CS then 0
      else Lt (A, CS, I - 1, V) + (if A (I) < V then 1 else 0))
   with
     Ghost              => True,
     Global             => null,
     Pre                => In_Bounds (A) and then CS >= A'First and then I <= A'Last,
     Post               => Lt'Result <= (if I <= CS then 0 else I - CS),
     Subprogram_Variant => (Decreases => I);

   --  Keys equal to V in A (CS + 1 .. I).
   function Eq (A : Element_Array; CS, I : Index; V : Integer) return Natural is
     (if I <= CS then 0
      else Eq (A, CS, I - 1, V) + (if A (I) = V then 1 else 0))
   with
     Ghost              => True,
     Global             => null,
     Pre                => In_Bounds (A) and then CS >= A'First and then I <= A'Last,
     Post               => Eq'Result <= (if I <= CS then 0 else I - CS),
     Subprogram_Variant => (Decreases => I);

   function D (A : Element_Array; CS : Index; Item, V : Integer) return Natural is
     (CS + Lt (A, CS, A'Last, V) + (if Item < V then 1 else 0))
   with Ghost => True, Global => null, Pre => In_Bounds (A) and then CS >= A'First;

   function C (A : Element_Array; CS : Index; Item, V : Integer) return Natural is
     (Eq (A, CS, A'Last, V) + (if Item = V then 1 else 0))
   with Ghost => True, Global => null, Pre => In_Bounds (A) and then CS >= A'First;

   function Settled (A : Element_Array; CS : Index; Item : Integer; P : Index) return Boolean is
     (D (A, CS, Item, A (P)) <= P and then P < D (A, CS, Item, A (P)) + C (A, CS, Item, A (P)))
   with Ghost => True, Global => null,
        Pre => In_Bounds (A) and then CS >= A'First and then P in A'Range;

   --  Cycle_Step caches each position's block in ghost arrays: Lo (P) is
   --  where the block of A (P) starts and Hi (P) one past its end. Counting
   --  settled positions through the cache costs O(n) instead of O(n^2).
   type Nat_Array is array (Index range <>) of Natural with Ghost;

   function SX (Lo, Hi : Nat_Array; P : Index) return Boolean is
     (Lo (P) <= P and then P < Hi (P))
   with
     Ghost  => True,
     Global => null,
     Pre    => Hi'First = Lo'First and then Lo'Last = Hi'Last
               and then P in Lo'Range;

   --  Settled positions in CS + 1 .. I, read from the cache.
   function NSX (Lo, Hi : Nat_Array; CS, I : Index) return Natural is
     (if I <= CS then 0
      else NSX (Lo, Hi, CS, I - 1) + (if SX (Lo, Hi, I) then 1 else 0))
   with
     Ghost              => True,
     Global             => null,
     Pre                => Hi'First = Lo'First and then Lo'Last = Hi'Last
                           and then CS >= Lo'First and then I <= Lo'Last,
     Post               => NSX'Result <= (if I <= CS then 0 else I - CS),
     Subprogram_Variant => (Decreases => I);

   --  After one write at Pos, the counts over CS + 1 .. I move only by the
   --  old and the new key at Pos, for every key now in A (CS + 1 .. A'Last).
   function Update_Ok (Old, A : Element_Array; CS, Pos, I : Index) return Boolean is
     (for all P in CS + 1 .. A'Last =>
        Lt (A, CS, I, A (P)) + (if Pos <= I and then Old (Pos) < A (P) then 1 else 0)
        = Lt (Old, CS, I, A (P)) + (if Pos <= I and then A (Pos) < A (P) then 1 else 0)
        and then
        Eq (A, CS, I, A (P)) + (if Pos <= I and then Old (Pos) = A (P) then 1 else 0)
        = Eq (Old, CS, I, A (P)) + (if Pos <= I and then A (Pos) = A (P) then 1 else 0))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (Old) and then In_Bounds (A)
       and then A'First = Old'First and then A'Last = Old'Last
       and then CS >= A'First and then I <= A'Last and then Pos in A'Range;

   --  Induction lemmas, all proved by GNATprove at Level 4 and all checked
   --  at run time under -gnata, except the postcondition of Lemma_Update
   --  (see there).
   package Lemmas with Ghost is

      --  Below + equal never exceed the number of keys.
      procedure Lemma_Total (A : Element_Array; CS, I : Index; V : Integer)
      with
        Global             => null,
        Pre                =>
          In_Bounds (A) and then CS >= A'First and then I <= A'Last and then CS <= I,
        Post               => Lt (A, CS, I, V) + Eq (A, CS, I, V) <= I - CS,
        Subprogram_Variant => (Decreases => I);

      --  Blocks are ordered: every key below V2 counts towards Lt (V2).
      procedure Lemma_Order (A : Element_Array; CS, I : Index; V1, V2 : Integer)
      with
        Global             => null,
        Pre                =>
          In_Bounds (A) and then CS >= A'First and then I <= A'Last and then V1 < V2,
        Post               => Lt (A, CS, I, V1) + Eq (A, CS, I, V1) <= Lt (A, CS, I, V2),
        Subprogram_Variant => (Decreases => I);

      --  A run of V in Start .. I adds its length to Eq.
      procedure Lemma_Run (A : Element_Array; CS, Start, I : Index; V : Integer)
      with
        Global             => null,
        Pre                =>
          In_Bounds (A) and then CS >= A'First and then CS < Start and then Start - 1 <= I
          and then I <= A'Last
          and then (for all K in Start .. I => A (K) = V),
        Post               => Eq (A, CS, I, V) >= Eq (A, CS, Start - 1, V) + (I - Start + 1),
        Subprogram_Variant => (Decreases => I);

      --  Eq only grows with the range.
      procedure Lemma_Eq_Mono (A : Element_Array; CS, I, J : Index; V : Integer)
      with
        Global             => null,
        Pre                =>
          In_Bounds (A) and then CS >= A'First and then I <= J and then J <= A'Last,
        Post               => Eq (A, CS, I, V) <= Eq (A, CS, J, V),
        Subprogram_Variant => (Decreases => J);

      --  The count moves by one when exactly Pos goes from unsettled to
      --  settled.
      procedure Lemma_NSX_Step (Lo0, Hi0, Lo, Hi : Nat_Array; CS, Pos, I : Index)
      with
        Global             => null,
        Pre                =>
          Lo0'First = Lo'First and then Hi0'First = Lo'First
          and then Hi'First = Lo'First and then Lo0'Last = Lo'Last
          and then Hi0'Last = Lo'Last and then Hi'Last = Lo'Last
          and then CS >= Lo'First
          and then I <= Lo'Last and then Pos in CS + 1 .. Lo'Last
          and then (for all P in Lo'Range =>
                      (if P /= Pos then Lo (P) = Lo0 (P) and then Hi (P) = Hi0 (P)))
          and then not SX (Lo0, Hi0, Pos)
          and then SX (Lo, Hi, Pos),
        Post               =>
          NSX (Lo, Hi, CS, I) = NSX (Lo0, Hi0, CS, I) + (if Pos <= I then 1 else 0),
        Subprogram_Variant => (Decreases => I);

      --  An unsettled position leaves room below the bound.
      procedure Lemma_NSX_Gap (Lo, Hi : Nat_Array; CS, P, I : Index)
      with
        Global             => null,
        Pre                =>
          Hi'First = Lo'First and then Lo'Last = Hi'Last
          and then CS >= Lo'First
          and then I <= Lo'Last and then P in CS + 1 .. I
          and then not SX (Lo, Hi, P),
        Post               => NSX (Lo, Hi, CS, I) + 1 <= I - CS,
        Subprogram_Variant => (Decreases => I);

      --  Run-time cost: checking this postcondition at every level of the
      --  recursion is O(n^3) per write (about 8 s for the test suite), so it
      --  is not evaluated at run time. GNATprove proves it like every other
      --  contract, and Cycle_Step checks Update_Ok at the top level (I =
      --  A'Last) with an executed Assert after each write.
      pragma Assertion_Policy (Post => Ignore);

      --  One write at Pos: the counts move by the old and new key there.
      procedure Lemma_Update (Old, A : Element_Array; CS, Pos, I : Index)
      with
        Global             => null,
        Pre                =>
          In_Bounds (Old) and then In_Bounds (A)
          and then A'First = Old'First and then A'Last = Old'Last
          and then CS >= A'First
          and then I <= A'Last and then Pos in CS + 1 .. A'Last
          and then (for all K in A'Range => (if K /= Pos then A (K) = Old (K))),
        Post               =>
          Update_Ok (Old, A, CS, Pos, I),
        Subprogram_Variant => (Decreases => I);
   end Lemmas;

   package body Lemmas is

      procedure Lemma_Total (A : Element_Array; CS, I : Index; V : Integer)
      is
      begin
         if I > CS then
            Lemma_Total (A, CS, I - 1, V);
         end if;
      end Lemma_Total;

      procedure Lemma_Order (A : Element_Array; CS, I : Index; V1, V2 : Integer)
      is
      begin
         if I > CS then
            Lemma_Order (A, CS, I - 1, V1, V2);
         end if;
      end Lemma_Order;

      procedure Lemma_Run (A : Element_Array; CS, Start, I : Index; V : Integer)
      is
      begin
         if I >= Start then
            Lemma_Run (A, CS, Start, I - 1, V);
         end if;
      end Lemma_Run;

      procedure Lemma_Eq_Mono (A : Element_Array; CS, I, J : Index; V : Integer)
      is
      begin
         if J > I then
            Lemma_Eq_Mono (A, CS, I, J - 1, V);
         end if;
      end Lemma_Eq_Mono;

      procedure Lemma_Update (Old, A : Element_Array; CS, Pos, I : Index)
      is
      begin
         if I > CS then
            Lemma_Update (Old, A, CS, Pos, I - 1);
         end if;
      end Lemma_Update;

      procedure Lemma_NSX_Step (Lo0, Hi0, Lo, Hi : Nat_Array; CS, Pos, I : Index)
      is
      begin
         if I > CS then
            Lemma_NSX_Step (Lo0, Hi0, Lo, Hi, CS, Pos, I - 1);
         end if;
      end Lemma_NSX_Step;

      procedure Lemma_NSX_Gap (Lo, Hi : Nat_Array; CS, P, I : Index)
      is
      begin
         if I > P then
            Lemma_NSX_Gap (Lo, Hi, CS, P, I - 1);
         end if;
      end Lemma_NSX_Gap;

   end Lemmas;

   function Dest_Index
     (A : Element_Array; CS : Index; Item : Integer) return Index
   with
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then A'Length >= 1
       and then CS in A'Range,
     Post   =>
       Dest_Index'Result in CS .. A'Last
       and then Dest_Index'Result = CS + Lt (A, CS, A'Last, Item)
       and then
         (if Dest_Index'Result = CS then
            (for all K in CS + 1 .. A'Last => A (K) >= Item)
          else
            Dest_Index'Result > CS)
   is
      Pos : Index := CS;
   begin
      for I in CS + 1 .. A'Last loop
         pragma Loop_Invariant (Pos in CS .. I - 1);
         pragma Loop_Invariant (Pos = CS + Lt (A, CS, I - 1, Item));
         pragma Loop_Invariant
           (if Pos = CS then
              (for all K in CS + 1 .. I - 1 => A (K) >= Item));

         if A (I) < Item then
            Pos := Pos + 1;
         end if;
      end loop;
      return Pos;
   end Dest_Index;

   procedure Advance_Past_Equals
     (A    : Element_Array;
      Item : Integer;
      Pos  : in out Index)
   with
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then A'Length >= 1
       and then Pos in A'Range,
     Post   =>
       Pos in Pos'Old .. A'Last
       and then (for all K in Pos'Old .. Pos - 1 => A (K) = Item)
       and then (Pos = A'Last or else A (Pos) /= Item)
   is
   begin
      while Pos < A'Last and then Item = A (Pos) loop
         pragma Loop_Invariant (Pos in Pos'Loop_Entry .. A'Last - 1);
         pragma Loop_Invariant
           (for all K in Pos'Loop_Entry .. Pos => A (K) = Item);
         pragma Loop_Variant (Increases => Pos);
         Pos := Pos + 1;
      end loop;
   end Advance_Past_Equals;

   --  Where Advance_Past_Equals stops lies inside Item's block, holds a
   --  different key, and is not settled yet.
   procedure Lemma_Target
     (A : Element_Array; CS : Index; Item : Integer; Pos : Index)
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then CS in A'First .. A'Last - 1
       and then CS + Lt (A, CS, A'Last, Item) > CS
       and then Pos in CS + Lt (A, CS, A'Last, Item) .. A'Last
       and then (for all K in CS + Lt (A, CS, A'Last, Item) .. Pos - 1 => A (K) = Item)
       and then (Pos = A'Last or else A (Pos) /= Item),
     Post   =>
       A (Pos) /= Item
       and then D (A, CS, Item, Item) <= Pos
       and then Pos < D (A, CS, Item, Item) + C (A, CS, Item, Item)
       and then not Settled (A, CS, Item, Pos)
   is
      Start : constant Index := CS + Lt (A, CS, A'Last, Item);
   begin
      Lemmas.Lemma_Total (A, CS, A'Last, Item);
      if Pos > Start then
         Lemmas.Lemma_Run (A, CS, Start, Pos - 1, Item);
         Lemmas.Lemma_Eq_Mono (A, CS, Pos - 1, A'Last, Item);
      end if;
      Lemmas.Lemma_Total (A, CS, Start - 1, Item);
      if A (Pos) < Item then
         Lemmas.Lemma_Order (A, CS, A'Last, A (Pos), Item);
      else
         Lemmas.Lemma_Order (A, CS, A'Last, Item, A (Pos));
      end if;
   end Lemma_Target;

   --  One write. Cycle_Step keeps Count below Max_N: Count never exceeds
   --  the number of settled positions, and the slot written is unsettled.
   procedure Place_Item
     (A     : in out Element_Array;
      Pos   : Index;
      Item  : in out Integer;
      Count : in out Natural)
   with
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Pos in A'Range
       and then Count < Max_N,
     Post   =>
       In_Bounds (A)
       and then A (Pos) = Item'Old
       and then Item = A'Old (Pos)
       and then Count = Count'Old + 1
       and then Count <= Max_N
       and then
         (for all K in A'Range =>
            (if K /= Pos then A (K) = A'Old (K)))
   is
      Tmp : constant Integer := A (Pos);
   begin
      A (Pos) := Item;
      Item    := Tmp;
      Count   := Count + 1;
   end Place_Item;

   --  Final placement write (no need for the displaced value).
   procedure Write_At
     (A     : in out Element_Array;
      Pos   : Index;
      Value : Integer;
      Count : in out Natural)
   with
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Pos in A'Range
       and then Count < Max_N,
     Post   =>
       In_Bounds (A)
       and then A (Pos) = Value
       and then Count = Count'Old + 1
       and then Count <= Max_N
       and then
         (for all K in A'Range =>
            (if K /= Pos then A (K) = A'Old (K)))
   is
   begin
      A (Pos) := Value;
      Count   := Count + 1;
   end Write_At;

   procedure Cycle_Step
     (A      : in out Element_Array;
      CS     : Index;
      Writes : out Natural)
   with
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then A'Length >= 2
       and then CS in A'First .. A'Last - 1
       and then Sorted_Slice (A, A'First, CS - 1)
       and then Prefix_Leq_Suffix (A, A'First, CS - 1, CS, A'Last),
     Post   =>
       In_Bounds (A)
       and then Sorted_Slice (A, A'First, CS)
       and then Prefix_Leq_Suffix (A, A'First, CS, CS + 1, A'Last)
       and then Writes <= Max_N
       and then
         (for all K in A'First .. CS - 1 => A (K) = A'Old (K))
       and then Same_Occ (A'Old, A)
   is
      A0       : constant Element_Array := A with Ghost;
      Cur, Cur0 : Element_Array (A'Range) with Ghost;
      Item     : Integer := A (CS);
      Pos      : Index;
      Count    : Natural := 0;
      Old      : Element_Array (A'Range) with Ghost;
      Old_Item : Integer with Ghost;
      Lo, Hi   : Nat_Array (A'Range) := [others => 0] with Ghost;
      Lo0, Hi0 : Nat_Array (A'Range) with Ghost;
   begin
      Writes := 0;
      Pos := Dest_Index (A, CS, Item);

      if Pos = CS then
         pragma Assert (for all K in CS + 1 .. A'Last => A (K) >= Item);
         pragma Assert (CS = A'First or else A (CS - 1) <= Item);
         pragma Assert (Sorted_Slice (A, A'First, CS));
         pragma Assert (Prefix_Leq_Suffix (A, A'First, CS, CS + 1, A'Last));
         return;
      end if;

      Advance_Past_Equals (A, Item, Pos);
      Lemma_Target (A, CS, Item, Pos);
      --  Counts: Cur is A with Item put back at CS (slot CS keeps a stale
      --  copy until the last write); Cur holds the input's values.
      Cur := A;
      Lemma_Same_Refl (A0);
      Lemma_Eq_Trans (A0, A0, Cur);
      for P in CS + 1 .. A'Last loop
         pragma Loop_Invariant
           (for all Q in CS + 1 .. P - 1 =>
              Lo (Q) = D (A, CS, Item, A (Q))
              and then Hi (Q) = Lo (Q) + C (A, CS, Item, A (Q)));
         Lo (P) := D (A, CS, Item, A (P));
         Hi (P) := Lo (P) + C (A, CS, Item, A (P));
      end loop;

      --  Each pass writes Item into an unsettled slot of its own block,
      --  settling it; the cycle closes when Item belongs at CS.
      loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Pos in CS + 1 .. A'Last);
         pragma Loop_Invariant (A (Pos) /= Item);
         pragma Loop_Invariant (D (A, CS, Item, Item) <= Pos);
         pragma Loop_Invariant
           (Pos < D (A, CS, Item, Item) + C (A, CS, Item, Item));
         pragma Loop_Invariant (not Settled (A, CS, Item, Pos));
         pragma Loop_Invariant
           (for all P in CS + 1 .. A'Last =>
              Lo (P) = D (A, CS, Item, A (P))
              and then Hi (P) = Lo (P) + C (A, CS, Item, A (P)));
         pragma Loop_Invariant (Count <= NSX (Lo, Hi, CS, A'Last));
         pragma Loop_Invariant (Sorted_Slice (A, A'First, CS - 1));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, A'First, CS - 1, CS, A'Last));
         pragma Loop_Invariant
           (for all K in A'First .. CS - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (CS = A'First
            or else (for all K in A'First .. CS - 1 => A (K) <= Item));
         pragma Loop_Invariant (Cur (CS) = Item);
         pragma Loop_Invariant
           (for all K in A'Range => (if K /= CS then Cur (K) = A (K)));
         pragma Loop_Invariant (Same_Occ (A0, Cur));
         pragma Loop_Variant (Increases => NSX (Lo, Hi, CS, A'Last));

         Lemmas.Lemma_NSX_Gap (Lo, Hi, CS, Pos, A'Last);
         Old := A;
         Old_Item := Item;
         Lo0 := Lo;
         Hi0 := Hi;
         Place_Item (A, Pos, Item, Count);
         --  On Cur the write is an exchange of slots CS and Pos.
         Cur0 := Cur;
         Cur (CS) := Item;
         Cur (Pos) := A (Pos);
         Lemma_Swap_Trans (A0, Cur0, Cur, CS, Pos);

         --  The blocks are unchanged, so Pos is now settled and nothing
         --  else changed.
         Lemmas.Lemma_Update (Old, A, CS, Pos, A'Last);
         pragma Assert (Update_Ok (Old, A, CS, Pos, A'Last));
         pragma Assert
           (for all P in CS + 1 .. A'Last =>
              D (A, CS, Item, A (P)) = D (Old, CS, Old_Item, A (P))
              and then C (A, CS, Item, A (P)) = C (Old, CS, Old_Item, A (P)));
         pragma Assert (Settled (A, CS, Item, Pos));
         Lo (Pos) := D (A, CS, Item, A (Pos));
         Hi (Pos) := Lo (Pos) + C (A, CS, Item, A (Pos));
         Lemmas.Lemma_NSX_Step (Lo0, Hi0, Lo, Hi, CS, Pos, A'Last);

         Pos := Dest_Index (A, CS, Item);
         exit when Pos = CS;

         Advance_Past_Equals (A, Item, Pos);
         Lemma_Target (A, CS, Item, Pos);
      end loop;

      --  Item belongs at CS: every later key is >= Item.
      pragma Assert (for all K in CS + 1 .. A'Last => A (K) >= Item);
      Write_At (A, CS, Item, Count);
      Lemma_Eq_Trans (A0, Cur, A);
      Writes := Count;
      pragma Assert (CS = A'First or else A (CS - 1) <= A (CS));
      pragma Assert (Sorted_Slice (A, A'First, CS));
      pragma Assert (Prefix_Leq_Suffix (A, A'First, CS, CS + 1, A'Last));
   end Cycle_Step;

   procedure Sort (A : in out Element_Array) is
      W     : Natural;
      Total : Natural := 0;
      A0    : constant Element_Array := A with Ghost;
      Prev  : Element_Array (A'Range) with Ghost;
   begin
      if A'Length <= 1 then
         Lemma_Same_Perm (A, A0);
         return;
      end if;

      pragma Assert (Sorted_Slice (A, A'First, A'First - 1));
      pragma Assert
        (Prefix_Leq_Suffix (A, A'First, A'First - 1, A'First, A'Last));

      for CS in A'First .. A'Last - 1 loop
         Prev := A;
         Cycle_Step (A, CS, W);
         Lemma_Same_Trans (A0, Prev, A);
         Total := Total + W;

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, A'First, CS));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, A'First, CS, CS + 1, A'Last));
         pragma Loop_Invariant (Is_Sorted (A (A'First .. CS)));
         pragma Loop_Invariant (Total <= (CS - A'First + 1) * Max_N);
         pragma Loop_Invariant (Same_Occ (A0, A));
      end loop;

      pragma Assert (Sorted_Slice (A, A'First, A'Last - 1));
      pragma Assert
        (Prefix_Leq_Suffix (A, A'First, A'Last - 1, A'Last, A'Last));
      pragma Assert (Is_Sorted (A));
      Lemma_Same_Perm (A, A0);
   end Sort;

   procedure Sort_Counting_Writes
     (A      : in out Element_Array;
      Writes : out Natural)
   is
      W    : Natural;
      A0   : constant Element_Array := A with Ghost;
      Prev : Element_Array (A'Range) with Ghost;
   begin
      Writes := 0;

      if A'Length <= 1 then
         Lemma_Same_Perm (A, A0);
         return;
      end if;

      pragma Assert (Sorted_Slice (A, A'First, A'First - 1));
      pragma Assert
        (Prefix_Leq_Suffix (A, A'First, A'First - 1, A'First, A'Last));

      for CS in A'First .. A'Last - 1 loop
         Prev := A;
         Cycle_Step (A, CS, W);
         Lemma_Same_Trans (A0, Prev, A);
         pragma Assert (W <= Max_N);
         pragma Assert (Writes <= (CS - A'First) * Max_N);
         Writes := Writes + W;

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, A'First, CS));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, A'First, CS, CS + 1, A'Last));
         pragma Loop_Invariant (Is_Sorted (A (A'First .. CS)));
         pragma Loop_Invariant (Writes <= (CS - A'First + 1) * Max_N);
         pragma Loop_Invariant (Same_Occ (A0, A));
      end loop;

      pragma Assert (Sorted_Slice (A, A'First, A'Last - 1));
      pragma Assert
        (Prefix_Leq_Suffix (A, A'First, A'Last - 1, A'Last, A'Last));
      pragma Assert (Is_Sorted (A));
      Lemma_Same_Perm (A, A0);
   end Sort_Counting_Writes;

end Cycle_Sort;
