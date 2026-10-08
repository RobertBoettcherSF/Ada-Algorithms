pragma Ada_2022;
package body All_Paths_From_Source_To_Target with SPARK_Mode => On is
   type Reachability is array (Node) of Boolean;

   function Has_Path (G : Graph) return Boolean is
      Seen : Reachability := (others => False);
   begin
      Seen (Node'First) := True;
      for Round in 1 .. Capacity loop
         for From in Node loop
            if Seen (From) then
               for To in Node loop
                  if G (From, To) then
                     Seen (To) := True;
                  end if;
               end loop;
            end if;
         end loop;
      end loop;
      return Seen (Node'Last);
   end Has_Path;
end All_Paths_From_Source_To_Target;
