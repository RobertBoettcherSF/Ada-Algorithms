pragma SPARK_Mode (On);

package body Queue_Using_Stacks is
   function Empty return Queue is
   begin
      return (Size => 0, V1 => 0, V2 => 0, V3 => 0, V4 => 0);
   end Empty;

   function Enqueue (Q : Queue; V : Value) return Queue is
      R : Queue := Q;
   begin
      case Q.Size is
         when 0 => R.V1 := V; R.Size := 1;
         when 1 => R.V2 := V; R.Size := 2;
         when 2 => R.V3 := V; R.Size := 3;
         when 3 => R.V4 := V; R.Size := 4;
         when 4 => null;
      end case;
      return R;
   end Enqueue;

   function Dequeue (Q : Queue) return Queue is
      R : Queue := Q;
   begin
      case Q.Size is
         when 0 => null;
         when 1 => R.Size := 0;
         when 2 => R.V1 := Q.V2; R.Size := 1;
         when 3 => R.V1 := Q.V2; R.V2 := Q.V3; R.Size := 2;
         when 4 => R.V1 := Q.V2; R.V2 := Q.V3; R.V3 := Q.V4; R.Size := 3;
      end case;
      return R;
   end Dequeue;

   function Front (Q : Queue) return Value is
   begin
      return Q.V1;
   end Front;
end Queue_Using_Stacks;
