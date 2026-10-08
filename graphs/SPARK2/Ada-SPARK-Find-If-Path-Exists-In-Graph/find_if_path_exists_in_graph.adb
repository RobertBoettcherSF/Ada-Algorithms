pragma SPARK_Mode (On);

package body Find_If_Path_Exists_In_Graph with SPARK_Mode => On is
   function Path_Exists (Edges : Graph; Start, Goal : Vertex) return Boolean is
      type Queue_Index is range 0 .. Capacity;
      type Queue is array (Positive range 1 .. Capacity) of Vertex;
      Seen : Graph := [others => [others => False]];
      Work : Queue := [others => Vertex'First];
      Head : Queue_Index := 0;
      Tail : Queue_Index := 1;
      Current : Vertex;
   begin
      Seen (Start, Start) := True;
      Work (1) := Start;
      while Head < Tail loop
         pragma Loop_Variant (Increases => Head);
         Head := Head + 1;
         Current := Work (Positive (Head));
         if Current = Goal then
            return True;
         end if;
         for Next in Vertex loop
            if Edges (Current, Next) and then not Seen (Start, Next) then
               Seen (Start, Next) := True;
               if Tail < Queue_Index (Capacity) then
                  Tail := Tail + 1;
                  Work (Positive (Tail)) := Next;
               end if;
            end if;
         end loop;
      end loop;
      return False;
   end Path_Exists;
end Find_If_Path_Exists_In_Graph;
