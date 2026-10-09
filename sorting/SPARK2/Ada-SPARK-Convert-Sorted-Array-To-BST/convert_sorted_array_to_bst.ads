pragma SPARK_Mode (On);
pragma Ada_2022;

--  Convert a sorted array to a height-balanced BST. Nodes live in a pool
--  numbered in preorder: node 1 is the root (when there is one), the left
--  subtree of a node K is numbered from K + 1, its right subtree right
--  after it. Node K covers the array positions Lo (K) .. Hi (K) and holds
--  the middle one, A ((Lo + Hi) / 2), so the in-order walk is A and the two
--  subtree sizes differ by at most 1.
package Convert_Sorted_Array_To_BST is
   Max_Nodes : constant := 1_000;
   subtype Index is Natural range 0 .. Max_Nodes;   --  0 = no child
   subtype Node_Index is Index range 1 .. Max_Nodes;
   subtype Value is Integer range -1000 .. 1000;
   subtype Count is Natural range 0 .. Max_Nodes;
   type Tree is private;

   function Empty return Tree;
   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index);

   --  The original 7-element exercise (Node_Value (Build (A), 1) = A (4)).
   type Sorted_Array is array (Positive range 1 .. 7) of Value;
   function Build (A : Sorted_Array) return Tree;

   type Value_List is array (Node_Index range <>) of Value;

   function Size (T : Tree) return Count;
   function Root (T : Tree) return Index is (if Size (T) = 0 then 0 else 1);
   function Node_Value (T : Tree; Node : Node_Index) return Value;
   function Left (T : Tree; Node : Node_Index) return Index;
   function Right (T : Tree; Node : Node_Index) return Index;
   function Lo (T : Tree; Node : Node_Index) return Index;
   function Hi (T : Tree; Node : Node_Index) return Index;

   --  Node K of T is the balanced-split node over A (Lo (K) .. Hi (K)).
   function Node_Ok (T : Tree; A : Value_List; K : Node_Index) return Boolean is
     (A'First = 1 and then Lo (T, K) in 1 .. Hi (T, K) and then Hi (T, K) <= A'Last
      and then Node_Value (T, K) = A (Lo (T, K) + (Hi (T, K) - Lo (T, K)) / 2)
      and then (if (Hi (T, K) - Lo (T, K)) / 2 = 0 then Left (T, K) = 0
                else K < Max_Nodes and then Left (T, K) = K + 1
                     and then Lo (T, K + 1) = Lo (T, K)
                     and then Hi (T, K + 1) = Lo (T, K) + (Hi (T, K) - Lo (T, K)) / 2 - 1)
      and then (if Lo (T, K) + (Hi (T, K) - Lo (T, K)) / 2 = Hi (T, K) then Right (T, K) = 0
                else K + 1 + (Hi (T, K) - Lo (T, K)) / 2 <= Max_Nodes
                     and then Right (T, K) = K + 1 + (Hi (T, K) - Lo (T, K)) / 2
                     and then Lo (T, Right (T, K)) = Lo (T, K) + (Hi (T, K) - Lo (T, K)) / 2 + 1
                     and then Hi (T, Right (T, K)) = Hi (T, K)));

   --  Every node of Build_From (A) is a balanced-split node, and the root
   --  covers all of A (so, by induction over the ranges, the in-order walk is
   --  A and the tree is height-balanced; a BST when A is sorted).
   function Build_From (A : Value_List) return Tree
     with Pre  => A'First = 1,
          Post => Size (Build_From'Result) = A'Length
                  and then (if A'Length > 0 then
                              Lo (Build_From'Result, 1) = 1 and then Hi (Build_From'Result, 1) = A'Last)
                  and then (for all K in 1 .. A'Last => Node_Ok (Build_From'Result, A, K));
private
   type Child_Array is array (Index) of Index;
   type Value_Array is array (Index) of Value;
   type Used_Array is array (Index) of Boolean;
   type Tree is record
      Values : Value_Array;
      Lefts : Child_Array;
      Rights : Child_Array;
      Used : Used_Array;
      Los : Child_Array;
      His : Child_Array;
      Nodes : Count;
   end record;
   function Size (T : Tree) return Count is (T.Nodes);
   function Node_Value (T : Tree; Node : Node_Index) return Value is (T.Values (Node));
   function Left (T : Tree; Node : Node_Index) return Index is (T.Lefts (Node));
   function Right (T : Tree; Node : Node_Index) return Index is (T.Rights (Node));
   function Lo (T : Tree; Node : Node_Index) return Index is (T.Los (Node));
   function Hi (T : Tree; Node : Node_Index) return Index is (T.His (Node));
end Convert_Sorted_Array_To_BST;
