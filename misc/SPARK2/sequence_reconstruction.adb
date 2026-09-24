pragma SPARK_Mode (On);

package body Sequence_Reconstruction with SPARK_Mode => On is
   function Matches (Expected, Candidate : Sequence; N : Length) return Boolean is
   begin
      for I in 1 .. N loop
         if Expected (I) /= Candidate (I) then
            return False;
         end if;
      end loop;
      return True;
   end Matches;
end Sequence_Reconstruction;
