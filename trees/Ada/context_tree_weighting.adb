-- context_tree_weighting.adb
-- Implementation of the Context Tree Weighting algorithm.

with Ada.Unchecked_Deallocation;

package body Context_Tree_Weighting is

   procedure Free_Node is new Ada.Unchecked_Deallocation (Node, Node_Access);

   -- Helper Function: Recursively frees the tree nodes
   procedure Free_Recursive (N : in out Node_Access) is
   begin
      if N /= null then
         Free_Recursive (N.Child_0);
         Free_Recursive (N.Child_1);
         Free_Node (N);
      end if;
   end Free_Recursive;

   function Initialize_Tree (Max_Depth : Natural) return Context_Tree is
   begin
      return (Root => null, Max_Depth => Max_Depth, Is_Initialized => True);
   end Initialize_Tree;

   procedure Free_Tree (Tree : in out Context_Tree) is
   begin
      Free_Recursive (Tree.Root);
      Tree.Is_Initialized := False;
   end Free_Tree;

   -- Helper Function: Recursive bottom-up tree weighting update
   procedure Update_Recursive
     (N         : in out Node_Access;
      Context   : in Bit_Array;
      Ctx_Idx   : in Integer;
      Next_Bit  : in Bit;
      Depth     : in Natural;
      Max_Depth : in Natural)
   is
      Target_Count : Natural;
      Total_Count  : Natural;
      Pw0, Pw1     : Long_Float;
   begin
      -- Dynamic allocation of nodes as they are visited
      if N = null then
         N := new Node;
      end if;

      -- 1. Update K-T estimator (P_e)
      if Next_Bit = 0 then
         Target_Count := N.Count_0;
      else
         Target_Count := N.Count_1;
      end if;
      
      Total_Count := N.Count_0 + N.Count_1;

      -- K-T formula incremental update: P_new = P_old * (count + 0.5) / (total + 1)
      N.P_e := N.P_e * (Long_Float (Target_Count) + 0.5) / Long_Float (Total_Count + 1);

      if Next_Bit = 0 then
         N.Count_0 := N.Count_0 + 1;
      else
         N.Count_1 := N.Count_1 + 1;
      end if;

      -- 2. Traverse down the context path if depth bounds permit
      if Depth < Max_Depth and then Ctx_Idx >= Context'First then
         if Context (Ctx_Idx) = 0 then
            Update_Recursive (N.Child_0, Context, Ctx_Idx - 1, Next_Bit, Depth + 1, Max_Depth);
         else
            Update_Recursive (N.Child_1, Context, Ctx_Idx - 1, Next_Bit, Depth + 1, Max_Depth);
         end if;
      end if;

      -- 3. Calculate Weighted Probability (P_w) Bottom-Up
      if Depth = Max_Depth then
         -- Leaf node variant: P_w strictly equals P_e
         N.P_w := N.P_e;
      else
         -- Internal node variant: P_w is weighted average of P_e and children P_w
         if N.Child_0 = null then Pw0 := 1.0; else Pw0 := N.Child_0.P_w; end if;
         if N.Child_1 = null then Pw1 := 1.0; else Pw1 := N.Child_1.P_w; end if;

         N.P_w := 0.5 * N.P_e + 0.5 * Pw0 * Pw1;
      end if;
   end Update_Recursive;

   procedure Update
     (Tree     : in out Context_Tree;
      Context  : in Bit_Array;
      Next_Bit : in Bit)
   is
   begin
      if not Tree.Is_Initialized then
         raise Tree_Uninitialized;
      end if;

      -- Start update recursively. We read the context backwards (most recent bit first).
      Update_Recursive
        (Tree.Root, Context, Context'Last, Next_Bit, 0, Tree.Max_Depth);
   end Update;

   function Get_Weighted_Probability (Tree : Context_Tree) return Long_Float is
   begin
      if not Tree.Is_Initialized then
         raise Tree_Uninitialized;
      end if;
      if Tree.Root = null then
         return 1.0; -- Probability of empty sequence
      end if;
      return Tree.Root.P_w;
   end Get_Weighted_Probability;

   function Get_KT_Probability (Tree : Context_Tree) return Long_Float is
   begin
      if not Tree.Is_Initialized then
         raise Tree_Uninitialized;
      end if;
      if Tree.Root = null then
         return 1.0;
      end if;
      return Tree.Root.P_e;
   end Get_KT_Probability;

end Context_Tree_Weighting;
