pragma SPARK_Mode (On);

package body Evaluate_Division_Stub is
   function Evaluate (Equations : Equation_Array; From, To : Variable) return Fraction is
      Unknown : constant Fraction := (Numerator => 0, Denominator => 1);
      Result  : Fraction := Unknown;
      Done    : Boolean := False;
   begin
      if From = To then
         return (Numerator => 1, Denominator => 1);
      end if;
      for I in Equations'Range loop
         if not Done and then Equations (I).From = From
           and then Equations (I).To = To
         then
            Result := (Numerator => Equations (I).Numerator,
                       Denominator => Equations (I).Denominator);
            Done := True;
         elsif not Done and then Equations (I).From = To
           and then Equations (I).To = From
         then
            Result := (Numerator => Equations (I).Denominator,
                       Denominator => Equations (I).Numerator);
            Done := True;
         end if;
      end loop;
      if not Done then
         for I in Equations'Range loop
            for J in Equations'Range loop
               if Equations (I).From = From
                 and then Equations (I).To = Equations (J).From
                 and then Equations (J).To = To
               then
                  Result :=
                    (Numerator => Equations (I).Numerator * Equations (J).Numerator,
                     Denominator => Equations (I).Denominator * Equations (J).Denominator);
               end if;
            end loop;
         end loop;
      end if;
      return Result;
   end Evaluate;
end Evaluate_Division_Stub;
