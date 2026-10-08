pragma Ada_2022;
package body Bellman_Ford_Algorithm with SPARK_Mode => On is
   procedure Compute (Edges : in Edge_Array; Source : in Node; D : out Distance_Array) is
      Candidate : Distance;
   begin
      D := (others => Infinity); D (Source) := 0;
      for Pass in Node loop
         for I in Edge_Index loop
            if D (Edges (I).U) /= Infinity then
               if Edges (I).Weight >= 0 and then D (Edges (I).U) <= Distance'Last - Edges (I).Weight then
                  Candidate := D (Edges (I).U) + Edges (I).Weight;
                  if Candidate < D (Edges (I).V) then D (Edges (I).V) := Candidate; end if;
               elsif Edges (I).Weight < 0 and then D (Edges (I).U) >= Distance'First - Edges (I).Weight then
                  Candidate := D (Edges (I).U) + Edges (I).Weight;
                  if Candidate < D (Edges (I).V) then D (Edges (I).V) := Candidate; end if;
               end if;
            end if;
         end loop;
      end loop;
   end Compute;
end Bellman_Ford_Algorithm;
