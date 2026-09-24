pragma Ada_2022;
package body Design_Front_Middle_Back_Queue with SPARK_Mode => On is
   procedure Initialize (Q : out Queue) is begin Q.Count := 0; for I in Index_Type loop Q.Data (I) := 0; end loop; end Initialize;
   procedure Enqueue (Q : in out Queue; Value : Integer) is begin if Q.Count < Capacity then Q.Count := Q.Count + 1; Q.Data (Q.Count) := Value; end if; end Enqueue;
   procedure Dequeue (Q : in out Queue; Value : out Integer) is
   begin Value := 0; if Q.Count > 0 then Value := Q.Data (1); for I in 1 .. Q.Count - 1 loop Q.Data (I) := Q.Data (I + 1); end loop; Q.Data (Q.Count) := 0; Q.Count := Q.Count - 1; end if; end Dequeue;
   function Is_Empty (Q : Queue) return Boolean is (Q.Count = 0); function Length (Q : Queue) return Count_Type is (Q.Count);
end Design_Front_Middle_Back_Queue;
