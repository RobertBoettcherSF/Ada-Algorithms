pragma Ada_2022;
--  House Robber III: houses form a binary tree, each worth Value; robbing
--  a house and one of its children is not allowed. Find the largest total.
--
--  A tree of N houses is given in preorder: house 1 is the root, the left
--  child of house I (if any) is I + 1, and its right child (if any) comes
--  right after the left subtree. Left (I) / Right (I) = 0 means no child.
--  Good_Tree checks this shape, so every house 1 .. N is in the tree once.
--
--  Limits: N <= 100 and Value <= 10_000. Totals are at most
--  100 * 10_000 = 1_000_000, far from overflow (Natural would allow about
--  214_000 houses of 10_000); N is limited by run time with assertions on:
--  the shape check and the contracts follow subtrees, about N ** 3 steps
--  on a path-shaped tree (one call: about 0.2 s for 100 houses, 0.9 s for
--  200).
package House_Robber_III_Lite with SPARK_Mode => On is
   Max_Nodes : constant := 100;
   Max_Value : constant := 10_000;
   subtype Node_Count is Natural range 0 .. Max_Nodes;
   subtype Index is Positive range 1 .. Max_Nodes;
   subtype Link is Natural range 0 .. Max_Nodes;
   subtype House_Value is Natural range 0 .. Max_Value;
   type Value_Array is array (Index range <>) of House_Value;
   type Link_Array is array (Index range <>) of Link;
   type Choice is array (Index range <>) of Boolean;

   --  A choice is indexed by house number (S (I): house I is robbed, read
   --  as S (T.Left (J))), so it starts at 1; the subtype says so for any
   --  length (H180; the Index subtype alone lets a 5 .. 7 choice through).
   --  Value_Array needs no such subtype: it only appears as the Tree
   --  components, constrained to 1 .. N.
   subtype One_Based_Choice is Choice
   with Predicate => One_Based_Choice'First = 1;

   type Tree (N : Node_Count) is record
      Value : Value_Array (1 .. N);
      Left  : Link_Array (1 .. N);
      Right : Link_Array (1 .. N);
   end record;

   --  The last house of the subtree of I (links that do not point forward
   --  are ignored here; Well_Formed rejects them).
   function Last_Of (T : Tree; I : Index) return Index
   with
     Pre                => I <= T.N,
     Post               => Last_Of'Result in I .. T.N,
     Subprogram_Variant => (Decreases => T.N - I);

   function Well_Formed (T : Tree) return Boolean is
     ((for all I in 1 .. T.N =>
         (T.Left (I) = 0 or else (I < T.N and then T.Left (I) = I + 1))
         and then
         (T.Right (I) = 0
          or else (if T.Left (I) = 0 then I < T.N and then T.Right (I) = I + 1
                   else Last_Of (T, I + 1) < T.N and then T.Right (I) = Last_Of (T, I + 1) + 1)))
      and then (T.N = 0 or else Last_Of (T, 1) = T.N));

   subtype Good_Tree is Tree with Dynamic_Predicate => Well_Formed (Good_Tree);

   --  No robbed house has a robbed child.
   function Independent (T : Good_Tree; S : One_Based_Choice) return Boolean
   with Pre => S'Last = T.N;

   --  The total of the robbed houses in the subtree of I.
   function Loot (T : Good_Tree; S : One_Based_Choice; I : Index) return Natural
   with
     Ghost,
     Pre                => S'Last = T.N and then I <= T.N,
     Post               => Loot'Result <= Max_Value * (Last_Of (T, I) - I + 1),
     Subprogram_Variant => (Decreases => T.N - I);

   --  The take/skip dynamic program over the subtrees.
   function Max_Loot (T : Good_Tree) return Natural
   with Post => Max_Loot'Result <= Max_Value * T.N;

   --  An optimal choice: independent, worth Max_Loot (a house is taken
   --  when taking it is at least as good as skipping it).
   function Best_Choice (T : Good_Tree) return One_Based_Choice
   with
     Post => Best_Choice'Result'Last = T.N
             and then Independent (T, Best_Choice'Result)
             and then (T.N = 0 or else Loot (T, Best_Choice'Result, 1) = Max_Loot (T));

   --  No independent choice is worth more than Max_Loot.
   procedure Lemma_Optimal (T : Good_Tree; S : One_Based_Choice)
   with
     Ghost,
     Global => null,
     Pre    => T.N >= 1 and then S'Last = T.N and then Independent (T, S),
     Post   => Loot (T, S, 1) <= Max_Loot (T);

private
   function Last_Of (T : Tree; I : Index) return Index is
     (if T.Right (I) in I + 1 .. T.N then Last_Of (T, T.Right (I))
      elsif T.Left (I) in I + 1 .. T.N then Last_Of (T, T.Left (I))
      else I);

   function Local (T : Good_Tree; S : One_Based_Choice; J : Index) return Boolean is
     (if S (J) then (T.Left (J) = 0 or else not S (T.Left (J)))
                    and then (T.Right (J) = 0 or else not S (T.Right (J))))
   with Pre => S'Last = T.N and then J <= T.N;

   function Independent (T : Good_Tree; S : One_Based_Choice) return Boolean is
     (for all J in 1 .. T.N => Local (T, S, J));

   function Loot (T : Good_Tree; S : One_Based_Choice; I : Index) return Natural is
     ((if S (I) then T.Value (I) else 0)
      + (if T.Left (I) = 0 then 0 else Loot (T, S, T.Left (I)))
      + (if T.Right (I) = 0 then 0 else Loot (T, S, T.Right (I))));
end House_Robber_III_Lite;
