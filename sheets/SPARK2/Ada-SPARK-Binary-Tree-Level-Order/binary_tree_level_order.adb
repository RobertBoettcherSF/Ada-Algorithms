pragma SPARK_Mode (On);
package body Binary_Tree_Level_Order is
   function Empty return Tree is begin return (Values => (others => 0), Lefts => (others => 0), Rights => (others => 0), Used => (others => False)); end Empty;
   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index) is
   begin T.Values (Node) := V; T.Lefts (Node) := Left; T.Rights (Node) := Right; T.Used (Node) := True; end Set_Node;
   function Level_Order_Sum (T : Tree; Root : Index) return Long_Long_Integer is
      subtype Position is Natural range 0 .. 16;
      Queue : array (Position) of Index := (others => 0); Head : Position := 0; Tail : Position; Total : Long_Long_Integer := 0;
   begin
      if Root = 0 or else not T.Used (Root) then return 0; end if;
      Tail := 1; Queue (Tail) := Root;
      for Step in 1 .. 16 loop
         pragma Loop_Invariant
           (Head in Position and then Tail in Position
            and then Total in Long_Long_Integer (-100 * (Step - 1)) .. Long_Long_Integer (100 * (Step - 1)));
         exit when Head = Tail;
         if Head < Position'Last then Head := Head + 1; end if;
         declare N : constant Index := Queue (Head); begin
            if T.Used (N) then Total := Total + Long_Long_Integer (T.Values (N));
               if T.Lefts (N) /= 0 and then Tail < Position'Last then
                     Tail := Tail + 1; Queue (Tail) := T.Lefts (N);
               end if;
               if T.Rights (N) /= 0 and then Tail < Position'Last then
                     Tail := Tail + 1; Queue (Tail) := T.Rights (N);
               end if;
            end if;
         end;
      end loop; return Total;
   end Level_Order_Sum;
end Binary_Tree_Level_Order;
