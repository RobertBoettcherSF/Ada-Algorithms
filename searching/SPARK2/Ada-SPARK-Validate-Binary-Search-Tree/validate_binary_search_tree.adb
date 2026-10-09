pragma Ada_2022;
pragma SPARK_Mode (On);

package body Validate_Binary_Search_Tree is
   function Empty return Tree is
   begin
      return (Values => [others => 0], Lefts => [others => 0],
              Rights => [others => 0], Used => [others => False]);
   end Empty;

   procedure Set_Node
     (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index) is
   begin
      T.Values (Node) := V;
      T.Lefts (Node) := Left;
      T.Rights (Node) := Right;
      T.Used (Node) := True;
   end Set_Node;

   function Value_At (T : Tree; Node : Node_Index) return Value is
   begin
      return T.Values (Node);
   end Value_At;

   function Left_Child (T : Tree; Node : Node_Index) return Index is
   begin
      return T.Lefts (Node);
   end Left_Child;

   function Right_Child (T : Tree; Node : Node_Index) return Index is
   begin
      return T.Rights (Node);
   end Right_Child;


   type Mark_Array is array (Node_Index) of Boolean;

   --  Number of marked nodes among 1 .. K.
   function Count_Upto (M : Mark_Array; K : Index) return Natural is
     (if K = 0 then 0
      else Count_Upto (M, K - 1) + (if M (K) then 1 else 0))
   with Ghost,
        Subprogram_Variant => (Decreases => K),
        Post => Count_Upto'Result <= K;

   function Marked (M : Mark_Array) return Natural is (Count_Upto (M, 15))
   with Ghost;

   --  Marking an unmarked node adds one to the count, so a node can still
   --  be marked only while fewer than 15 are.
   procedure Lemma_Mark (Old, New_M : Mark_Array; C : Node_Index)
   with Ghost, Global => null,
        Pre  => not Old (C) and then New_M (C)
                and then (for all I in Node_Index => (if I /= C then New_M (I) = Old (I))),
        Post => Marked (New_M) = Marked (Old) + 1 and then Marked (Old) <= 14
   is
   begin
      for K in Node_Index loop
         pragma Loop_Invariant
           (Count_Upto (New_M, K) = Count_Upto (Old, K) + (if C <= K then 1 else 0));
      end loop;
   end Lemma_Mark;

   --  Depth-first walk with a stack of at most 15 entries. Every node is
   --  pushed once (it is marked when pushed); a node reached a second time
   --  means the links are not a tree (a cycle or a shared child), and the
   --  answer is False. The loop runs until the stack is empty: there is no
   --  step limit, and every reachable node is checked.
   function Is_Valid_BST (T : Tree; Root : Index) return Boolean is
      Marks : Mark_Array := [others => False];
      Nodes : array (Node_Index) of Node_Index := [others => 1];
      Lows, Highs : array (Node_Index) of Integer range -101 .. 101 := [others => 0];
      Top : Natural range 0 .. 15;
   begin
      if Root = 0 or else not T.Used (Root) then
         return True;
      end if;
      Marks (Root) := True;
      Top := 1;
      Nodes (1) := Root;
      Lows (1) := -101;
      Highs (1) := 101;
      while Top > 0 loop
         pragma Loop_Invariant (Top <= Marked (Marks));
         pragma Loop_Variant (Decreases => 2 * (15 - Marked (Marks)) + Top);
         declare
            N  : constant Node_Index := Nodes (Top);
            Lo : constant Integer := Lows (Top);
            Hi : constant Integer := Highs (Top);
            V  : constant Integer := T.Values (N);
            C  : Index;
         begin
            Top := Top - 1;
            if V <= Lo or else V >= Hi then
               return False;
            end if;
            C := T.Rights (N);
            if C /= 0 then
               if Marks (C) then
                  return False;
               end if;
               declare
                  Old : constant Mark_Array := Marks with Ghost;
               begin
                  Marks (C) := True;
                  Lemma_Mark (Old, Marks, C);
               end;
               Top := Top + 1;
               Nodes (Top) := C;
               Lows (Top) := V;
               Highs (Top) := Hi;
            end if;
            C := T.Lefts (N);
            if C /= 0 then
               if Marks (C) then
                  return False;
               end if;
               declare
                  Old : constant Mark_Array := Marks with Ghost;
               begin
                  Marks (C) := True;
                  Lemma_Mark (Old, Marks, C);
               end;
               Top := Top + 1;
               Nodes (Top) := C;
               Lows (Top) := Lo;
               Highs (Top) := V;
            end if;
         end;
      end loop;
      return True;
   end Is_Valid_BST;
end Validate_Binary_Search_Tree;
