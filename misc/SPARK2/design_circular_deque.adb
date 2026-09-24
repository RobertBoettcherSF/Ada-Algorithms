pragma SPARK_Mode (On);
package body Design_Circular_Deque is
   function Empty return Deque is
   begin
      return (Values => (others => 0), Size => 0);
   end Empty;
   function Length (D : Deque) return Count is
   begin
      return D.Size;
   end Length;
   procedure Push_Front (D : in out Deque; V : Value) is
   begin
      case D.Size is
         when 0 => D.Values (1) := V;
         when 1 => D.Values (2) := D.Values (1); D.Values (1) := V;
         when 2 => D.Values (3) := D.Values (2); D.Values (2) := D.Values (1); D.Values (1) := V;
         when 3 => D.Values (4) := D.Values (3); D.Values (3) := D.Values (2); D.Values (2) := D.Values (1); D.Values (1) := V;
         when 4 => null;
      end case;
      if D.Size < Capacity then D.Size := D.Size + 1; end if;
   end Push_Front;
   procedure Push_Back (D : in out Deque; V : Value) is
   begin
      case D.Size is
         when 0 => D.Values (1) := V;
         when 1 => D.Values (2) := V;
         when 2 => D.Values (3) := V;
         when 3 => D.Values (4) := V;
         when 4 => null;
      end case;
      if D.Size < Capacity then D.Size := D.Size + 1; end if;
   end Push_Back;
   procedure Pop_Front (D : in out Deque) is
   begin
      case D.Size is
         when 1 => null;
         when 2 => D.Values (1) := D.Values (2);
         when 3 => D.Values (1) := D.Values (2); D.Values (2) := D.Values (3);
         when 4 => D.Values (1) := D.Values (2); D.Values (2) := D.Values (3); D.Values (3) := D.Values (4);
         when 0 => null;
      end case;
      if D.Size > 0 then D.Size := D.Size - 1; end if;
   end Pop_Front;
   function Front (D : Deque) return Value is
   begin
      return D.Values (1);
   end Front;
end Design_Circular_Deque;
