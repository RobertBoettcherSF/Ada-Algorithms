pragma SPARK_Mode (On);

package body Delete_Node_In_A_BST_Lite is
   function Empty return Tree is
   begin
      return (Values => (others => 0), Lefts => (others => 0), Rights => (others => 0), Used => (others => False));
   end Empty;

   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index) is
   begin
      T.Values (Node) := V;
      T.Lefts (Node) := Left;
      T.Rights (Node) := Right;
      T.Used (Node) := True;
   end Set_Node;

   procedure Delete_Node (T : in out Tree; Root : in out Index; Key : Value) is
      Current : Index := Root;
      Found : Boolean := False;
   begin
      for Step in 1 .. 16 loop
         exit when Current = 0 or else Found;
         if T.Used (Current) then
            if T.Values (Current) = Key then
               Found := True;
               if Current = Root then
                  Root := 0;
               else
                  T.Used (Current) := False;
               end if;
            elsif Key < T.Values (Current) then
               Current := T.Lefts (Current);
            else
               Current := T.Rights (Current);
            end if;
         else
            Current := 0;
         end if;
      end loop;
   end Delete_Node;
end Delete_Node_In_A_BST_Lite;
