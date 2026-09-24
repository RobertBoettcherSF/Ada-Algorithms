pragma Ada_2022;
package body Is_Graph_Bipartite with SPARK_Mode => On is
   type Color_Value is range 0 .. 2;
   type Color_Array is array (Vertex) of Color_Value;

   function Is_Bipartite (G : Graph) return Boolean is
      Color : Color_Array := (others => 0);
   begin
      for Start in Vertex loop
         if Color (Start) = 0 then
            Color (Start) := 1;
            for Round in 1 .. Capacity loop
               for From in Vertex loop
                  if Color (From) /= 0 then
                     for To in Vertex loop
                        if G (From, To) then
                           if Color (To) = 0 then
                              if Color (From) = 1 then
                                 Color (To) := 2;
                              else
                                 Color (To) := 1;
                              end if;
                           elsif Color (To) = Color (From) then
                              return False;
                           end if;
                        end if;
                     end loop;
                  end if;
               end loop;
            end loop;
         end if;
      end loop;
      return True;
   end Is_Bipartite;
end Is_Graph_Bipartite;
