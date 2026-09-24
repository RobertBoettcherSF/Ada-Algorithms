pragma SPARK_Mode (On);

package body Floyd_Warshall_Lite with SPARK_Mode => On is
   function Shortest_Path (Edges : Graph; Start, Goal : Vertex) return Distance is
      Best : Distance := Distance'Last;
      Candidate : Distance;
   begin
      if Start = Goal then
         return 0;
      end if;
      if Edges (Start, Goal) > 0 then
         Best := Distance (Edges (Start, Goal));
      end if;
      for Through in Vertex loop
         if Edges (Start, Through) > 0
           and then Edges (Through, Goal) > 0
         then
            Candidate := Distance (Edges (Start, Through))
              + Distance (Edges (Through, Goal));
            if Candidate < Best then
               Best := Candidate;
            end if;
         end if;
      end loop;
      return Best;
   end Shortest_Path;
end Floyd_Warshall_Lite;
