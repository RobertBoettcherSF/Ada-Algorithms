pragma SPARK_Mode (On);

package body Delete_And_Earn_Stub is
   function Add_Bounded (Left : Result; Right : Value) return Result is
   begin
      if Left > Result'Last - Right then
         return Result'Last;
      else
         return Left + Right;
      end if;
   end Add_Bounded;

   function Add_Result (Left, Right : Result) return Result is
   begin
      if Left > Result'Last - Right then
         return Result'Last;
      else
         return Left + Right;
      end if;
   end Add_Result;

   function Compute (Values : Value_Array) return Result is
      Points : array (Value) of Result := (others => 0);
      Skip_Previous : Result := 0;
      Take_Previous : Result := 0;
      Best : Result;
   begin
      for I in Index loop
         pragma Loop_Invariant (Skip_Previous in Result and Take_Previous in Result);
         Points (Values (I)) := Add_Bounded (Points (Values (I)), Values (I));
      end loop;
      for V in Value loop
         pragma Loop_Invariant (Skip_Previous in Result and Take_Previous in Result);
         declare
            New_Skip : Result := Skip_Previous;
            New_Take : constant Result := Add_Result (Skip_Previous, Points (V));
         begin
            if Take_Previous > New_Skip then New_Skip := Take_Previous; end if;
            Skip_Previous := New_Skip;
            Take_Previous := New_Take;
         end;
      end loop;
      if Skip_Previous > Take_Previous then Best := Skip_Previous; else Best := Take_Previous; end if;
      return Best;
   end Compute;
end Delete_And_Earn_Stub;
