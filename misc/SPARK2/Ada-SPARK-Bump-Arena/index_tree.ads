pragma SPARK_Mode (On);

with Bump_Arena; use Bump_Arena;

--  Tiny binary-search tree client. Nodes live in a fixed array; links are
--  Node_Id indices (0 = null). All fresh nodes come from Bump_Arena.

package Index_Tree is

   subtype Key is Integer range -1_000 .. 1_000;

   type Tree is private;

   function Empty return Tree
     with Global => null,
          Post   => Root_Of (Empty'Result) = Null_Node
            and then Used (Arena_Of (Empty'Result)) = 0;

   function Root_Of (T : Tree) return Node_Id
     with Global => null;

   function Arena_Of (T : Tree) return Arena
     with Global => null;

   function Remaining_Slots (T : Tree) return Slot_Count
     with Global => null,
          Post   => Remaining_Slots'Result = Remaining (Arena_Of (T));

   procedure Clear (T : out Tree)
     with Global => null,
          Post   => Root_Of (T) = Null_Node
            and then Used (Arena_Of (T)) = 0;

   --  Insert K. Ok is False when K is already present (no duplicate slots).
   --  Requires at least one free arena slot when K is new.
   procedure Insert (T : in out Tree; K : Key; Ok : out Boolean)
     with Global => null,
          Pre    => Remaining_Slots (T) > 0 or else Contains (T, K),
          Post   => (if Ok then
                       Used (Arena_Of (T)) = Used (Arena_Of (T'Old)) + 1
                       and then Root_Of (T) /= Null_Node
                     else
                       Used (Arena_Of (T)) = Used (Arena_Of (T'Old))
                       and then Root_Of (T) = Root_Of (T'Old));

   function Contains (T : Tree; K : Key) return Boolean
     with Global => null;

private

   type Node is record
      Value : Key := 0;
      Left  : Node_Id := Null_Node;
      Right : Node_Id := Null_Node;
   end record;

   type Node_Array is array (Valid_Id) of Node;

   --  Nodes are allocated in id order and a new node is only ever linked
   --  below an older one, so every link points to a later live slot. A
   --  walk from the root therefore visits strictly increasing ids and
   --  ends within Capacity steps.
   function Links_Forward (Nodes : Node_Array; Root : Node_Id; Live : Slot_Count)
     return Boolean
   is
     ((Root = Null_Node or else Root in 1 .. Live)
      and then
        (for all N in 1 .. Live =>
           (Nodes (N).Left = Null_Node or else Nodes (N).Left in N + 1 .. Live)
           and then
           (Nodes (N).Right = Null_Node or else Nodes (N).Right in N + 1 .. Live)))
   with Global => null;

   type Tree is record
      Root  : Node_Id := Null_Node;
      Nodes : Node_Array := [others => (Value => 0, Left => Null_Node, Right => Null_Node)];
      Store : Arena := Create;
   end record
     with Type_Invariant => Links_Forward (Nodes, Root, Used (Store));

   function Root_Of (T : Tree) return Node_Id is (T.Root);

   function Arena_Of (T : Tree) return Arena is (T.Store);

end Index_Tree;
