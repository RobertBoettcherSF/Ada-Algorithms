pragma Ada_2022;
package body Redundant_Connection_II_Lite with SPARK_Mode => On is
   procedure Find_Redundant (Edges : in Edge_Array; Nodes : in Node_Count;
                             Edge_Count : in Edge_Index; Result : out Edge_Result) is
   begin
      Result := 0;
      for Candidate in reverse Edge_Index'First .. Edge_Count loop
         declare
            In_Degree : array (Node) of Natural range 0 .. Edge_Capacity := (others => 0);
            Reachable : array (Node) of Boolean := (others => False);
            Root : Node := Node'First;
            Roots : Natural range 0 .. Capacity := 0;
            Valid : Boolean := True;
         begin
            for I in Edge_Index loop
               if I <= Edge_Count and then I /= Candidate and then Edges (I).U <= Nodes and then Edges (I).V <= Nodes then
                  if In_Degree (Edges (I).V) < Edge_Capacity then
                     In_Degree (Edges (I).V) := In_Degree (Edges (I).V) + 1;
                  else
                     Valid := False;
                  end if;
               end if;
            end loop;
            for N in Node loop
               if N <= Nodes and then In_Degree (N) = 0 then
                  Roots := Roots + 1;
                  Root := N;
               end if;
               if N <= Nodes and then In_Degree (N) > 1 then Valid := False; end if;
            end loop;
            if Roots /= 1 then Valid := False; end if;
            Reachable (Root) := True;
            for Step in Node loop
               for I in Edge_Index loop
                  if I <= Edge_Count and then I /= Candidate and then Reachable (Edges (I).U)
                    and then Edges (I).V <= Nodes
                  then
                     Reachable (Edges (I).V) := True;
                  end if;
               end loop;
            end loop;
            for N in Node loop
               if N <= Nodes and then not Reachable (N) then Valid := False; end if;
            end loop;
            if Valid and then Result = 0 then Result := Candidate; end if;
         end;
      end loop;
   end Find_Redundant;
end Redundant_Connection_II_Lite;
