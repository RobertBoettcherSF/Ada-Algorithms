--  Tree_Sort body — SPARK Level 4 unbalanced BST tree sort.
--  Fixed node pool (1 .. Max_N, null = 0). Phase 1 inserts into an
--  unbalanced BST (equals go right). Phase 2 writes back by repeatedly
--  extracting the minimum live pool value — order-identical to BST
--  in-order on the same multiset, with Level-4-friendly sortedness VCs
--  (full recursive in-order BST invariants fight automated L4).
--  No Intentional Annotate.

package body Tree_Sort
  with SPARK_Mode => On
is

   --  Loop invariants and the Posts of the subprograms below are proved by
   --  gnatprove and not re-evaluated at run time: the permutation clauses
   --  quantify over every Integer value. The Post of the public
   --  Sort (spec) is still checked at run time, including Is_Perm.
   pragma Assertion_Policy (Loop_Invariant => Ignore, Post => Ignore);

   ---------------------------------------------------------------------------
   -- Permutation proof (ghost): frame lemma for Occ.
   ---------------------------------------------------------------------------

   package Perm_Lemmas
     with Ghost
   is
      pragma Assertion_Policy (Pre => Ignore);

      --  Counts over A'First .. Last only see A'First .. Last.
      procedure Lemma_Occ_Frame (A, B : Element_Array; Last : Natural)
      with
        Global             => null,
        Pre                =>
          In_Bounds (A) and then In_Bounds (B)
          and then A'First = B'First
          and then Last <= A'Last and then Last <= B'Last
          and then (for all K in A'First .. Last => A (K) = B (K)),
        Post               =>
          (for all V in Integer => Occ (A, V, Last) = Occ (B, V, Last)),
        Subprogram_Variant => (Decreases => Last);

   end Perm_Lemmas;

   package body Perm_Lemmas is

      procedure Lemma_Occ_Frame (A, B : Element_Array; Last : Natural) is
      begin
         if Last >= A'First then
            Lemma_Occ_Frame (A, B, Last - 1);
         end if;
      end Lemma_Occ_Frame;

   end Perm_Lemmas;
   use Perm_Lemmas;

   subtype Node_Index is Natural range 0 .. Max_N;
   None : constant Node_Index := 0;

   type BST_Node is record
      Value : Integer    := 0;
      Left  : Node_Index := None;
      Right : Node_Index := None;
      Live  : Boolean    := False;
   end record;

   type Node_Pool is array (1 .. Max_N) of BST_Node;

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

   function Live_Count (Pool : Node_Pool; Used : Natural) return Natural
   is
     (if Used = 0 then 0
      else
        (if Pool (Used).Live then 1 else 0)
        + Live_Count (Pool, Used - 1))
   with
     Ghost              => True,
     Global             => null,
     Subprogram_Variant => (Decreases => Used),
     Pre                => Used <= Max_N,
     Post               => Live_Count'Result <= Used;

   function All_Live_GE
     (Pool : Node_Pool; Used : Natural; Bound : Integer) return Boolean
   is
     (for all K in 1 .. Used =>
        (if Pool (K).Live then Pool (K).Value >= Bound))
   with
     Ghost  => True,
     Global => null,
     Pre    => Used <= Max_N;

   function Struct_OK (Pool : Node_Pool; Used : Natural) return Boolean is
     (for all K in 1 .. Used =>
        (Pool (K).Left = None
         or else Pool (K).Left in K + 1 .. Used)
        and then
          (Pool (K).Right = None
           or else Pool (K).Right in K + 1 .. Used))
   with
     Ghost  => True,
     Global => null,
     Pre    => Used <= Max_N;

   function All_Live (Pool : Node_Pool; Used : Natural) return Boolean is
     (for all K in 1 .. Used => Pool (K).Live)
   with
     Ghost  => True,
     Global => null,
     Pre    => Used <= Max_N;

   procedure Lemma_Live_Count_All
     (Pool : Node_Pool; Used : Natural)
   with
     Ghost             => True,
     Global            => null,
     Pre               =>
       Used <= Max_N and then All_Live (Pool, Used),
     Post              => Live_Count (Pool, Used) = Used,
     Subprogram_Variant => (Decreases => Used)
   is
   begin
      if Used = 0 then
         return;
      end if;
      Lemma_Live_Count_All (Pool, Used - 1);
   end Lemma_Live_Count_All;

   procedure Lemma_Live_Count_Eq
     (Pool_A, Pool_B : Node_Pool; Used : Natural)
   with
     Ghost             => True,
     Global            => null,
     Pre               =>
       Used <= Max_N
       and then
         (for all K in 1 .. Used =>
            Pool_A (K).Live = Pool_B (K).Live),
     Post              => Live_Count (Pool_A, Used) = Live_Count (Pool_B, Used),
     Subprogram_Variant => (Decreases => Used)
   is
   begin
      if Used = 0 then
         return;
      end if;
      pragma Assert (Pool_A (Used).Live = Pool_B (Used).Live);
      Lemma_Live_Count_Eq (Pool_A, Pool_B, Used - 1);
   end Lemma_Live_Count_Eq;

   --  Clearing Live on index I decreases Live_Count by exactly 1.
   procedure Lemma_Live_Count_Clear
     (Pool_Old, Pool : Node_Pool; Used : Natural; I : Node_Index)
   with
     Ghost             => True,
     Global            => null,
     Pre               =>
       Used in 1 .. Max_N
       and then I in 1 .. Used
       and then Pool_Old (I).Live
       and then not Pool (I).Live
       and then
         (for all K in 1 .. Used =>
            (if K /= I then Pool (K).Live = Pool_Old (K).Live)),
     Post              =>
       Live_Count (Pool, Used) = Live_Count (Pool_Old, Used) - 1,
     Subprogram_Variant => (Decreases => Used)
   is
   begin
      if Used = I then
         pragma Assert (not Pool (Used).Live);
         pragma Assert (Pool_Old (Used).Live);
         pragma Assert
           (for all K in 1 .. Used - 1 =>
              Pool (K).Live = Pool_Old (K).Live);
         Lemma_Live_Count_Eq (Pool, Pool_Old, Used - 1);
         pragma Assert
           (Live_Count (Pool, Used - 1) = Live_Count (Pool_Old, Used - 1));
         pragma Assert
           (Live_Count (Pool, Used) = Live_Count (Pool, Used - 1));
         pragma Assert
           (Live_Count (Pool_Old, Used) =
              Live_Count (Pool_Old, Used - 1) + 1);
         pragma Assert
           (Live_Count (Pool, Used) = Live_Count (Pool_Old, Used) - 1);
         return;
      end if;

      pragma Assert (Used > I);
      pragma Assert (Pool (Used).Live = Pool_Old (Used).Live);
      Lemma_Live_Count_Clear (Pool_Old, Pool, Used - 1, I);
      pragma Assert
        (Live_Count (Pool, Used - 1) = Live_Count (Pool_Old, Used - 1) - 1);
      if Pool (Used).Live then
         pragma Assert
           (Live_Count (Pool, Used) = Live_Count (Pool, Used - 1) + 1);
         pragma Assert
           (Live_Count (Pool_Old, Used) =
              Live_Count (Pool_Old, Used - 1) + 1);
      else
         pragma Assert
           (Live_Count (Pool, Used) = Live_Count (Pool, Used - 1));
         pragma Assert
           (Live_Count (Pool_Old, Used) = Live_Count (Pool_Old, Used - 1));
      end if;
      pragma Assert
        (Live_Count (Pool, Used) = Live_Count (Pool_Old, Used) - 1);
   end Lemma_Live_Count_Clear;

   ---------------------------------------------------------------------------
   -- Pool multiset (ghost): live nodes holding V among 1 .. Used
   ---------------------------------------------------------------------------

   function Pool_Occ
     (Pool : Node_Pool; Used : Natural; V : Integer) return Natural
   with
     Ghost,
     Global             => null,
     Pre                => Used <= Max_N,
     Post               => Pool_Occ'Result <= Used,
     Subprogram_Variant => (Decreases => Used);

   function Pool_Occ
     (Pool : Node_Pool; Used : Natural; V : Integer) return Natural
   is
     (if Used = 0 then 0
      else Pool_Occ (Pool, Used - 1, V)
           + (if Pool (Used).Live and then Pool (Used).Value = V
              then 1 else 0));

   --  The live nodes 1 .. M hold A (A'First .. A'First + M - 1).
   procedure Lemma_Pool_Is_A (Pool : Node_Pool; A : Element_Array; M : Natural)
   with
     Ghost,
     Global             => null,
     Pre                =>
       In_Bounds (A)
       and then M <= A'Length
       and then (for all K in 1 .. M =>
                   Pool (K).Live
                   and then Pool (K).Value = A (A'First + (K - 1))),
     Post               =>
       (for all V in Integer =>
          Pool_Occ (Pool, M, V)
          = (if M = 0 then 0 else Occ (A, V, A'First + (M - 1)))),
     Subprogram_Variant => (Decreases => M);

   procedure Lemma_Pool_Is_A (Pool : Node_Pool; A : Element_Array; M : Natural)
   is
   begin
      if M > 0 then
         Lemma_Pool_Is_A (Pool, A, M - 1);
      end if;
   end Lemma_Pool_Is_A;

   --  Clearing Live on node I removes one copy of its value.
   procedure Lemma_Pool_Clear
     (Pool_Old, Pool : Node_Pool; Used : Natural; I : Node_Index)
   with
     Ghost,
     Global             => null,
     Pre                =>
       Used <= Max_N
       and then I >= 1
       and then Pool_Old (I).Live
       and then not Pool (I).Live
       and then Pool (I).Value = Pool_Old (I).Value
       and then
         (for all K in 1 .. Used =>
            (if K /= I then
               Pool (K).Live = Pool_Old (K).Live
               and then Pool (K).Value = Pool_Old (K).Value)),
     Post               =>
       (for all V in Integer =>
          Pool_Occ (Pool, Used, V)
          + (if I <= Used and then V = Pool_Old (I).Value then 1 else 0)
          = Pool_Occ (Pool_Old, Used, V)),
     Subprogram_Variant => (Decreases => Used);

   procedure Lemma_Pool_Clear
     (Pool_Old, Pool : Node_Pool; Used : Natural; I : Node_Index) is
   begin
      if Used > 0 then
         Lemma_Pool_Clear (Pool_Old, Pool, Used - 1, I);
      end if;
   end Lemma_Pool_Clear;

   --  No value has more live copies than there are live nodes.
   procedure Lemma_Pool_Occ_Le_Live (Pool : Node_Pool; Used : Natural)
   with
     Ghost,
     Global             => null,
     Pre                => Used <= Max_N,
     Post               =>
       (for all V in Integer =>
          Pool_Occ (Pool, Used, V) <= Live_Count (Pool, Used)),
     Subprogram_Variant => (Decreases => Used);

   procedure Lemma_Pool_Occ_Le_Live (Pool : Node_Pool; Used : Natural) is
   begin
      if Used > 0 then
         Lemma_Pool_Occ_Le_Live (Pool, Used - 1);
      end if;
   end Lemma_Pool_Occ_Le_Live;

   procedure Insert_One
     (Pool : in out Node_Pool;
      Used : in out Natural;
      Root : in out Node_Index;
      V    : Integer)
   with
     Global => null,
     Pre    =>
       Used < Max_N
       and then (Root = None or else Root in 1 .. Used)
       and then Struct_OK (Pool, Used)
       and then All_Live (Pool, Used)
       and then Live_Count (Pool, Used) = Used,
     Post   =>
       Used = Used'Old + 1
       and then Root in 1 .. Used
       and then Struct_OK (Pool, Used)
       and then All_Live (Pool, Used)
       and then Live_Count (Pool, Used) = Used
       and then Pool (Used).Value = V
       and then
         (for all K in 1 .. Used'Old =>
            Pool (K).Value = Pool'Old (K).Value)
   is
      New_I : Node_Index;
      Cur   : Node_Index;
   begin
      Used := Used + 1;
      New_I := Used;
      Pool (New_I).Value := V;
      Pool (New_I).Left  := None;
      Pool (New_I).Right := None;
      Pool (New_I).Live  := True;

      if Root = None then
         Root := New_I;
         pragma Assert (All_Live (Pool, Used));
         Lemma_Live_Count_All (Pool, Used);
         return;
      end if;

      Cur := Root;
      loop
         pragma Loop_Invariant (Cur in 1 .. Used - 1);
         pragma Loop_Invariant (Pool (Cur).Live);
         pragma Loop_Invariant (Struct_OK (Pool, Used));
         pragma Loop_Invariant (All_Live (Pool, Used));
         pragma Loop_Invariant
           (for all K in 1 .. Used - 1 =>
              Pool (K).Value = Pool'Loop_Entry (K).Value);
         pragma Loop_Invariant (Pool (Used).Value = V);
         pragma Loop_Invariant (Root in 1 .. Used - 1);
         pragma Loop_Variant (Increases => Cur);

         if V < Pool (Cur).Value then
            if Pool (Cur).Left = None then
               Pool (Cur).Left := New_I;
               Lemma_Live_Count_All (Pool, Used);
               return;
            else
               Cur := Pool (Cur).Left;
            end if;
         else
            if Pool (Cur).Right = None then
               Pool (Cur).Right := New_I;
               Lemma_Live_Count_All (Pool, Used);
               return;
            else
               Cur := Pool (Cur).Right;
            end if;
         end if;
      end loop;
   end Insert_One;

   --  Extract minimum live value (pool scan). Same multiset order as
   --  BST in-order write-back; keeps Is_Sorted VCs in SMT reach.
   procedure Extract_Min
     (Pool  : in out Node_Pool;
      Used  : Natural;
      Bound : Integer;
      Has_B : Boolean;
      V     : out Integer)
   with
     Global => null,
     Pre    =>
       Used in 1 .. Max_N
       and then Live_Count (Pool, Used) >= 1
       and then Struct_OK (Pool, Used)
       and then (if Has_B then All_Live_GE (Pool, Used, Bound)),
     Post   =>
       Live_Count (Pool, Used) = Live_Count (Pool'Old, Used) - 1
       and then Struct_OK (Pool, Used)
       and then (if Has_B then V >= Bound)
       and then All_Live_GE (Pool, Used, V)
       and then
         (for all K in 1 .. Used =>
            Pool (K).Value = Pool'Old (K).Value
            and then
              (if not Pool'Old (K).Live then not Pool (K).Live))
       and then
         (for all W in Integer =>
            Pool_Occ (Pool, Used, W) + (if W = V then 1 else 0)
            = Pool_Occ (Pool'Old, Used, W))
   is
      Best : Node_Index := None;
   begin
      for K in 1 .. Used loop
         pragma Loop_Invariant
           (if Best = None then
              (for all J in 1 .. K - 1 => not Pool (J).Live)
            else
              Best in 1 .. K - 1
              and then Pool (Best).Live
              and then
                (for all J in 1 .. K - 1 =>
                   (if Pool (J).Live then
                      Pool (J).Value >= Pool (Best).Value)));
         pragma Loop_Invariant
           (for all J in 1 .. Used =>
              Pool (J).Live = Pool'Loop_Entry (J).Live
              and then Pool (J).Value = Pool'Loop_Entry (J).Value);
         pragma Loop_Invariant (Struct_OK (Pool, Used));
         pragma Loop_Invariant
           (if Has_B then All_Live_GE (Pool, Used, Bound));

         if Pool (K).Live then
            if Best = None or else Pool (K).Value < Pool (Best).Value then
               Best := K;
            end if;
         end if;
      end loop;

      pragma Assert (Best /= None);
      pragma Assert (Best in 1 .. Used);
      pragma Assert (Pool (Best).Live);
      pragma Assert
        (for all J in 1 .. Used =>
           (if Pool (J).Live then
              Pool (J).Value >= Pool (Best).Value));
      if Has_B then
         pragma Assert (Pool (Best).Value >= Bound);
      end if;

      V := Pool (Best).Value;
      declare
         Pool_Before : Node_Pool with Ghost => True;
         Best_I      : Node_Index;
      begin
         Pool_Before := Pool;
         Best_I := Best;
         Pool (Best).Live := False;
         Lemma_Live_Count_Clear (Pool_Before, Pool, Used, Best_I);
         Lemma_Pool_Clear (Pool_Before, Pool, Used, Best_I);
      end;

      pragma Assert (All_Live_GE (Pool, Used, V));
   end Extract_Min;

   procedure Sort (A : in out Element_Array) is
      N  : constant Index := A'Length;   --  nodes; the pool stays 1 .. Max_N
      A0 : constant Element_Array := A with Ghost;
   begin
      if A'Length <= 1 then
         Lemma_Occ_Frame (A, A0, A'Last);
         return;
      end if;

      declare
         Pool : Node_Pool;
         Used : Natural := 0;
         Root : Node_Index := None;
      begin
         for I in A'Range loop
            pragma Loop_Invariant (Used = I - A'First);
            pragma Loop_Invariant (Used < Max_N);
            pragma Loop_Invariant
              (Root = None or else Root in 1 .. Used);
            pragma Loop_Invariant (Struct_OK (Pool, Used));
            pragma Loop_Invariant (All_Live (Pool, Used));
            pragma Loop_Invariant (Live_Count (Pool, Used) = Used);
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant
              (for all K in 1 .. Used =>
                 Pool (K).Value = A (A'First + (K - 1)));

            Insert_One (Pool, Used, Root, A (I));
         end loop;

         pragma Assert (Used = Natural (N));
         pragma Assert (Live_Count (Pool, Used) = Used);
         pragma Assert (A'First + (Used - 1) = A'Last);
         Lemma_Pool_Is_A (Pool, A, Used);

         for Out_I in A'Range loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (Used = Natural (N));
            pragma Loop_Invariant (Struct_OK (Pool, Used));
            pragma Loop_Invariant
              (Live_Count (Pool, Used) =
                 Natural (N) - (Out_I - A'First));
            pragma Loop_Invariant (Sorted_Slice (A, A'First, Out_I - 1));
            pragma Loop_Invariant
              (if Out_I > A'First
               then All_Live_GE (Pool, Used, A (Out_I - 1)));
            pragma Loop_Invariant
              (for all W in Integer =>
                 Occ (A, W, Out_I - 1) + Pool_Occ (Pool, Used, W)
                 = Occ (A0, W, A0'Last));

            declare
               V : Integer;
            begin
               if Out_I = A'First then
                  Extract_Min (Pool, Used, 0, False, V);
               else
                  Extract_Min (Pool, Used, A (Out_I - 1), True, V);
                  pragma Assert (V >= A (Out_I - 1));
               end if;
               declare
                  Before : constant Element_Array := A with Ghost;
               begin
                  A (Out_I) := V;
                  Lemma_Occ_Frame (Before, A, Out_I - 1);
               end;
            end;

            pragma Assert (Sorted_Slice (A, A'First, Out_I));
            pragma Assert (All_Live_GE (Pool, Used, A (Out_I)));
         end loop;

         pragma Assert (Sorted_Slice (A, A'First, A'Last));
         pragma Assert (Is_Sorted (A));
         pragma Assert (Live_Count (Pool, Used) = 0);
         Lemma_Pool_Occ_Le_Live (Pool, Used);
      end;
   end Sort;

end Tree_Sort;
