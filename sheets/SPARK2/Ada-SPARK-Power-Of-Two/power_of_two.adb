pragma SPARK_Mode (On);

package body Power_Of_Two is
   function Is_Power (Value : Input) return Boolean is
      Candidate : Input := 1;
   begin
      while Candidate <= Value / 2 loop
         pragma Loop_Invariant (Candidate <= Value);
         pragma Loop_Variant (Decreases => Value - Candidate);
         Candidate := Candidate * 2;
      end loop;
      return Candidate = Value;
   end Is_Power;
end Power_Of_Two;
