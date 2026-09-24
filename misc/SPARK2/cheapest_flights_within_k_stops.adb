pragma Ada_2022;
package body Cheapest_Flights_Within_K_Stops with SPARK_Mode => On is
   procedure Compute (Edges : in Edge_Array; Source, Destination : in Node;
                       K : in Stop_Count; Result : out Cost) is
      type Cost_Array is array (Node) of Cost;
      Best : Cost_Array := (others => Infinity);
      Next_Best : Cost_Array;
      Candidate : Cost;
   begin
      Best (Source) := 0;
      for Pass in Stop_Count loop
         Next_Best := Best;
         if Pass <= K then
            for I in Edge_Index loop
               if Best (Edges (I).U) /= Infinity
                 and then Best (Edges (I).U) <= Cost'Last - Edges (I).Price
               then
                  Candidate := Best (Edges (I).U) + Edges (I).Price;
                  if Candidate < Next_Best (Edges (I).V) then
                     Next_Best (Edges (I).V) := Candidate;
                  end if;
               end if;
            end loop;
            Best := Next_Best;
         end if;
      end loop;
      Result := Best (Destination);
   end Compute;
end Cheapest_Flights_Within_K_Stops;
