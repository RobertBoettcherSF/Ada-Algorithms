pragma SPARK_Mode (On);

package body Longest_Increasing_Subsequence is
   function Add_One (Value : Result) return Result is
   begin
      if Value = Result'Last then
         return Result'Last;
      else
         return Value + 1;
      end if;
   end Add_One;

   function Compute (Values : Element_Array) return Result is
      Lengths : array (Index) of Result := (others => 1);
      Best : Result := 1;
   begin
      for I in Index loop
         pragma Loop_Invariant (Best in Result);
         for J in Index range Index'First .. I - 1 loop
            pragma Loop_Invariant (Lengths (I) in Result and Best in Result);
            if Values (J) < Values (I) and then Add_One (Lengths (J)) > Lengths (I) then
               Lengths (I) := Add_One (Lengths (J));
            end if;
         end loop;
         if Lengths (I) > Best then Best := Lengths (I); end if;
      end loop;
      return Best;
   end Compute;
end Longest_Increasing_Subsequence;
