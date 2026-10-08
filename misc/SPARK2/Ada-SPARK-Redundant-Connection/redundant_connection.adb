pragma SPARK_Mode (On);

package body Redundant_Connection is
   type Parent_Array is array (Vertex) of Vertex;

   function Find_Redundant (Edges : Edge_Array) return Edge is
      Parent : Parent_Array := (1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5);
      Answer : Edge := Edges (Edges'Last);
      Found  : Boolean := False;
   begin
      for E in Edges'Range loop
         declare
            Left  : Vertex := Edges (E).From;
            Right : Vertex := Edges (E).To;
         begin
            for Step in 1 .. Capacity loop
               if Parent (Left) /= Left then
                  Left := Parent (Left);
               end if;
               if Parent (Right) /= Right then
                  Right := Parent (Right);
               end if;
            end loop;
            if Left = Right then
               if not Found then
                  Answer := Edges (E);
                  Found := True;
               end if;
            else
               Parent (Left) := Right;
            end if;
         end;
      end loop;
      return Answer;
   end Find_Redundant;
end Redundant_Connection;
