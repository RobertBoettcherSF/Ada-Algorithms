pragma Ada_2022;
package body Circular_Queue with SPARK_Mode => On is
   procedure Initialize (Q : out Queue) is
   begin for I in Index loop Q.Data (I) := 0; end loop; Q.Head := 1; Q.Tail := 1; Q.Count := 0; end Initialize;
   function Is_Empty (Q : Queue) return Boolean is begin return Q.Count = 0; end Is_Empty;
   function Is_Full (Q : Queue) return Boolean is begin return Q.Count = Capacity; end Is_Full;
   function Length (Q : Queue) return Natural is begin return Q.Count; end Length;
   procedure Enqueue (Q : in out Queue; Value : Integer) is
   begin Q.Data (Q.Tail) := Value; if Q.Tail = Index'Last then Q.Tail := 1; else Q.Tail := Q.Tail + 1; end if; if Q.Count < Capacity then Q.Count := Q.Count + 1; end if; end Enqueue;
   procedure Dequeue (Q : in out Queue; Value : out Integer) is
   begin Value := Q.Data (Q.Head); if Q.Head = Index'Last then Q.Head := 1; else Q.Head := Q.Head + 1; end if; if Q.Count > 0 then Q.Count := Q.Count - 1; end if; end Dequeue;
   function Peek (Q : Queue) return Integer is begin return Q.Data (Q.Head); end Peek;
end Circular_Queue;
