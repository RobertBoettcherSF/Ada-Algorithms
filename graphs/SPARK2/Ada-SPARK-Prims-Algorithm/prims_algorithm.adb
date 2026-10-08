pragma Ada_2022;
package body Prims_Algorithm with SPARK_Mode => On is
   procedure Compute (Graph : in Weight_Matrix; Parent : out Parent_Array) is
      Key : array (Node) of Weight := (others => Infinity);
      Used : array (Node) of Boolean := (others => False);
      Best : Node := Node'First;
      Found : Boolean;
   begin
      Parent := (others => Node'First); Key (Node'First) := 0;
      for Step in Node loop
         Found := False;
         for N in Node loop
            if not Used (N) and then not Found and then Key (N) < Infinity then
               Best := N; Found := True;
            end if;
         end loop;
         if Found then
            Used (Best) := True;
            for N in Node loop
               if not Used (N) and then Graph (Best, N) < Key (N) then
                  Key (N) := Graph (Best, N); Parent (N) := Best;
               end if;
            end loop;
         end if;
      end loop;
   end Compute;
end Prims_Algorithm;
