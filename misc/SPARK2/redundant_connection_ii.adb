pragma SPARK_Mode (On);

package body Redundant_Connection_II with SPARK_Mode => On is
   function Has_Redundant_Edge
     (Edges : Edge_List; N : Edge_Index) return Boolean is
   begin
      for I in Edge_Index loop
         if I <= N then
            for J in Edge_Index loop
               if J <= N and then J > I
                 and then Edges (I).From = Edges (J).From
                 and then Edges (I).To = Edges (J).To
               then
                  return True;
               end if;
            end loop;
         end if;
      end loop;
      return False;
   end Has_Redundant_Edge;
end Redundant_Connection_II;
