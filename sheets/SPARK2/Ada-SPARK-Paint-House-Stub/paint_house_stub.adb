pragma SPARK_Mode (On);

package body Paint_House_Stub is
   function Add_Bounded (Left : Result; Right : Cost) return Result is
   begin
      if Left > Result'Last - Right then
         return Result'Last;
      else
         return Left + Right;
      end if;
   end Add_Bounded;

   function Compute (Costs : Cost_Matrix) return Result is
      type Vector is array (Color) of Result;
      Previous : Vector := (others => 0);
      Current : Vector := (others => 0);
      Answer : Result := 0;
   begin
      for H in House loop
         pragma Loop_Invariant
           (Answer in Result and then
            (for all C in Color => Previous (C) in Result));
         for C in Color loop
            Current (C) := Result'Last;
            for Other in Color loop
               pragma Loop_Invariant (Current (C) in Result);
               if Other /= C then
                  if Add_Bounded (Previous (Other), Costs (H, C)) < Current (C) then
                     Current (C) := Add_Bounded (Previous (Other), Costs (H, C));
                  end if;
               end if;
            end loop;
         end loop;
         Previous := Current;
      end loop;
      Answer := Previous (Color'First);
      for C in Color range Color'First + 1 .. Color'Last loop
         pragma Loop_Invariant (Answer in Result);
         if Previous (C) < Answer then Answer := Previous (C); end if;
      end loop;
      return Answer;
   end Compute;
end Paint_House_Stub;
