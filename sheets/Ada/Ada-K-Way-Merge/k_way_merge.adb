--  K_Way_Merge body — binary min-heap of heads + 2-way scan.

pragma Ada_2022;

package body K_Way_Merge
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Is_Sorted
   -------------------------------------------------------------------------

   function Is_Sorted (A : Vector) return Boolean is
   begin
      if A'Length <= 1 then
         return True;
      end if;
      for I in A'First .. A'Last - 1 loop
         if A (I) > A (I + 1) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Sorted;

   -------------------------------------------------------------------------
   -- 2-way merge (direct scan)
   -------------------------------------------------------------------------

   procedure Merge
     (A, B   : Vector;
      Output : out Vector;
      Last   : out Natural)
   is
      Need : constant Natural := A'Length + B'Length;
      IA   : Natural;
      IB   : Natural;
      OI   : Natural;
   begin
      if A'Length > Max_Len or else B'Length > Max_Len then
         raise Invalid_Argument;
      end if;
      if Need > Max_Total then
         raise Invalid_Argument;
      end if;
      if Output'Length < Need then
         raise Invalid_Argument;
      end if;
      if not Is_Sorted (A) or else not Is_Sorted (B) then
         raise Invalid_Argument;
      end if;

      if Need = 0 then
         Last := Output'First - 1;
         return;
      end if;

      IA := A'First;
      IB := B'First;
      OI := Output'First;

      while IA <= A'Last and then IB <= B'Last loop
         if A (IA) <= B (IB) then
            Output (OI) := A (IA);
            IA := IA + 1;
         else
            Output (OI) := B (IB);
            IB := IB + 1;
         end if;
         OI := OI + 1;
      end loop;

      while IA <= A'Last loop
         Output (OI) := A (IA);
         IA := IA + 1;
         OI := OI + 1;
      end loop;

      while IB <= B'Last loop
         Output (OI) := B (IB);
         IB := IB + 1;
         OI := OI + 1;
      end loop;

      Last := OI - 1;
   end Merge;

   function Merge (A, B : Vector) return Vector is
      Need : constant Natural := A'Length + B'Length;
      Buf  : Vector (1 .. Need);
      Last : Natural;
   begin
      --  Re-check lengths here so empty Need does not allocate oddly;
      --  Merge procedure raises for capacity / sortedness.
      if Need = 0 then
         if not Is_Sorted (A) or else not Is_Sorted (B) then
            raise Invalid_Argument;
         end if;
         if A'Length > Max_Len or else B'Length > Max_Len then
            raise Invalid_Argument;
         end if;
         declare
            Empty : constant Vector (1 .. 0) := [];
         begin
            return Empty;
         end;
      end if;

      Merge (A, B, Buf, Last);
      return Buf (1 .. Last);
   end Merge;

   -------------------------------------------------------------------------
   -- Binary min-heap of heads for k-way Merge
   -------------------------------------------------------------------------

   type Heap_Node is record
      Value : Integer;
      List  : Positive;
      Index : Positive;
   end record;

   type Heap_Store is array (Positive range <>) of Heap_Node;

   --  Min-heap: parent at I/2, children at 2*I and 2*I+1 (1-based).
   --  Size is the live count in Store (1 .. Size).

   procedure Sift_Up (Store : in out Heap_Store; Pos : Positive) is
      I : Positive := Pos;
      P : Positive;
      T : Heap_Node;
   begin
      while I > 1 loop
         P := I / 2;
         if Store (P).Value <= Store (I).Value then
            exit;
         end if;
         T := Store (P);
         Store (P) := Store (I);
         Store (I) := T;
         I := P;
      end loop;
   end Sift_Up;

   procedure Sift_Down
     (Store : in out Heap_Store;
      Size  : Natural;
      Pos   : Positive)
   is
      I     : Positive := Pos;
      Left  : Positive;
      Right : Positive;
      Best  : Positive;
      T     : Heap_Node;
   begin
      loop
         Left := 2 * I;
         if Left > Size then
            exit;
         end if;
         Best := Left;
         Right := Left + 1;
         if Right <= Size
           and then Store (Right).Value < Store (Best).Value
         then
            Best := Right;
         end if;
         if Store (I).Value <= Store (Best).Value then
            exit;
         end if;
         T := Store (I);
         Store (I) := Store (Best);
         Store (Best) := T;
         I := Best;
      end loop;
   end Sift_Down;

   procedure Heap_Push
     (Store : in out Heap_Store;
      Size  : in out Natural;
      Node  : Heap_Node)
   is
   begin
      Size := Size + 1;
      Store (Size) := Node;
      Sift_Up (Store, Size);
   end Heap_Push;

   function Heap_Pop
     (Store : in out Heap_Store;
      Size  : in out Natural) return Heap_Node
   is
      Root : constant Heap_Node := Store (1);
   begin
      Store (1) := Store (Size);
      Size := Size - 1;
      if Size >= 1 then
         Sift_Down (Store, Size, 1);
      end if;
      return Root;
   end Heap_Pop;

   -------------------------------------------------------------------------
   -- K-way Merge
   -------------------------------------------------------------------------

   function Merge (Lists : Vector_List) return Vector is
      K : constant Natural := Lists'Length;
      Total : Natural := 0;
   begin
      if K > Max_K then
         raise Invalid_Argument;
      end if;

      --  Validate lengths and sortedness; accumulate total.
      for L of Lists loop
         if L /= null then
            if L'Length > Max_Len then
               raise Invalid_Argument;
            end if;
            if not Is_Sorted (L.all) then
               raise Invalid_Argument;
            end if;
            if Natural'Last - Total < L'Length then
               raise Invalid_Argument;
            end if;
            Total := Total + L'Length;
         end if;
      end loop;

      if Total > Max_Total then
         raise Invalid_Argument;
      end if;

      if Total = 0 then
         declare
            Empty : constant Vector (1 .. 0) := [];
         begin
            return Empty;
         end;
      end if;

      declare
         Out_Buf : Vector (1 .. Total);
         OI      : Positive := 1;
         Store   : Heap_Store (1 .. Max_K);
         HSize   : Natural := 0;
         Node    : Heap_Node;
         Next_Ix : Positive;
         Lix     : Positive;
      begin
         --  Seed heap with the head of every non-empty list.
         for I in Lists'Range loop
            if Lists (I) /= null and then Lists (I)'Length > 0 then
               Heap_Push
                 (Store, HSize,
                  (Value => Lists (I)(Lists (I)'First),
                   List  => I,
                   Index => Lists (I)'First));
            end if;
         end loop;

         while HSize > 0 loop
            Node := Heap_Pop (Store, HSize);
            Out_Buf (OI) := Node.Value;
            OI := OI + 1;

            Lix := Node.List;
            if Node.Index < Lists (Lix)'Last then
               Next_Ix := Node.Index + 1;
               Heap_Push
                 (Store, HSize,
                  (Value => Lists (Lix)(Next_Ix),
                   List  => Lix,
                   Index => Next_Ix));
            end if;
         end loop;

         return Out_Buf;
      end;
   end Merge;

end K_Way_Merge;
