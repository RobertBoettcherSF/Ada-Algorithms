--  Test-only child of Red_Black_Tree: builds arbitrary (also invalid)
--  node layouts and tampers with links, so that the judge
--  Is_Valid_Red_Black_Tree can be compared with an independent
--  reference definition (Reference_Valid). Not used by the package.
package Red_Black_Tree.Test_Support is

   --  Layout by heap position: position P has children 2P and 2P+1.
   Max_Pos : constant := 15;
   subtype Position is Positive range 1 .. Max_Pos;
   type Present_Array is array (Position) of Boolean;
   type Key_Array     is array (Position) of Node_Key;
   type Red_Array     is array (Position) of Boolean;

   --  Replace T by the layout (Present must be closed under parents).
   --  Parent links and Count are set consistently.
   procedure Build
     (T       : in out Tree;
      Present : Present_Array;
      Keys    : Key_Array;
      Red     : Red_Array);

   --  Detach the parent link of the root's first child (no-op if none).
   procedure Break_Parent_Link (T : in out Tree);

   --  Set the stored node count without changing the nodes.
   procedure Set_Count (T : in out Tree; Count : Natural);

   --  The definition, computed independently of the judge:
   --  the in-order key sequence is strictly increasing; the root is
   --  black; no red node has a red child; every path from the root to a
   --  missing child passes the same number of black nodes; the root has
   --  no parent and every child links back to its parent; Count equals
   --  the number of nodes.
   function Reference_Valid (T : Tree) return Boolean;

end Red_Black_Tree.Test_Support;
