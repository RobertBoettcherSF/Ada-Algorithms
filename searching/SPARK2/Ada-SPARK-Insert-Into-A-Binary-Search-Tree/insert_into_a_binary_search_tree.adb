pragma SPARK_Mode (On);

package body Insert_Into_A_Binary_Search_Tree is
   function Empty return Tree is
      T : Tree;   --  default-initialised: the empty tree
   begin
      return T;
   end Empty;

   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index) is
   begin
      T.Values (Node) := V;
      T.Lefts (Node) := Left;
      T.Rights (Node) := Right;
      T.Used (Node) := True;
   end Set_Node;

   --  Ghost: the nodes already passed on the search path.
   type Node_Set is array (Node_Index) of Boolean
     with Ghost, Default_Component_Value => False;

   --  Number of members of S among nodes 1 .. Upto.
   function Count (S : Node_Set; Upto : Index) return Index is
     (if Upto = 0 then 0
      else Count (S, Upto - 1) + (if S (Upto) then 1 else 0))
   with
     Ghost,
     Post               => Count'Result <= Upto,
     Subprogram_Variant => (Decreases => Upto);

   --  Adding one node to a set adds one to its count.
   procedure Lemma_Count_Add (A, B : Node_Set; X : Node_Index)
   with
     Ghost,
     Pre  => not A (X) and then B (X)
       and then (for all N in Node_Index => (if N /= X then B (N) = A (N))),
     Post => Count (B, Node_Index'Last) = Count (A, Node_Index'Last) + 1
   is
   begin
      for U in Node_Index loop
         pragma Loop_Invariant
           (Count (B, U) = Count (A, U) + (if X <= U then 1 else 0));
      end loop;
   end Lemma_Count_Add;

   procedure Insert (T : in out Tree; Root : in out Index; Node : Node_Index; V : Value) is
      Current : Node_Index;
      Next    : Index;
      Go_Left : Boolean;
      Visited : Node_Set with Ghost;   --  empty
   begin
      if Root /= 0 then
         --  Walk down from the root to the node that gets Node as a child.
         --  The path never comes back to a node: a revisited node would
         --  be the root (which is nobody's child) or have two parents.
         --  So the count of passed nodes grows and the walk ends.
         Current := Root;
         loop
            pragma Loop_Invariant (T.Used (Current) and then not Visited (Current));
            pragma Loop_Invariant
              (for all X in Node_Index => (if Visited (X) then T.Used (X)));
            pragma Loop_Invariant
              (for all X in Node_Index =>
                 (if Visited (X) and then X /= Root then
                    (for some P in Node_Index =>
                       Visited (P)
                       and then (T.Lefts (P) = X or else T.Rights (P) = X))));
            pragma Loop_Invariant
              (Current = Root
               or else
                 (for some P in Node_Index =>
                    Visited (P)
                    and then (T.Lefts (P) = Current or else T.Rights (P) = Current)));
            pragma Loop_Variant (Increases => Count (Visited, Node_Index'Last));
            Go_Left := V < T.Values (Current);
            Next := (if Go_Left then T.Lefts (Current) else T.Rights (Current));
            exit when Next = 0;
            declare
               Before : constant Node_Set := Visited with Ghost;
            begin
               Visited (Current) := True;
               Lemma_Count_Add (Before, Visited, Current);
            end;
            Current := Next;
         end loop;
         if Go_Left then
            T.Lefts (Current) := Node;
         else
            T.Rights (Current) := Node;
         end if;
      else
         Root := Node;
      end if;
      T.Values (Node) := V;
      T.Lefts (Node) := 0;
      T.Rights (Node) := 0;
      T.Used (Node) := True;
   end Insert;
end Insert_Into_A_Binary_Search_Tree;
