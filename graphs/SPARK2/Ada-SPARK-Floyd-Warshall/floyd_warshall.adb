pragma Ada_2022;
package body Floyd_Warshall with SPARK_Mode => On is
   procedure Compute (D : in out Distance_Matrix) is
      Candidate : Distance;
   begin
      for K in Node loop
         for I in Node loop
            for J in Node loop
               if D (I, K) < Infinity and then D (K, J) < Infinity and then
                 D (I, K) <= Infinity - D (K, J)
               then
                  Candidate := D (I, K) + D (K, J);
                  if Candidate < D (I, J) then D (I, J) := Candidate; end if;
               end if;
            end loop;
         end loop;
      end loop;
   end Compute;
end Floyd_Warshall;
