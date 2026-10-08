pragma SPARK_Mode (On);

package Insert_Into_A_Binary_Search_Tree is
   subtype Index is Natural range 0 .. 16;
   subtype Node_Index is Index range 1 .. 16;
   subtype Value is Integer range -100 .. 100;
   type Tree is private;
   --  Read-only view of a node (for tests and contracts).
   function Is_Used (T : Tree; Node : Node_Index) return Boolean;
   function Value_Of (T : Tree; Node : Node_Index) return Value;
   function Left_Of (T : Tree; Node : Node_Index) return Index;
   function Right_Of (T : Tree; Node : Node_Index) return Index;

   --  No node used; every value and link 0.
   function Empty return Tree
     with
       Post => (for all N in Node_Index =>
                  not Is_Used (Empty'Result, N)
                  and then Value_Of (Empty'Result, N) = 0
                  and then Left_Of (Empty'Result, N) = 0
                  and then Right_Of (Empty'Result, N) = 0);

   --  Make Node a used node with value V and children Left and Right
   --  (0 = none); every other node stays as it was. Nothing is checked:
   --  the caller builds a well-formed tree before calling Insert.
   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index)
     with
       Post => Is_Used (T, Node)
               and then Value_Of (T, Node) = V
               and then Left_Of (T, Node) = Left
               and then Right_Of (T, Node) = Right
               and then
                 (for all N in Node_Index =>
                    (if N /= Node then
                       Is_Used (T, N) = Is_Used (T'Old, N)
                       and then Value_Of (T, N) = Value_Of (T'Old, N)
                       and then Left_Of (T, N) = Left_Of (T'Old, N)
                       and then Right_Of (T, N) = Right_Of (T'Old, N)));

   --  Root is 0 (empty tree) or a used node; every child link of a used
   --  node is 0 or a used node other than Root; no node has two parents
   --  (and no node is both children of one parent). The nodes reachable
   --  from Root therefore form a tree, so a search path ends (Insert
   --  proves this with a loop variant).
   function Well_Formed (T : Tree; Root : Index) return Boolean is
     ((Root = 0 or else Is_Used (T, Root))
      and then
        (for all N in Node_Index =>
           (if Is_Used (T, N) then
              (Left_Of (T, N) = 0
               or else (Is_Used (T, Left_Of (T, N))
                        and then Left_Of (T, N) /= Root))
              and then
              (Right_Of (T, N) = 0
               or else (Is_Used (T, Right_Of (T, N))
                        and then Right_Of (T, N) /= Root
                        and then Right_Of (T, N) /= Left_Of (T, N)))))
      and then
        (for all A in Node_Index =>
           (for all B in Node_Index =>
              (if A /= B and then Is_Used (T, A) and then Is_Used (T, B) then
                 (Left_Of (T, A) = 0
                  or else (Left_Of (T, A) /= Left_Of (T, B)
                           and then Left_Of (T, A) /= Right_Of (T, B)))
                 and then
                 (Right_Of (T, A) = 0
                  or else Right_Of (T, A) /= Right_Of (T, B))))));

   --  Insert value V as the new leaf Node (a node not yet in the tree):
   --  smaller values go left, others right. The tree stays well formed,
   --  Node gets a parent (unless it is the new root), and the only other
   --  change is that one empty child link now points to Node.
   procedure Insert (T : in out Tree; Root : in out Index; Node : Node_Index; V : Value)
     with
       Pre  => Well_Formed (T, Root) and then not Is_Used (T, Node),
       Post => Root /= 0
               and then (if Root'Old /= 0 then Root = Root'Old)
               and then Is_Used (T, Node)
               and then Value_Of (T, Node) = V
               and then Left_Of (T, Node) = 0
               and then Right_Of (T, Node) = 0
               and then Well_Formed (T, Root)
               and then
                 (Root'Old = 0
                  or else
                    (for some P in Node_Index =>
                       Is_Used (T, P)
                       and then (Left_Of (T, P) = Node or else Right_Of (T, P) = Node)))
               and then
                 (for all N in Node_Index =>
                    (if N /= Node then
                       Is_Used (T, N) = Is_Used (T'Old, N)
                       and then Value_Of (T, N) = Value_Of (T'Old, N)
                       and then (Left_Of (T, N) = Left_Of (T'Old, N)
                                 or else (Left_Of (T'Old, N) = 0
                                          and then Left_Of (T, N) = Node))
                       and then (Right_Of (T, N) = Right_Of (T'Old, N)
                                 or else (Right_Of (T'Old, N) = 0
                                          and then Right_Of (T, N) = Node))));
private
   --  A Tree object starts as the empty tree: every component array is
   --  default-initialised to 0 / False.
   type Index_Array is array (Index) of Index
     with Default_Component_Value => 0;
   type Value_Array is array (Index) of Value
     with Default_Component_Value => 0;
   type Used_Array is array (Index) of Boolean
     with Default_Component_Value => False;
   type Tree is record
      Values : Value_Array;
      Lefts : Index_Array;
      Rights : Index_Array;
      Used : Used_Array;
   end record;

   function Is_Used (T : Tree; Node : Node_Index) return Boolean is (T.Used (Node));
   function Value_Of (T : Tree; Node : Node_Index) return Value is (T.Values (Node));
   function Left_Of (T : Tree; Node : Node_Index) return Index is (T.Lefts (Node));
   function Right_Of (T : Tree; Node : Node_Index) return Index is (T.Rights (Node));
end Insert_Into_A_Binary_Search_Tree;
