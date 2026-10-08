pragma Ada_2022;

--  Binary search tree in a fixed array of 31 slots. Slot 1 is the root; child index 0 = no child.
--  Nodes are appended in insertion order, so a child's slot is always greater than its parent's.
package Insert_Into_BST with SPARK_Mode => On is
   Capacity : constant := 31;
   subtype Index is Natural range 0 .. Capacity;
   subtype Slot is Positive range 1 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   type Tree is private;

   function Size (T : Tree) return Index with Global => null;
   function Value_At (T : Tree; S : Slot) return Value with Global => null, Pre => S <= Size (T);
   function Left_Of (T : Tree; S : Slot) return Index with Global => null, Pre => S <= Size (T);
   function Right_Of (T : Tree; S : Slot) return Index with Global => null, Pre => S <= Size (T);
   function Root (T : Tree) return Index is (if Size (T) = 0 then 0 else 1) with Global => null;

   --  BST order: every node carries the open interval its value must lie in, inherited along the path
   --  from the root ((Lo, node value) for the left child, (node value, Hi) for the right child). So every
   --  value in the left subtree of a node is smaller and every value in the right subtree larger.
   function Ordered (T : Tree) return Boolean with Global => null;

   --  V is stored in the tree
   function Has (T : Tree; V : Value) return Boolean is
     (for some S in 1 .. Size (T) => Value_At (T, S) = V) with Global => null;

   function Empty return Tree with Global => null, Post => Size (Empty'Result) = 0 and then Ordered (Empty'Result);

   --  Insert V at its place in the tree; a value that is already present leaves the tree unchanged.
   procedure Insert (T : in out Tree; V : Value)
     with Global => null,
          Pre    => Ordered (T) and then Size (T) < Capacity,
          Post   => Ordered (T)
                    and then Size (T) in Size (T'Old) .. Size (T'Old) + 1
                    and then (for all S in 1 .. Size (T'Old) => Value_At (T, S) = Value_At (T'Old, S))
                    and then (if Size (T) = Size (T'Old) + 1 then Value_At (T, Size (T)) = V else Has (T, V));

   --  BST search from the root (only one path is followed)
   function Contains (T : Tree; V : Value) return Boolean
     with Global => null, Pre => Ordered (T), Post => (if Contains'Result then Has (T, V));
private
   subtype Bound is Integer range Value'First - 1 .. Value'Last + 1;
   type Value_Array is array (Slot) of Value;
   type Child_Array is array (Slot) of Index;
   type Bound_Array is array (Slot) of Bound;
   type Tree is record
      Values        : Value_Array;
      Lefts, Rights : Child_Array;
      Lo, Hi        : Bound_Array;   --  open interval of each node's subtree (kept for the proof)
      Count         : Index;
   end record;

   function Size (T : Tree) return Index is (T.Count);
   function Value_At (T : Tree; S : Slot) return Value is (T.Values (S));
   function Left_Of (T : Tree; S : Slot) return Index is (T.Lefts (S));
   function Right_Of (T : Tree; S : Slot) return Index is (T.Rights (S));

   function Node_Ok (T : Tree; S : Slot) return Boolean is
     (T.Lo (S) < T.Values (S) and then T.Values (S) < T.Hi (S)
      and then (T.Lefts (S) = 0
                or else (T.Lefts (S) > S and then T.Lefts (S) <= T.Count
                         and then T.Lo (T.Lefts (S)) = T.Lo (S) and then T.Hi (T.Lefts (S)) = T.Values (S)))
      and then (T.Rights (S) = 0
                or else (T.Rights (S) > S and then T.Rights (S) <= T.Count
                         and then T.Lo (T.Rights (S)) = T.Values (S) and then T.Hi (T.Rights (S)) = T.Hi (S))))
     with Pre => S <= T.Count;

   function Ordered (T : Tree) return Boolean is
     ((T.Count = 0 or else (T.Lo (1) = Bound'First and then T.Hi (1) = Bound'Last))
      and then (for all S in 1 .. T.Count => Node_Ok (T, S)));
end Insert_Into_BST;
