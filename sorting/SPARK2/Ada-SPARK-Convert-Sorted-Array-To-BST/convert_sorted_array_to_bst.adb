pragma SPARK_Mode (On);
pragma Ada_2022;

package body Convert_Sorted_Array_To_BST is
   function Empty return Tree is
   begin
      return (Values => [others => 0], Lefts => [others => 0],
              Rights => [others => 0], Used => [others => False],
              Los => [others => 0], His => [others => 0], Nodes => 0);
   end Empty;

   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index) is
   begin
      T.Values (Node) := V; T.Lefts (Node) := Left; T.Rights (Node) := Right; T.Used (Node) := True;
   end Set_Node;

   function Same_Node (T1, T2 : Tree; K : Node_Index) return Boolean is
     (T1.Values (K) = T2.Values (K) and then T1.Lefts (K) = T2.Lefts (K)
      and then T1.Rights (K) = T2.Rights (K) and then T1.Los (K) = T2.Los (K)
      and then T1.His (K) = T2.His (K))
     with Ghost;

   --  Fill nodes Node .. Node + (Hi_P - Lo_P) with the subtree over
   --  A (Lo_P .. Hi_P); no other node changes.
   procedure Fill (T : in out Tree; A : Value_List; Lo_P, Hi_P : Node_Index; Node : Node_Index)
     with Pre  => A'First = 1 and then Lo_P <= Hi_P and then Hi_P <= A'Last
                  and then Node + (Hi_P - Lo_P) <= Max_Nodes,
          Post => T.Los (Node) = Lo_P and then T.His (Node) = Hi_P
                  and then T.Nodes = T'Old.Nodes
                  and then (for all K in Node .. Node + (Hi_P - Lo_P) =>
                              Node_Ok (T, A, K)
                              and then K + (T.His (K) - T.Los (K)) <= Node + (Hi_P - Lo_P))
                  and then (for all K in Node_Index =>
                              (if K not in Node .. Node + (Hi_P - Lo_P) then Same_Node (T, T'Old, K))),
          Subprogram_Variant => (Decreases => Hi_P - Lo_P)
   is
      Half : constant Natural := (Hi_P - Lo_P) / 2;
      Mid  : constant Node_Index := Lo_P + Half;
      R    : constant Index := (if Mid = Hi_P then 0 else Node + 1 + Half);
   begin
      T.Values (Node) := A (Mid);
      T.Los (Node) := Lo_P;
      T.His (Node) := Hi_P;
      T.Lefts (Node) := (if Half = 0 then 0 else Node + 1);
      T.Rights (Node) := R;
      T.Used (Node) := True;
      if Half > 0 then
         Fill (T, A, Lo_P, Mid - 1, Node + 1);
      end if;
      if Mid < Hi_P then
         Fill (T, A, Mid + 1, Hi_P, R);
      end if;
      pragma Assert (Node_Ok (T, A, Node));
      pragma Assert
        (for all K in Node + 1 .. Node + Half => Node_Ok (T, A, K));
   end Fill;

   function Build_From (A : Value_List) return Tree is
      T : Tree := Empty;
   begin
      T.Nodes := A'Length;
      if A'Length > 0 then
         Fill (T, A, 1, A'Last, 1);
      end if;
      return T;
   end Build_From;

   function Build (A : Sorted_Array) return Tree is
     (Build_From (Value_List (A)));
end Convert_Sorted_Array_To_BST;
