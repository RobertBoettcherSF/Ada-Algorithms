pragma SPARK_Mode (On);

package body Subtree_Of_Another_Tree is
   function Empty return Tree is
   begin
      return (Values => (others => 0), Lefts => (others => 0),
              Rights => (others => 0), Used => (others => False));
   end Empty;

   procedure Set_Node
     (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index) is
   begin
      T.Values (Node) := V;
      T.Lefts (Node) := Left;
      T.Rights (Node) := Right;
      T.Used (Node) := True;
   end Set_Node;

   function Value_At (T : Tree; Node : Node_Index) return Value is
   begin
      return T.Values (Node);
   end Value_At;

   function Left_Child (T : Tree; Node : Node_Index) return Index is
   begin
      return T.Lefts (Node);
   end Left_Child;

   function Right_Child (T : Tree; Node : Node_Index) return Index is
   begin
      return T.Rights (Node);
   end Right_Child;


   subtype Stack_Position is Natural range 0 .. 256;
   type Pair_Array is array (Positive range 1 .. 256) of Index;

   function Same_At (A : Tree; ARoot : Index; B : Tree; BRoot : Index) return Boolean is
      As, Bs : Pair_Array := (others => 0); Top : Stack_Position; Same : Boolean := True;
   begin
      if ARoot = 0 or else BRoot = 0 then return ARoot = BRoot; end if;
      Top := 1; As (Top) := ARoot; Bs (Top) := BRoot;
      for Step in 1 .. 256 loop
         pragma Loop_Invariant (Top in Stack_Position);
         if Top > 0 and then Same then
            declare X : constant Index := As (Top); Y : constant Index := Bs (Top);
            begin
               Top := Top - 1;
               if A.Used (X) /= B.Used (Y) then
                  Same := False;
               elsif A.Used (X) then
                  if A.Values (X) /= B.Values (Y) then Same := False;
                  else
                     if A.Lefts (X) = 0 and then B.Lefts (Y) = 0 then null;
                     elsif A.Lefts (X) /= 0 and then B.Lefts (Y) /= 0 and then Top < Stack_Position'Last then
                        Top := Top + 1; As (Top) := A.Lefts (X); Bs (Top) := B.Lefts (Y);
                     else Same := False;
                     end if;
                     if A.Rights (X) = 0 and then B.Rights (Y) = 0 then null;
                     elsif A.Rights (X) /= 0 and then B.Rights (Y) /= 0 and then Top < Stack_Position'Last then
                        Top := Top + 1; As (Top) := A.Rights (X); Bs (Top) := B.Rights (Y);
                     else Same := False;
                     end if;
                  end if;
               end if;
            end;
         end if;
      end loop;
      return Same;
   end Same_At;

   function Is_Subtree
     (T : Tree; Root : Index; Pattern : Tree; Pattern_Root : Index) return Boolean is
      Found : Boolean := False;
   begin
      if Pattern_Root = 0 or else not Pattern.Used (Pattern_Root) then return True; end if;
      if Root = 0 or else not T.Used (Root) then return False; end if;
      for Candidate in Node_Index loop
         if T.Used (Candidate) and then T.Values (Candidate) = Pattern.Values (Pattern_Root) then
            if Same_At (T, Candidate, Pattern, Pattern_Root) then Found := True; end if;
         end if;
      end loop;
      return Found;
   end Is_Subtree;
end Subtree_Of_Another_Tree;
