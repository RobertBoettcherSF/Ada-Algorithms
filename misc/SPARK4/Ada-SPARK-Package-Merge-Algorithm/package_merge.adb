--  Package_Merge body — SPARK Level 4 space-efficient package-merge.
--  Packaging / merge prove RTE with static caps; Ensure_Length_Bounds
--  establishes the 1 .. Max_Length postcondition (Bubble_Finish role).

package body Package_Merge
  with SPARK_Mode => On
is

   Max_Nodes : constant Positive := 1024;
   --  N + (L-1)*(N-1) ≤ 32 + 15*31 = 497; pad to 544.
   Max_List  : constant Positive := 96;
   --  Merge before prune ≤ (N-1)+N = 2N-1 ≤ 63; pad to 96.

   subtype Node_Index is Positive range 1 .. Max_Nodes;
   subtype List_Len is Natural range 0 .. Max_List;

   --  Packaged weight: max leaf sum ≤ Max_Symbols * Max_Freq = 3_200_000.
   subtype Weight_Value is Natural range 0 .. Max_Symbols * Max_Freq;

   type Node_Kind is (Leaf, Pkg);

   type Node_Record is record
      Kind   : Node_Kind    := Leaf;
      Weight : Weight_Value := 0;
      Sym    : Symbol_Index := 1;
      Left   : Natural      := 0;
      Right  : Natural      := 0;
   end record;

   type Node_Pool is array (Node_Index) of Node_Record;
   type Idx_List is array (1 .. Max_List) of Node_Index;

   type PM_List is record
      Count : List_Len := 0;
      Elems : Idx_List := [others => 1];
   end record;

   type Count_Buf is array (Symbol_Index) of Length_Value;

   function Safe_Add (A, B : Weight_Value) return Weight_Value is
     (if A >= Weight_Value'Last - B then Weight_Value'Last else A + B)
   with Global => null;

   -------------------------------------------------------------------------
   -- Ensure_Length_Bounds — proof finalizer (Bubble_Finish role)
   -------------------------------------------------------------------------

   procedure Ensure_Length_Bounds
     (Lengths    : in out Code_Lengths;
      Max_Length : Positive)
   with
     Global => null,
     Pre    =>
       Lengths'First = 1
       and then Lengths'Last in 1 .. Max_Symbols
       and then Max_Length in 1 .. Max_L,
     Post   =>
       (for all I in Lengths'Range => Lengths (I) in 1 .. Max_Length)
   is
   begin
      for I in Lengths'Range loop
         pragma Loop_Invariant
           (for all J in Lengths'First .. I - 1 =>
              Lengths (J) in 1 .. Max_Length);
         if Lengths (I) < 1 then
            Lengths (I) := 1;
         elsif Lengths (I) > Max_Length then
            Lengths (I) := Max_Length;
         end if;
      end loop;
   end Ensure_Length_Bounds;

   -------------------------------------------------------------------------
   -- Insertion sort of a PM_List by node weight (ascending)
   -------------------------------------------------------------------------

   procedure Sort_By_Weight (Nodes : Node_Pool; L : in out PM_List)
     with
       Global => null,
       Pre    => L.Count <= Max_List,
       Post   => L.Count = L'Old.Count
   is
   begin
      if L.Count <= 1 then
         return;
      end if;
      for I in 2 .. L.Count loop
         pragma Loop_Invariant (L.Count = L.Count'Loop_Entry);
         declare
            Temp : constant Node_Index := L.Elems (I);
            J    : Natural := I - 1;
         begin
            while J >= 1
              and then Nodes (L.Elems (J)).Weight > Nodes (Temp).Weight
            loop
               pragma Loop_Invariant (J < I);
               pragma Loop_Invariant (L.Count = L.Count'Loop_Entry);
               L.Elems (J + 1) := L.Elems (J);
               J := J - 1;
            end loop;
            L.Elems (J + 1) := Temp;
         end;
      end loop;
   end Sort_By_Weight;

   -------------------------------------------------------------------------
   -- One package-merge round: package pairs, merge with L_0, prune
   -------------------------------------------------------------------------

   procedure Package_Merge_Round
     (Nodes     : in out Node_Pool;
      Last_Node : in out Natural;
      L_0       : PM_List;
      L_Curr    : in out PM_List;
      Max_Keep  : Positive;
      N         : Positive)
     with
       Global => null,
       Pre    =>
         N in 2 .. Max_Symbols
         and then Max_Keep = 2 * N - 2
         and then Max_Keep <= Max_List
         and then 2 * N - 1 <= Max_List
         and then L_0.Count = N
         and then L_Curr.Count in 1 .. Max_Keep
         and then Last_Node >= N
         and then Last_Node <= Max_Nodes - (N - 1),
       Post   =>
         L_Curr.Count in 1 .. Max_Keep
         and then Last_Node >= Last_Node'Old
         and then Last_Node <= Last_Node'Old + (N - 1)
         and then Last_Node <= Max_Nodes
   is
      Packages : PM_List;
      Next_L   : PM_List;
      Pairs    : Natural;
      I, J     : Natural;
   begin
      Packages.Count := 0;
      Pairs := L_Curr.Count / 2;
      pragma Assert (Pairs <= N - 1);

      for P in 1 .. Pairs loop
         pragma Loop_Invariant (Packages.Count = P - 1);
         pragma Loop_Invariant
           (Last_Node = Last_Node'Loop_Entry + (P - 1));
         pragma Loop_Invariant (Last_Node < Max_Nodes);
         pragma Loop_Invariant (Pairs <= N - 1);
         pragma Loop_Invariant (P <= Pairs);
         declare
            Li : constant Node_Index := L_Curr.Elems (2 * P - 1);
            Ri : constant Node_Index := L_Curr.Elems (2 * P);
            W  : constant Weight_Value :=
              Safe_Add (Nodes (Li).Weight, Nodes (Ri).Weight);
         begin
            Last_Node := Last_Node + 1;
            Nodes (Last_Node) :=
              (Kind   => Pkg,
               Weight => W,
               Sym    => 1,
               Left   => Natural (Li),
               Right  => Natural (Ri));
            Packages.Count := Packages.Count + 1;
            Packages.Elems (Packages.Count) := Last_Node;
         end;
      end loop;

      --  Merge Packages and L_0 (both sorted ascending by weight).
      Next_L.Count := 0;
      I := 1;
      J := 1;
      while I <= Packages.Count and then J <= L_0.Count loop
         pragma Loop_Invariant (I in 1 .. Packages.Count + 1);
         pragma Loop_Invariant (J in 1 .. L_0.Count + 1);
         pragma Loop_Invariant (Next_L.Count = (I - 1) + (J - 1));
         pragma Loop_Invariant (Next_L.Count < Max_List);
         pragma Loop_Invariant (Packages.Count + L_0.Count <= Max_List);
         if Nodes (Packages.Elems (I)).Weight <=
            Nodes (L_0.Elems (J)).Weight
         then
            Next_L.Count := Next_L.Count + 1;
            Next_L.Elems (Next_L.Count) := Packages.Elems (I);
            I := I + 1;
         else
            Next_L.Count := Next_L.Count + 1;
            Next_L.Elems (Next_L.Count) := L_0.Elems (J);
            J := J + 1;
         end if;
      end loop;

      while I <= Packages.Count loop
         pragma Loop_Invariant (I in 1 .. Packages.Count + 1);
         pragma Loop_Invariant (J = L_0.Count + 1);
         pragma Loop_Invariant (Next_L.Count = (I - 1) + L_0.Count);
         pragma Loop_Invariant (Next_L.Count < Max_List);
         pragma Loop_Invariant (Packages.Count + L_0.Count <= Max_List);
         Next_L.Count := Next_L.Count + 1;
         Next_L.Elems (Next_L.Count) := Packages.Elems (I);
         I := I + 1;
      end loop;

      while J <= L_0.Count loop
         pragma Loop_Invariant (J in 1 .. L_0.Count + 1);
         pragma Loop_Invariant (I = Packages.Count + 1);
         pragma Loop_Invariant (Next_L.Count = Packages.Count + (J - 1));
         pragma Loop_Invariant (Next_L.Count < Max_List);
         pragma Loop_Invariant (Packages.Count + L_0.Count <= Max_List);
         Next_L.Count := Next_L.Count + 1;
         Next_L.Elems (Next_L.Count) := L_0.Elems (J);
         J := J + 1;
      end loop;

      if Next_L.Count > Max_Keep then
         Next_L.Count := List_Len (Max_Keep);
      end if;

      --  Guaranteed non-empty: L_0 has N ≥ 2 leaves merged in.
      if Next_L.Count = 0 then
         Next_L.Count := 1;
         Next_L.Elems (1) := L_0.Elems (1);
      end if;

      L_Curr := Next_L;
   end Package_Merge_Round;

   -------------------------------------------------------------------------
   -- Count leaf occurrences via iterative stack walk
   -------------------------------------------------------------------------

   procedure Count_Leaves
     (Nodes        : Node_Pool;
      Last_Node    : Natural;
      L_Curr       : PM_List;
      Select_Count : Natural;
      Buf          : out Count_Buf)
     with
       Global => null,
       Pre    =>
         Last_Node in 1 .. Max_Nodes
         and then Select_Count <= L_Curr.Count
         and then Select_Count <= Max_List
         and then L_Curr.Count <= Max_List,
       Post   => (for all S in Symbol_Index => Buf (S) <= Max_L)
   is
      Stack : array (1 .. Max_Nodes) of Node_Index := [others => 1];
      Top   : Natural := 0;
      Idx   : Node_Index;
   begin
      Buf := [others => 0];

      for K in 1 .. Select_Count loop
         pragma Loop_Invariant (Top = K - 1);
         pragma Loop_Invariant (Top < Max_Nodes);
         Top := Top + 1;
         Stack (Top) := L_Curr.Elems (K);
      end loop;

      while Top > 0 loop
         pragma Loop_Invariant (Top <= Max_Nodes);
         pragma Loop_Invariant
           (for all S in Symbol_Index => Buf (S) <= Max_L);
         Idx := Stack (Top);
         Top := Top - 1;
         if Nodes (Idx).Kind = Leaf then
            declare
               S : constant Symbol_Index := Nodes (Idx).Sym;
            begin
               if Buf (S) < Max_L then
                  Buf (S) := Buf (S) + 1;
               end if;
            end;
         else
            if Nodes (Idx).Right in 1 .. Last_Node
              and then Top < Max_Nodes
            then
               Top := Top + 1;
               Stack (Top) := Node_Index (Nodes (Idx).Right);
            end if;
            if Nodes (Idx).Left in 1 .. Last_Node
              and then Top < Max_Nodes
            then
               Top := Top + 1;
               Stack (Top) := Node_Index (Nodes (Idx).Left);
            end if;
         end if;
      end loop;
   end Count_Leaves;

   -------------------------------------------------------------------------
   -- Huffman_Length_Limited
   -------------------------------------------------------------------------

   procedure Huffman_Length_Limited
     (Frequencies : Symbol_Frequencies;
      Max_Length  : Positive;
      Lengths     : in out Code_Lengths)
   is
      N : constant Positive := Frequencies'Length;
   begin
      for I in Lengths'Range loop
         Lengths (I) := 0;
         pragma Loop_Invariant
           (for all J in Lengths'First .. I => Lengths (J) = 0);
      end loop;

      if N = 1 then
         Lengths (Lengths'First) := 1;
         Ensure_Length_Bounds (Lengths, Max_Length);
         return;
      end if;

      declare
         Max_Keep  : constant Positive := 2 * N - 2;
         Nodes     : Node_Pool;
         Last_Node : Natural := 0;
         L_0       : PM_List;
         L_Curr    : PM_List;
         Buf       : Count_Buf;
         Sel       : Natural;
      begin
         pragma Assert (Max_Keep <= Max_List);
         pragma Assert (N >= 2);

         for Sym in Frequencies'Range loop
            pragma Loop_Invariant
              (Last_Node = Natural (Sym - Frequencies'First));
            pragma Loop_Invariant (L_0.Count = Last_Node);
            pragma Loop_Invariant (Last_Node < N);
            Last_Node := Last_Node + 1;
            Nodes (Last_Node) :=
              (Kind   => Leaf,
               Weight => Weight_Value (Frequencies (Sym)),
               Sym    => Sym,
               Left   => 0,
               Right  => 0);
            L_0.Count := L_0.Count + 1;
            L_0.Elems (L_0.Count) := Last_Node;
         end loop;

         Sort_By_Weight (Nodes, L_0);
         L_Curr := L_0;

         for Step in 1 .. Max_Length - 1 loop
            pragma Loop_Invariant (Last_Node >= N);
            pragma Loop_Invariant
              (Last_Node <= N + (Step - 1) * (N - 1));
            pragma Loop_Invariant (L_0.Count = N);
            pragma Loop_Invariant (L_Curr.Count in 1 .. Max_Keep);
            pragma Loop_Invariant (Last_Node <= Max_Nodes - (N - 1));

            Package_Merge_Round
              (Nodes, Last_Node, L_0, L_Curr, Max_Keep, N);
         end loop;

         if L_Curr.Count < Max_Keep then
            Sel := L_Curr.Count;
         else
            Sel := Max_Keep;
         end if;

         Count_Leaves (Nodes, Last_Node, L_Curr, Sel, Buf);

         for Sym in Frequencies'Range loop
            Lengths (Sym) := Natural (Buf (Sym));
            pragma Loop_Invariant
              (for all J in Frequencies'First .. Sym =>
                 Lengths (J) = Natural (Buf (J)));
         end loop;

         Ensure_Length_Bounds (Lengths, Max_Length);
      end;
   end Huffman_Length_Limited;

end Package_Merge;
