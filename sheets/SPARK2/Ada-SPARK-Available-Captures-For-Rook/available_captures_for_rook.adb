pragma Ada_2022;
package body Available_Captures_For_Rook with SPARK_Mode => On is
   function Count_Captures (Position : Index; Layout : Board) return Natural is
      Result : Natural := 0;
   begin
      for Column in Index loop
         if Layout (Position, Column) = Pawn then
            Result := Result + 1;
         end if;
      end loop;
      for Row in Index loop
         if Layout (Row, Position) = Pawn then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_Captures;
end Available_Captures_For_Rook;
