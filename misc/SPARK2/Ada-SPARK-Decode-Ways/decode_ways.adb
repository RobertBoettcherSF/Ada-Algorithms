pragma SPARK_Mode (On);

package body Decode_Ways is
   function Add_Bounded (Left, Right : Result) return Result is
   begin
      if Left > Result'Last - Right then
         return Result'Last;
      else
         return Left + Right;
      end if;
   end Add_Bounded;

   function Pair_Valid (Left, Right : Digit) return Boolean is
   begin
      return Left = 1 or else (Left = 2 and then Right <= 6);
   end Pair_Valid;

   function Count (Data : Digit_Sequence; Length : Input) return Result is
      Previous : Result;
      Before   : Result := 1;
      Current  : Result;
   begin
      if Data (1) = 0 then
         return 0;
      end if;
      Previous := 1;
      for I in 2 .. Length loop
         pragma Loop_Invariant (Previous in Result and Before in Result);
         if Data (I) = 0 then
            if Pair_Valid (Data (I - 1), Data (I)) then
               Current := Before;
            else
               Current := 0;
            end if;
         elsif Pair_Valid (Data (I - 1), Data (I)) then
            Current := Add_Bounded (Previous, Before);
         else
            Current := Previous;
         end if;
         Before := Previous;
         Previous := Current;
      end loop;
      return Previous;
   end Count;
end Decode_Ways;
