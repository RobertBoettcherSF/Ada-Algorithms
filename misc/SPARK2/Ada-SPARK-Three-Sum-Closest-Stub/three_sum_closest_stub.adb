pragma Ada_2022;

package body Three_Sum_Closest_Stub with SPARK_Mode => On is
   function Distance (Candidate : Sum_Value; Target : Target_Value) return Integer is
   begin
      if Candidate >= Target then
         return Candidate - Target;
      else
         return Target - Candidate;
      end if;
   end Distance;

   function Choose (Current : Sum_Value; Candidate : Sum_Value;
                    Target : Target_Value) return Sum_Value is
   begin
      if Distance (Candidate, Target) < Distance (Current, Target) then
         return Candidate;
      else
         return Current;
      end if;
   end Choose;

   function Closest (Input : Input_Array; Target : Target_Value) return Sum_Value is
      Best : Sum_Value := Input (1) + Input (2) + Input (3);
   begin
      Best := Choose (Best, Input (1) + Input (2) + Input (4), Target);
      Best := Choose (Best, Input (1) + Input (2) + Input (5), Target);
      Best := Choose (Best, Input (1) + Input (3) + Input (4), Target);
      Best := Choose (Best, Input (1) + Input (3) + Input (5), Target);
      Best := Choose (Best, Input (1) + Input (4) + Input (5), Target);
      Best := Choose (Best, Input (2) + Input (3) + Input (4), Target);
      Best := Choose (Best, Input (2) + Input (3) + Input (5), Target);
      Best := Choose (Best, Input (2) + Input (4) + Input (5), Target);
      Best := Choose (Best, Input (3) + Input (4) + Input (5), Target);
      return Best;
   end Closest;
end Three_Sum_Closest_Stub;
