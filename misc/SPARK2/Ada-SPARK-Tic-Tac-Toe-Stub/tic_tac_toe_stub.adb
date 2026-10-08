pragma SPARK_Mode (On);

package body Tic_Tac_Toe_Stub is
   function Line_Winner (A, B, C : Player) return Player is
   begin
      if A /= Empty and then A = B and then B = C then
         return A;
      end if;
      return Empty;
   end Line_Winner;

   function Winner (B : Board) return Player is
      Result : Player;
   begin
      for I in Coordinate loop
         Result := Line_Winner (B (I, 1), B (I, 2), B (I, 3));
         if Result /= Empty then
            return Result;
         end if;
         Result := Line_Winner (B (1, I), B (2, I), B (3, I));
         if Result /= Empty then
            return Result;
         end if;
      end loop;
      Result := Line_Winner (B (1, 1), B (2, 2), B (3, 3));
      if Result /= Empty then
         return Result;
      end if;
      return Line_Winner (B (1, 3), B (2, 2), B (3, 1));
   end Winner;
end Tic_Tac_Toe_Stub;
