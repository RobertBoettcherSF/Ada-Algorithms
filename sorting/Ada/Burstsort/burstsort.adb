--  Burstsort body — educational burst-trie string sort.

pragma Ada_2022;

with Ada.Unchecked_Deallocation;

package body Burstsort
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Public helpers
   -------------------------------------------------------------------------

   function Make (S : String) return Bounded_String is
      B : Bounded_String;
   begin
      if S'Length > Max_String_Len then
         raise Invalid_Argument;
      end if;
      B.Length := S'Length;
      if S'Length > 0 then
         B.Data (1 .. S'Length) := S;
      end if;
      return B;
   end Make;

   function To_String (B : Bounded_String) return String is
   begin
      return B.Data (1 .. B.Length);
   end To_String;

   function "<" (Left, Right : Bounded_String) return Boolean is
      L : constant Natural := Left.Length;
      R : constant Natural := Right.Length;
      M : constant Natural := Natural'Min (L, R);
   begin
      for I in 1 .. M loop
         if Left.Data (I) < Right.Data (I) then
            return True;
         elsif Left.Data (I) > Right.Data (I) then
            return False;
         end if;
      end loop;
      return L < R;
   end "<";

   function "<=" (Left, Right : Bounded_String) return Boolean is
   begin
      return not (Right < Left);
   end "<=";

   function Is_Sorted (A : String_Array) return Boolean is
   begin
      if A'Length <= 1 then
         return True;
      end if;
      for I in A'First .. A'Last - 1 loop
         if not (A (I) <= A (I + 1)) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Sorted;

   -------------------------------------------------------------------------
   -- Burst trie (heap node pool; educational, no unbounded heap growth)
   -------------------------------------------------------------------------

   --  Worst-case node demand is modest under Max_N × Max_String_Len; 512
   --  is ample for the educational bounds and random demos.
   Max_Nodes : constant Positive := 512;

   subtype Node_Index is Natural range 0 .. Max_Nodes;
   --  0 = null / unused.

   subtype Char_Code is Natural range 0 .. Alphabet_Size - 1;

   --  Child buckets never hold more than Burst_Threshold+1 (they burst).
   subtype Small_Count is Natural range 0 .. Burst_Threshold + 1;
   type Small_Index_List is array (1 .. Burst_Threshold + 1) of Positive;

   type Small_Bucket is record
      Count : Small_Count := 0;
      Items : Small_Index_List := [others => 1];
   end record;

   --  Ended lists can hold every string that terminates at this depth.
   type Large_Index_List is array (1 .. Max_N) of Positive;

   type Large_Bucket is record
      Count : Natural := 0;
      Items : Large_Index_List := [others => 1];
   end record;

   type Slot_Kind is (Empty_Slot, Bucket_Slot, Trie_Slot);

   type Child_Slot is record
      Kind   : Slot_Kind := Empty_Slot;
      Bucket : Small_Bucket;
      Child  : Node_Index := 0;
   end record;

   type Child_Array is array (Char_Code) of Child_Slot;

   type Trie_Node is record
      --  Depth = characters already matched from the root. The node
      --  discriminates on character position Depth+1.
      Depth : Natural := 0;
      Ended : Large_Bucket;           -- strings with Length = Depth
      Kids  : Child_Array;
   end record;

   type Node_Pool is array (1 .. Max_Nodes) of Trie_Node;
   type Node_Pool_Access is access Node_Pool;

   procedure Free_Pool is
     new Ada.Unchecked_Deallocation (Node_Pool, Node_Pool_Access);

   -------------------------------------------------------------------------
   -- Sort
   -------------------------------------------------------------------------

   procedure Sort (A : in out String_Array) is
      N : constant Natural := A'Length;
   begin
      if N > Max_N then
         raise Invalid_Argument;
      end if;

      if N <= 1 then
         return;
      end if;

      declare
         Work  : String_Array (1 .. N);
         Pool  : Node_Pool_Access := new Node_Pool;
         Free  : Node_Index := 0;   -- last allocated index
         Root  : Node_Index := 0;
         Out_I : Positive := 1;

         procedure Raise_If_No_Node is
         begin
            if Free = Max_Nodes then
               Free_Pool (Pool);
               raise Invalid_Argument;
            end if;
         end Raise_If_No_Node;

         function Alloc_Node (Depth : Natural) return Node_Index is
            Idx : Node_Index;
         begin
            Raise_If_No_Node;
            Free := Free + 1;
            Idx := Free;
            Pool (Idx).Depth := Depth;
            Pool (Idx).Ended := (Count => 0, Items => [others => 1]);
            for C in Char_Code loop
               Pool (Idx).Kids (C) :=
                 (Kind   => Empty_Slot,
                  Bucket => (Count => 0, Items => [others => 1]),
                  Child  => 0);
            end loop;
            return Idx;
         end Alloc_Node;

         procedure Small_Append (B : in out Small_Bucket; Idx : Positive) is
         begin
            B.Count := B.Count + 1;
            B.Items (B.Count) := Idx;
         end Small_Append;

         procedure Large_Append (B : in out Large_Bucket; Idx : Positive) is
         begin
            B.Count := B.Count + 1;
            B.Items (B.Count) := Idx;
         end Large_Append;

         --  Insertion-sort a large bucket by full lexicographic order.
         procedure Insertion_Sort_Large (B : in out Large_Bucket) is
         begin
            if B.Count <= 1 then
               return;
            end if;
            for I in 2 .. B.Count loop
               declare
                  Key : constant Positive := B.Items (I);
                  J   : Natural := I - 1;
               begin
                  while J >= 1 and then Work (Key) < Work (B.Items (J)) loop
                     B.Items (J + 1) := B.Items (J);
                     J := J - 1;
                  end loop;
                  B.Items (J + 1) := Key;
               end;
            end loop;
         end Insertion_Sort_Large;

         procedure Insertion_Sort_Small (B : in out Small_Bucket) is
         begin
            if B.Count <= 1 then
               return;
            end if;
            for I in 2 .. B.Count loop
               declare
                  Key : constant Positive := B.Items (I);
                  J   : Natural := I - 1;
               begin
                  while J >= 1 and then Work (Key) < Work (B.Items (J)) loop
                     B.Items (J + 1) := B.Items (J);
                     J := J - 1;
                  end loop;
                  B.Items (J + 1) := Key;
               end;
            end loop;
         end Insertion_Sort_Small;

         --  Forward decl for mutual recursion with Burst_Bucket.
         procedure Insert_At
           (Node : Node_Index;
            Idx  : Positive);

         procedure Burst_Bucket
           (Parent : Node_Index;
            Code   : Char_Code)
         is
            Old   : constant Small_Bucket := Pool (Parent).Kids (Code).Bucket;
            Depth : constant Natural := Pool (Parent).Depth;
            --  Parent depth D matched D chars; child slot Code is char at
            --  D+1, so strings in this bucket share a prefix of length D+1.
            --  The new trie node therefore has Depth = D+1.
            New_D : constant Natural := Depth + 1;
            Child : constant Node_Index := Alloc_Node (New_D);
         begin
            Pool (Parent).Kids (Code) :=
              (Kind   => Trie_Slot,
               Bucket => (Count => 0, Items => [others => 1]),
               Child  => Child);

            for K in 1 .. Old.Count loop
               Insert_At (Child, Old.Items (K));
            end loop;
         end Burst_Bucket;

         procedure Insert_At
           (Node : Node_Index;
            Idx  : Positive)
         is
            Depth : constant Natural := Pool (Node).Depth;
            Len   : constant Natural := Work (Idx).Length;
         begin
            if Len = Depth then
               Large_Append (Pool (Node).Ended, Idx);
               return;
            end if;

            declare
               Code : constant Char_Code :=
                 Character'Pos (Work (Idx).Data (Depth + 1));
               Slot : Child_Slot renames Pool (Node).Kids (Code);
            begin
               case Slot.Kind is
                  when Empty_Slot =>
                     Slot.Kind := Bucket_Slot;
                     Small_Append (Slot.Bucket, Idx);

                  when Bucket_Slot =>
                     Small_Append (Slot.Bucket, Idx);
                     if Slot.Bucket.Count > Burst_Threshold then
                        Burst_Bucket (Node, Code);
                     end if;

                  when Trie_Slot =>
                     Insert_At (Slot.Child, Idx);
               end case;
            end;
         end Insert_At;

         procedure Emit_Large (B : in out Large_Bucket) is
         begin
            Insertion_Sort_Large (B);
            for K in 1 .. B.Count loop
               A (A'First + Out_I - 1) := Work (B.Items (K));
               Out_I := Out_I + 1;
            end loop;
         end Emit_Large;

         procedure Emit_Small (B : in out Small_Bucket) is
         begin
            Insertion_Sort_Small (B);
            for K in 1 .. B.Count loop
               A (A'First + Out_I - 1) := Work (B.Items (K));
               Out_I := Out_I + 1;
            end loop;
         end Emit_Small;

         procedure Emit (Node : Node_Index) is
         begin
            --  Strings that ended exactly at this depth come before any
            --  extension (lexicographic: shorter prefix is smaller).
            Emit_Large (Pool (Node).Ended);

            for C in Char_Code loop
               case Pool (Node).Kids (C).Kind is
                  when Empty_Slot =>
                     null;
                  when Bucket_Slot =>
                     Emit_Small (Pool (Node).Kids (C).Bucket);
                  when Trie_Slot =>
                     Emit (Pool (Node).Kids (C).Child);
               end case;
            end loop;
         end Emit;

      begin
         --  Copy into a 1-based work buffer.
         for I in 0 .. N - 1 loop
            Work (I + 1) := A (A'First + I);
         end loop;

         Root := Alloc_Node (0);

         for I in 1 .. N loop
            Insert_At (Root, I);
         end loop;

         Out_I := 1;
         Emit (Root);

         Free_Pool (Pool);
      exception
         when others =>
            if Pool /= null then
               Free_Pool (Pool);
            end if;
            raise;
      end;
   end Sort;

end Burstsort;
