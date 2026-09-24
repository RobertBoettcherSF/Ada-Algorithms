pragma SPARK_Mode (On);

package body House_Robber_III_Stub is
   function Add_Bounded (Left : Result; Right : Amount) return Result is
   begin
      if Left > Result'Last - Right then
         return Result'Last;
      else
         return Left + Right;
      end if;
   end Add_Bounded;

   function Compute (Values : Amount_Array) return Result is
      Skip_Previous : Result := 0;
      Take_Previous : Result := 0;
   begin
      for I in Index loop
         pragma Loop_Invariant
           (Skip_Previous in Result and Take_Previous in Result);
         declare
            New_Skip : Result := Skip_Previous;
            New_Take : constant Result := Add_Bounded (Skip_Previous, Values (I));
         begin
            if Take_Previous > New_Skip then New_Skip := Take_Previous; end if;
            Skip_Previous := New_Skip;
            Take_Previous := New_Take;
         end;
      end loop;
      if Skip_Previous > Take_Previous then
         return Skip_Previous;
      else
         return Take_Previous;
      end if;
   end Compute;
end House_Robber_III_Stub;
