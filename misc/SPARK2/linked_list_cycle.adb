pragma SPARK_Mode (On);
package body Linked_List_Cycle is
   function Empty return List is begin return (Nexts => (others => 0), Used => (others => False)); end Empty;
   procedure Set_Next (L : in out List; Node : Node_Index; Next : Index) is
   begin L.Nexts (Node) := Next; L.Used (Node) := True; end Set_Next;
   function Has_Cycle (L : List; Head : Index) return Boolean is
      Seen : array (Index) of Boolean := (others => False); Current : Index := Head;
   begin
      for Step in 1 .. 16 loop
         exit when Current = 0 or else not L.Used (Current);
         if Seen (Current) then return True; end if;
         Seen (Current) := True; Current := L.Nexts (Current);
      end loop;
      return Current /= 0 and then L.Used (Current) and then Seen (Current);
   end Has_Cycle;
end Linked_List_Cycle;
