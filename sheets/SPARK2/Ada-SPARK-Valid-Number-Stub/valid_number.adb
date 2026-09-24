pragma SPARK_Mode (On);

package body Valid_Number is
   function Is_Valid (Input : Text) return Boolean is
      Seen_Digit          : Boolean := False;
      Seen_Dot            : Boolean := False;
      Seen_Exponent       : Boolean := False;
      Exponent_Digit      : Boolean := False;
      Finished             : Boolean := False;
   begin
      for I in Index loop
         pragma Loop_Invariant (Seen_Digit or else not Seen_Digit);
         pragma Loop_Invariant (Seen_Dot or else not Seen_Dot);
         if Input (I) = ' ' then
            Finished := True;
         elsif Finished then
            return False;
         elsif Input (I) in '0' .. '9' then
            Seen_Digit := True;
            if Seen_Exponent then
               Exponent_Digit := True;
            end if;
         elsif (Input (I) = '+' or else Input (I) = '-')
           and then (I = Index'First
                     or else Input (Index'Pred (I)) = 'e'
                     or else Input (Index'Pred (I)) = 'E')
         then
            null;
         elsif Input (I) = '.' and then not Seen_Dot and then not Seen_Exponent then
            Seen_Dot := True;
         elsif (Input (I) = 'e' or else Input (I) = 'E')
           and then Seen_Digit and then not Seen_Exponent
         then
            Seen_Exponent := True;
         else
            return False;
         end if;
      end loop;
      return Seen_Digit and then (not Seen_Exponent or else Exponent_Digit);
   end Is_Valid;
end Valid_Number;
