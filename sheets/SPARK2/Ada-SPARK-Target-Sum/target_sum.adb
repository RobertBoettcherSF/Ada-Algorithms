pragma SPARK_Mode (On);

package body Target_Sum is
   type Counts is array (Target) of Count;

   function Add (Left, Right : Count) return Count is
   begin
      if Left > Count'Last - Right then
         return Count'Last;
      else
         return Left + Right;
      end if;
   end Add;

   function Ways_To_Target
     (A : Values; N : Length; Goal : Target) return Count
   is
      Current : Counts := (others => 0);
      Next : Counts;
      V : Integer;
   begin
      Current (0) := 1;
      for I in 1 .. N loop
         Next := (others => 0);
         V := Integer (A (I));
         for S in Target loop
            if S <= Target'Last - V then
               Next (S + V) := Add (Next (S + V), Current (S));
            end if;
            if S >= Target'First + V then
               Next (S - V) := Add (Next (S - V), Current (S));
            end if;
         end loop;
         Current := Next;
      end loop;
      return Current (Goal);
   end Ways_To_Target;
end Target_Sum;
