pragma Ada_2022;
package body Power_Of_Four with SPARK_Mode => On is
   function Is_Power (Value : Input) return Boolean is
      Candidate : Input := 1;
   begin
      while Candidate <= Value / 4 loop
         pragma Loop_Invariant (Candidate <= Value);
         pragma Loop_Variant (Decreases => Value - Candidate);
         Candidate := Candidate * 4;
      end loop;
      return Candidate = Value;
   end Is_Power;
end Power_Of_Four;
