pragma SPARK_Mode (On);

package body Circular_Deque_Stub is
   function Empty return Deque is
   begin
      return (Size => 0, V1 => 0, V2 => 0, V3 => 0, V4 => 0);
   end Empty;

   function Push_Back (D : Deque; V : Value) return Deque is
      R : Deque := D;
   begin
      case D.Size is
         when 0 => R.V1 := V; R.Size := 1;
         when 1 => R.V2 := V; R.Size := 2;
         when 2 => R.V3 := V; R.Size := 3;
         when 3 => R.V4 := V; R.Size := 4;
         when 4 => null;
      end case;
      return R;
   end Push_Back;

   function Push_Front (D : Deque; V : Value) return Deque is
      R : Deque := D;
   begin
      case D.Size is
         when 0 => R.V1 := V; R.Size := 1;
         when 1 => R.V2 := D.V1; R.V1 := V; R.Size := 2;
         when 2 => R.V3 := D.V2; R.V2 := D.V1; R.V1 := V; R.Size := 3;
         when 3 => R.V4 := D.V3; R.V3 := D.V2; R.V2 := D.V1; R.V1 := V; R.Size := 4;
         when 4 => null;
      end case;
      return R;
   end Push_Front;

   function Pop_Front (D : Deque) return Deque is
      R : Deque := D;
   begin
      case D.Size is
         when 0 => null;
         when 1 => R.Size := 0;
         when 2 => R.V1 := D.V2; R.Size := 1;
         when 3 => R.V1 := D.V2; R.V2 := D.V3; R.Size := 2;
         when 4 => R.V1 := D.V2; R.V2 := D.V3; R.V3 := D.V4; R.Size := 3;
      end case;
      return R;
   end Pop_Front;

   function Pop_Back (D : Deque) return Deque is
      R : Deque := D;
   begin
      case D.Size is
         when 0 => null;
         when 1 => R.Size := 0;
         when 2 => R.Size := 1;
         when 3 => R.Size := 2;
         when 4 => R.Size := 3;
      end case;
      return R;
   end Pop_Back;

   function Front (D : Deque) return Value is
   begin
      return D.V1;
   end Front;

   function Back (D : Deque) return Value is
   begin
      case D.Size is
         when 0 => return 0;
         when 1 => return D.V1;
         when 2 => return D.V2;
         when 3 => return D.V3;
         when 4 => return D.V4;
      end case;
   end Back;
end Circular_Deque_Stub;
