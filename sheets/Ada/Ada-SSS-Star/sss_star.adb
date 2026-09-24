--  SSS_Star body — Stockman SSS* (OPEN LIVE/SOLVED) + minimax oracle.

pragma Ada_2022;

package body SSS_Star
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
            Slot       => 0,
            Tie        => 0);
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
         Slot       => 0,
         Tie        => 0);
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
      G.Nodes (N).Tie := 0;
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
   -- Validation + left-to-right tie keys
   ---------------------------------------------------------------------------

   procedure Validate_And_Number (G : in out Game_Tree) is
      Seen  : array (Valid_Node) of Boolean := [others => False];
      Next_Tie : Natural := 0;

      procedure Walk (N : Valid_Node) is
         Rec : Node_Rec renames G.Nodes (N);
      begin
         if Seen (N) then
            raise Invalid_Argument with "cycle in game tree";
         end if;
         Seen (N) := True;
         Next_Tie := Next_Tie + 1;
         Rec.Tie := Next_Tie;

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
   end Validate_And_Number;

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
      GT : Game_Tree := G;
   begin
      Validate_And_Number (GT);
      return Minimax_Node (GT, GT.Root);
   end Minimax;

   ---------------------------------------------------------------------------
   -- OPEN list for SSS*
   ---------------------------------------------------------------------------

   type Node_Status is (Live, Solved);

   type Open_Entry is record
      Node   : Valid_Node   := 1;
      Status : Node_Status  := Live;
      H      : Integer      := 0;
      Tie    : Natural      := 0;
   end record;

   --  Worst-case OPEN occupancy is modest for educational trees; allow
   --  headroom for simultaneous LIVE children under MAX nodes.
   Max_Open : constant Positive := Max_Nodes * 2 + 64;
   subtype Open_Count is Natural range 0 .. Max_Open;
   subtype Open_Index is Positive range 1 .. Max_Open;
   type Open_Store is array (Open_Index) of Open_Entry;

   type Open_List is record
      Data : Open_Store;
      Len  : Open_Count := 0;
   end record;

   function Better (A, B : Open_Entry) return Boolean is
   --  True when A should be popped before B (higher h; then smaller Tie).
   begin
      if A.H /= B.H then
         return A.H > B.H;
      end if;
      return A.Tie < B.Tie;
   end Better;

   procedure Open_Push (O : in out Open_List; E : Open_Entry) is
      I : Open_Index;
   begin
      if O.Len = Max_Open then
         raise Invalid_Argument with "SSS*: OPEN overflow";
      end if;
      O.Len := O.Len + 1;
      I := O.Len;
      O.Data (I) := E;
      --  Bubble toward front while better than predecessor (insertion).
      while I > 1 and then Better (O.Data (I), O.Data (I - 1)) loop
         declare
            Tmp : constant Open_Entry := O.Data (I);
         begin
            O.Data (I) := O.Data (I - 1);
            O.Data (I - 1) := Tmp;
         end;
         I := I - 1;
      end loop;
   end Open_Push;

   function Open_Pop (O : in out Open_List) return Open_Entry is
      E : Open_Entry;
   begin
      if O.Len = 0 then
         raise Invalid_Argument with "SSS*: OPEN empty";
      end if;
      E := O.Data (1);
      for I in 1 .. O.Len - 1 loop
         O.Data (I) := O.Data (I + 1);
      end loop;
      O.Len := O.Len - 1;
      return E;
   end Open_Pop;

   function Is_Ancestor_Or_Self
     (G : Game_Tree; Anc, N : Valid_Node) return Boolean
   is
      Cur : Node_Index := N;
   begin
      while Cur /= 0 loop
         if Cur = Anc then
            return True;
         end if;
         Cur := G.Nodes (Cur).Parent;
      end loop;
      return False;
   end Is_Ancestor_Or_Self;

   procedure Open_Purge_Children_Of
     (G : Game_Tree; O : in out Open_List; Parent : Valid_Node)
   is
   --  Remove every OPEN descriptor whose node lies in the subtree of any
   --  child of Parent (Wikipedia Γ case 4 / solution-tree close at MAX).
      New_Len : Open_Count := 0;
      Keep    : Boolean;
      N       : Valid_Node;
      Rec     : Node_Rec renames G.Nodes (Parent);
   begin
      for I in 1 .. O.Len loop
         N := O.Data (I).Node;
         Keep := True;
         for S in 1 .. Rec.N_Children loop
            if Is_Ancestor_Or_Self (G, Rec.Children (S), N) then
               Keep := False;
               exit;
            end if;
         end loop;
         if Keep then
            New_Len := New_Len + 1;
            O.Data (New_Len) := O.Data (I);
         end if;
      end loop;
      O.Len := New_Len;
   end Open_Purge_Children_Of;

   function First_Child (G : Game_Tree; N : Valid_Node) return Valid_Node is
   begin
      return G.Nodes (N).Children (1);
   end First_Child;

   function Next_Sibling
     (G : Game_Tree; N : Valid_Node) return Valid_Node
   is
      P : constant Node_Index := G.Nodes (N).Parent;
      S : constant Child_Count := G.Nodes (N).Slot;
   begin
      return G.Nodes (P).Children (S + 1);
   end Next_Sibling;

   function Is_Last_Child (G : Game_Tree; N : Valid_Node) return Boolean is
      P : constant Node_Index := G.Nodes (N).Parent;
   begin
      return G.Nodes (N).Slot = G.Nodes (P).N_Children;
   end Is_Last_Child;

   function Min_Int (A, B : Integer) return Integer is
   begin
      if A < B then
         return A;
      else
         return B;
      end if;
   end Min_Int;

   ---------------------------------------------------------------------------
   -- Stockman SSS* (educational OPEN-list formulation)
   ---------------------------------------------------------------------------

   function Evaluate (G : Game_Tree) return Integer is
      GT   : Game_Tree := G;
      Open : Open_List;
      P    : Open_Entry;
      Par  : Node_Index;
      Kind : Node_Kind;
      NC   : Child_Count;
      Val  : Integer;
      Tie  : Natural;
   begin
      Validate_And_Number (GT);

      Open_Push
        (Open,
         (Node   => GT.Root,
          Status => Live,
          H      => Pos_Inf,
          Tie    => GT.Nodes (GT.Root).Tie));

      loop
         P := Open_Pop (Open);
         Kind := GT.Nodes (P.Node).Kind;
         NC   := GT.Nodes (P.Node).N_Children;
         Val  := GT.Nodes (P.Node).Value;
         Tie  := GT.Nodes (P.Node).Tie;
         Par  := GT.Nodes (P.Node).Parent;

         if P.Node = GT.Root and then P.Status = Solved then
            return P.H;
         end if;

         case P.Status is
            when Live =>
               case Kind is
                  when Leaf =>
                     --  Γ (1): solve terminal with capped merit.
                     Open_Push
                       (Open,
                        (Node   => P.Node,
                         Status => Solved,
                         H      => Min_Int (P.H, Val),
                         Tie    => Tie));

                  when Min_Node =>
                     --  Γ (2): expand only the first child (left-to-right).
                     declare
                        C : constant Valid_Node := First_Child (GT, P.Node);
                     begin
                        Open_Push
                          (Open,
                           (Node   => C,
                            Status => Live,
                            H      => P.H,
                            Tie    => GT.Nodes (C).Tie));
                     end;

                  when Max_Node =>
                     --  Γ (3): expand every child as LIVE with the same bound.
                     for S in 1 .. NC loop
                        declare
                           C : constant Valid_Node :=
                             GT.Nodes (P.Node).Children (S);
                        begin
                           Open_Push
                             (Open,
                              (Node   => C,
                               Status => Live,
                               H      => P.H,
                               Tie    => GT.Nodes (C).Tie));
                        end;
                     end loop;
               end case;

            when Solved =>
               if Par = 0 then
                  --  Should have been caught by the root+Solved test above.
                  return P.H;
               end if;

               --  Parent-based Γ (4)/(5)/(6): completing a child under a
               --  MAX parent closes that solution-tree branch (purge
               --  siblings); under a MIN parent, continue left-to-right or
               --  solve the MIN when the last child is done.  Treating a
               --  solved leaf under MAX like Γ (4) correctly handles shallow
               --  Max→Leaf trees (Wikipedia phrases Γ (4) as "J is MIN").
               case GT.Nodes (Par).Kind is
                  when Max_Node =>
                     Open_Purge_Children_Of (GT, Open, Par);
                     Open_Push
                       (Open,
                        (Node   => Par,
                         Status => Solved,
                         H      => P.H,
                         Tie    => GT.Nodes (Par).Tie));

                  when Min_Node =>
                     if Is_Last_Child (GT, P.Node) then
                        Open_Push
                          (Open,
                           (Node   => Par,
                            Status => Solved,
                            H      => P.H,
                            Tie    => GT.Nodes (Par).Tie));
                     else
                        declare
                           Sib : constant Valid_Node :=
                             Next_Sibling (GT, P.Node);
                        begin
                           Open_Push
                             (Open,
                              (Node   => Sib,
                               Status => Live,
                               H      => P.H,
                               Tie    => GT.Nodes (Sib).Tie));
                        end;
                     end if;

                  when Leaf =>
                     raise Invalid_Argument with "SSS*: leaf parent";
               end case;
         end case;
      end loop;
   end Evaluate;

end SSS_Star;
