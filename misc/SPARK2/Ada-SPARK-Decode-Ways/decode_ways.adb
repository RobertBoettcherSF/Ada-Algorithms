pragma SPARK_Mode (On);

package body Decode_Ways is
   function Count (Data : Digit_Sequence; Length : Input) return Result is
      Previous : Result := (if Data (1) /= 0 then 1 else 0);   --  decodings of Data (1 .. I - 1)
      Before   : Result := 1;                                   --  decodings of Data (1 .. I - 2)
      Current  : Result;
   begin
      for I in 2 .. Length loop
         pragma Loop_Invariant (Previous = Ways (Data, I - 1) and then Before = Ways (Data, I - 2));
         Current := (if Data (I) /= 0 then Previous else 0)
                    + (if Pair_Valid (Data (I - 1), Data (I)) then Before else 0);
         pragma Assert (Current = Ways (Data, I));
         Before := Previous;
         Previous := Current;
      end loop;
      return Previous;
   end Count;
end Decode_Ways;
