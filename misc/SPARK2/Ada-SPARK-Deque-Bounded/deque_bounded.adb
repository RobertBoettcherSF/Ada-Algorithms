pragma Ada_2022;
package body Deque_Bounded with SPARK_Mode => On is
   procedure Initialize (D : out Deque) is
   begin for I in Index loop D.Data (I) := 0; end loop; D.Head := 1; D.Tail := 1; D.Count := 0; end Initialize;
   function Length (D : Deque) return Natural is begin return D.Count; end Length;
   function Is_Empty (D : Deque) return Boolean is begin return D.Count = 0; end Is_Empty;
   function Is_Full (D : Deque) return Boolean is begin return D.Count = Capacity; end Is_Full;
   procedure Push_Front (D : in out Deque; Value : Integer) is
   begin if D.Head = 1 then D.Head := Index'Last; else D.Head := D.Head - 1; end if; D.Data (D.Head) := Value; if D.Count < Capacity then D.Count := D.Count + 1; end if; end Push_Front;
   procedure Push_Back (D : in out Deque; Value : Integer) is
   begin D.Data (D.Tail) := Value; if D.Tail = Index'Last then D.Tail := 1; else D.Tail := D.Tail + 1; end if; if D.Count < Capacity then D.Count := D.Count + 1; end if; end Push_Back;
   procedure Pop_Front (D : in out Deque; Value : out Integer) is
   begin Value := D.Data (D.Head); if D.Head = Index'Last then D.Head := 1; else D.Head := D.Head + 1; end if; if D.Count > 0 then D.Count := D.Count - 1; end if; end Pop_Front;
   procedure Pop_Back (D : in out Deque; Value : out Integer) is
   begin if D.Tail = 1 then D.Tail := Index'Last; else D.Tail := D.Tail - 1; end if; Value := D.Data (D.Tail); if D.Count > 0 then D.Count := D.Count - 1; end if; end Pop_Back;
end Deque_Bounded;
