--  B_Star body — Berliner educational B* (interval bounds) + minimax oracle.

pragma Ada_2022;

package body B_Star
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Build
   ---------------------------------------------------------------------------

   procedure Clear (G : in out Game_Tree) is
   begin
      G.Count := 0;
      G.Root  := 0;
      for I in Valid_Node loop
         G.Nodes (I) :=
           (Kind       => Leaf,
            Value      => 0,
            N_Children => 0,
            Children   => [others => 0],
            Parent     => 0,
            Slot       => 0);
      end loop;
   end Clear;

   function Add_Leaf
     (G     : in out Game_Tree;
      Value : Integer) return Valid_Node
   is
      N : Valid_Node;
   begin
      if G.Count >= Max_Nodes then
         raise Invalid_Argument with "Add_Leaf: tree full";
      end if;
      G.Count := G.Count + 1;
      N := Valid_Node (G.Count);
      G.Nodes (N) :=
        (Kind       => Leaf,
         Value      => Value,
         N_Children => 0,
         Children   => [others => 0],
         Parent     => 0,
         Slot       => 0);
      return N;
   end Add_Leaf;

   function Add_Internal
     (G        : in out Game_Tree;
      Kind     : Node_Kind;
      Children : Node_List) return Valid_Node
   is
      N : Valid_Node;
   begin
      if Kind = Leaf then
         raise Invalid_Argument with "Add_Internal: Kind must be Max/Min";
      end if;
      if Children'Length = 0 then
         raise Invalid_Argument with "Add_Internal: empty children";
      end if;
      if Children'Length > Max_Children then
         raise Invalid_Argument with "Add_Internal: too many children";
      end if;
      if G.Count >= Max_Nodes then
         raise Invalid_Argument with "Add_Internal: tree full";
      end if;

      for C of Children loop
         if Natural (C) > G.Count then
            raise Invalid_Argument with "Add_Internal: unknown child";
         end if;
         if G.Nodes (C).Parent /= 0 then
            raise Invalid_Argument with "Add_Internal: child already linked";
         end if;
      end loop;

      --  Reject duplicate children in the list.
      for I in Children'Range loop
         for J in Children'First .. I - 1 loop
            if Children (I) = Children (J) then
               raise Invalid_Argument with "Add_Internal: duplicate child";
            end if;
         end loop;
      end loop;

      G.Count := G.Count + 1;
      N := Valid_Node (G.Count);
      G.Nodes (N).Kind := Kind;
      G.Nodes (N).N_Children := Child_Count (Children'Length);
      G.Nodes (N).Value := 0;
      G.Nodes (N).Parent := 0;
      G.Nodes (N).Slot := 0;
      G.Nodes (N).Children := [others => 0];

      declare
         Slot : Child_Count := 0;
      begin
         for C of Children loop
            Slot := Slot + 1;
            G.Nodes (N).Children (Slot) := C;
            G.Nodes (C).Parent := N;
            G.Nodes (C).Slot := Slot;
         end loop;
      end;
      return N;
   end Add_Internal;

   procedure Set_Root (G : in out Game_Tree; Root : Valid_Node) is
   begin
      if Natural (Root) > G.Count then
         raise Invalid_Argument with "Set_Root: unknown node";
      end if;
      G.Root := Root;
   end Set_Root;

   function Node_Count (G : Game_Tree) return Natural is
   begin
      return G.Count;
   end Node_Count;

   function Root_Of (G : Game_Tree) return Node_Index is
   begin
      return G.Root;
   end Root_Of;

   function Kind_Of (G : Game_Tree; N : Valid_Node) return Node_Kind is
   begin
      if Natural (N) > G.Count then
         raise Invalid_Argument with "Kind_Of: unknown node";
      end if;
      return G.Nodes (N).Kind;
   end Kind_Of;

   function Leaf_Value (G : Game_Tree; N : Valid_Node) return Integer is
   begin
      if Natural (N) > G.Count then
         raise Invalid_Argument with "Leaf_Value: unknown node";
      end if;
      return G.Nodes (N).Value;
   end Leaf_Value;

   function Child_Count_Of (G : Game_Tree; N : Valid_Node) return Child_Count is
   begin
      if Natural (N) > G.Count then
         raise Invalid_Argument with "Child_Count_Of: unknown node";
      end if;
      return G.Nodes (N).N_Children;
   end Child_Count_Of;

   function Child_Of
     (G : Game_Tree; N : Valid_Node; Slot : Child_Slot) return Node_Index
   is
   begin
      if Natural (N) > G.Count then
         raise Invalid_Argument with "Child_Of: unknown node";
      end if;
      if Slot > G.Nodes (N).N_Children then
         return 0;
      end if;
      return G.Nodes (N).Children (Slot);
   end Child_Of;

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   procedure Validate (G : Game_Tree) is
      Seen : array (Valid_Node) of Boolean := [others => False];

      procedure Walk (N : Valid_Node) is
         Rec : Node_Rec renames G.Nodes (N);
      begin
         if Seen (N) then
            raise Invalid_Argument with "cycle in game tree";
         end if;
         Seen (N) := True;

         case Rec.Kind is
            when Leaf =>
               if Rec.N_Children /= 0 then
                  raise Invalid_Argument with "leaf with children";
               end if;
            when Max_Node | Min_Node =>
               if Rec.N_Children = 0 then
                  raise Invalid_Argument with "internal node without children";
               end if;
               for S in 1 .. Rec.N_Children loop
                  declare
                     C : constant Node_Index := Rec.Children (S);
                  begin
                     if C = 0 or else Natural (C) > G.Count then
                        raise Invalid_Argument with "bad child index";
                     end if;
                     if G.Nodes (C).Parent /= N then
                        raise Invalid_Argument with "broken parent link";
                     end if;
                     Walk (C);
                  end;
               end loop;
         end case;
      end Walk;
   begin
      if G.Count = 0 or else G.Root = 0 then
         raise Invalid_Argument with "empty tree or unset root";
      end if;
      if Natural (G.Root) > G.Count then
         raise Invalid_Argument with "root out of range";
      end if;
      Walk (G.Root);
   end Validate;

   ---------------------------------------------------------------------------
   -- Minimax oracle
   ---------------------------------------------------------------------------

   function Minimax_Node (G : Game_Tree; N : Valid_Node) return Integer is
      Rec : Node_Rec renames G.Nodes (N);
      Acc : Integer;
      V   : Integer;
   begin
      case Rec.Kind is
         when Leaf =>
            return Rec.Value;
         when Max_Node =>
            Acc := Neg_Inf;
            for S in 1 .. Rec.N_Children loop
               V := Minimax_Node (G, Rec.Children (S));
               if V > Acc then
                  Acc := V;
               end if;
            end loop;
            return Acc;
         when Min_Node =>
            Acc := Pos_Inf;
            for S in 1 .. Rec.N_Children loop
               V := Minimax_Node (G, Rec.Children (S));
               if V < Acc then
                  Acc := V;
               end if;
            end loop;
            return Acc;
      end case;
   end Minimax_Node;

   function Minimax (G : Game_Tree) return Integer is
   begin
      Validate (G);
      return Minimax_Node (G, G.Root);
   end Minimax;

   ---------------------------------------------------------------------------
   -- Educational B*: interval store + prove-best / disprove-rest
   ---------------------------------------------------------------------------

   type Bound_Rec is record
      Lo       : Integer := Neg_Inf;
      Hi       : Integer := Pos_Inf;
      Expanded : Boolean := False;
   end record;

   type Bound_Store is array (Valid_Node) of Bound_Rec;

   function Max_Int (A, B : Integer) return Integer is
   begin
      if A > B then
         return A;
      else
         return B;
      end if;
   end Max_Int;

   function Min_Int (A, B : Integer) return Integer is
   begin
      if A < B then
         return A;
      else
         return B;
      end if;
   end Min_Int;

   --  Recompute [Lo, Hi] bottom-up for the whole rooted tree.
   procedure Backup_All
     (G : Game_Tree; B : in out Bound_Store; N : Valid_Node)
   is
      Rec : Node_Rec renames G.Nodes (N);
      Acc_Lo, Acc_Hi : Integer;
      C : Valid_Node;
   begin
      case Rec.Kind is
         when Leaf =>
            if B (N).Expanded then
               null;  -- already [v, v]
            else
               B (N).Lo := Neg_Inf;
               B (N).Hi := Pos_Inf;
            end if;

         when Max_Node =>
            Acc_Lo := Neg_Inf;
            Acc_Hi := Neg_Inf;
            for S in 1 .. Rec.N_Children loop
               C := Rec.Children (S);
               Backup_All (G, B, C);
               Acc_Lo := Max_Int (Acc_Lo, B (C).Lo);
               Acc_Hi := Max_Int (Acc_Hi, B (C).Hi);
            end loop;
            B (N).Lo := Acc_Lo;
            B (N).Hi := Acc_Hi;

         when Min_Node =>
            Acc_Lo := Pos_Inf;
            Acc_Hi := Pos_Inf;
            for S in 1 .. Rec.N_Children loop
               C := Rec.Children (S);
               Backup_All (G, B, C);
               Acc_Lo := Min_Int (Acc_Lo, B (C).Lo);
               Acc_Hi := Min_Int (Acc_Hi, B (C).Hi);
            end loop;
            B (N).Lo := Acc_Lo;
            B (N).Hi := Acc_Hi;
      end case;
   end Backup_All;

   function Is_Open (B : Bound_Store; N : Valid_Node) return Boolean is
   --  Interval not yet a singleton — still worth refining.
   begin
      return B (N).Lo < B (N).Hi;
   end Is_Open;

   --  Most optimistic open child for the side to move (descent / prove-best).
   function Best_Optimistic_Child
     (G : Game_Tree; B : Bound_Store; N : Valid_Node) return Valid_Node
   is
      Rec   : Node_Rec renames G.Nodes (N);
      Best  : Valid_Node := Rec.Children (1);
      Found : Boolean := False;
      C     : Valid_Node;
   begin
      for S in 1 .. Rec.N_Children loop
         C := Rec.Children (S);
         if Is_Open (B, C) then
            if not Found then
               Best := C;
               Found := True;
            else
               case Rec.Kind is
                  when Max_Node =>
                     --  Highest Hi; leftmost tie-break (stable scan).
                     if B (C).Hi > B (Best).Hi then
                        Best := C;
                     end if;
                  when Min_Node =>
                     --  Lowest Lo (optimistic for minimiser).
                     if B (C).Lo < B (Best).Lo then
                        Best := C;
                     end if;
                  when Leaf =>
                     null;
               end case;
            end if;
         end if;
      end loop;
      if not Found then
         --  All children proven; return first (caller should not descend).
         return Rec.Children (1);
      end if;
      return Best;
   end Best_Optimistic_Child;

   --  Runner-up optimistic open child (disprove-rest target).
   function Second_Optimistic_Child
     (G : Game_Tree; B : Bound_Store; N : Valid_Node) return Valid_Node
   is
      Rec    : Node_Rec renames G.Nodes (N);
      First  : constant Valid_Node := Best_Optimistic_Child (G, B, N);
      Second : Valid_Node := First;
      Found  : Boolean := False;
      C      : Valid_Node;
   begin
      for S in 1 .. Rec.N_Children loop
         C := Rec.Children (S);
         if C /= First and then Is_Open (B, C) then
            if not Found then
               Second := C;
               Found := True;
            else
               case Rec.Kind is
                  when Max_Node =>
                     if B (C).Hi > B (Second).Hi then
                        Second := C;
                     end if;
                  when Min_Node =>
                     if B (C).Lo < B (Second).Lo then
                        Second := C;
                     end if;
                  when Leaf =>
                     null;
               end case;
            end if;
         end if;
      end loop;
      return Second;
   end Second_Optimistic_Child;

   --  True when disprove-rest is meaningful (Wikipedia precondition):
   --  the prove-best child's pessimistic bound is already best among siblings.
   function Disprove_Rest_Ready
     (G : Game_Tree; B : Bound_Store; N : Valid_Node) return Boolean
   is
      Rec  : Node_Rec renames G.Nodes (N);
      Best : constant Valid_Node := Best_Optimistic_Child (G, B, N);
      C    : Valid_Node;
   begin
      case Rec.Kind is
         when Max_Node =>
            for S in 1 .. Rec.N_Children loop
               C := Rec.Children (S);
               if C /= Best and then B (C).Lo > B (Best).Lo then
                  return False;
               end if;
            end loop;
            return True;
         when Min_Node =>
            for S in 1 .. Rec.N_Children loop
               C := Rec.Children (S);
               if C /= Best and then B (C).Hi < B (Best).Hi then
                  return False;
               end if;
            end loop;
            return True;
         when Leaf =>
            return False;
      end case;
   end Disprove_Rest_Ready;

   function Has_Open_Sibling
     (G : Game_Tree; B : Bound_Store; N, Skip : Valid_Node) return Boolean
   is
      Rec : Node_Rec renames G.Nodes (N);
      C   : Valid_Node;
   begin
      for S in 1 .. Rec.N_Children loop
         C := Rec.Children (S);
         if C /= Skip and then Is_Open (B, C) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Open_Sibling;

   --  Choose which root child to enter (prove-best vs disprove-rest).
   function Select_Root_Child
     (G : Game_Tree; B : Bound_Store; Root : Valid_Node) return Valid_Node
   is
      Best   : constant Valid_Node := Best_Optimistic_Child (G, B, Root);
      Second : Valid_Node;
   begin
      if not Is_Open (B, Best) then
         --  Leader already proven; must refine a rival if any remain open.
         if Has_Open_Sibling (G, B, Root, Best) then
            return Second_Optimistic_Child (G, B, Root);
         end if;
         return Best;
      end if;

      if Disprove_Rest_Ready (G, B, Root)
        and then Has_Open_Sibling (G, B, Root, Best)
      then
         Second := Second_Optimistic_Child (G, B, Root);
         --  Prefer disprove-rest when the leader's Lo already dominates
         --  sibling Los (MAX) / His (MIN); otherwise prove-best.
         return Second;
      end if;

      return Best;
   end Select_Root_Child;

   --  Descend from a chosen root child to a pending leaf.
   function Descend_To_Leaf
     (G : Game_Tree; B : Bound_Store; Start : Valid_Node) return Valid_Node
   is
      N : Valid_Node := Start;
      C : Valid_Node;
   begin
      while G.Nodes (N).Kind /= Leaf loop
         if not Is_Open (B, N) then
            --  Should not happen if Start was open; pick any child.
            N := G.Nodes (N).Children (1);
         else
            C := Best_Optimistic_Child (G, B, N);
            N := C;
         end if;
      end loop;
      return N;
   end Descend_To_Leaf;

   function Evaluate (G : Game_Tree) return Integer is
      B        : Bound_Store;
      Root     : Valid_Node;
      Leaf_N   : Valid_Node;
      Child    : Valid_Node;
      Steps    : Natural := 0;
      Max_Steps : constant Natural := Max_Nodes + 8;
   begin
      Validate (G);
      Root := G.Root;

      for I in Valid_Node range 1 .. Valid_Node (G.Count) loop
         B (I) := (Lo => Neg_Inf, Hi => Pos_Inf, Expanded => False);
      end loop;

      --  Trivial root leaf.
      if G.Nodes (Root).Kind = Leaf then
         B (Root).Lo := G.Nodes (Root).Value;
         B (Root).Hi := G.Nodes (Root).Value;
         B (Root).Expanded := True;
         return B (Root).Lo;
      end if;

      Backup_All (G, B, Root);

      while B (Root).Lo < B (Root).Hi loop
         Steps := Steps + 1;
         if Steps > Max_Steps then
            --  Safety net: finite trees with exact leaves must terminate.
            raise Invalid_Argument with "B*: failed to refine root bounds";
         end if;

         Child := Select_Root_Child (G, B, Root);
         Leaf_N := Descend_To_Leaf (G, B, Child);

         if B (Leaf_N).Expanded then
            --  Path led to an already-expanded leaf; force another open leaf
            --  by scanning (educational fallback — should be rare).
            declare
               Found : Boolean := False;
            begin
               for I in Valid_Node range 1 .. Valid_Node (G.Count) loop
                  if G.Nodes (I).Kind = Leaf
                    and then not B (I).Expanded
                  then
                     Leaf_N := I;
                     Found := True;
                     exit;
                  end if;
               end loop;
               if not Found then
                  --  All leaves expanded; recompute and exit.
                  Backup_All (G, B, Root);
                  exit;
               end if;
            end;
         end if;

         B (Leaf_N).Lo := G.Nodes (Leaf_N).Value;
         B (Leaf_N).Hi := G.Nodes (Leaf_N).Value;
         B (Leaf_N).Expanded := True;
         Backup_All (G, B, Root);
      end loop;

      return B (Root).Lo;
   end Evaluate;

end B_Star;
