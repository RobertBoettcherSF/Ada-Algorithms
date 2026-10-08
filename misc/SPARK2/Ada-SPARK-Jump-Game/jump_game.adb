pragma Ada_2022;
pragma SPARK_Mode (On);
package body Jump_Game is
   function Can_Jump (A : Steps; N : Index) return Boolean is
      Reach : Long_Long_Integer := 1;   --  furthest index reachable so far (may lie past N)
      Best  : Index := 1 with Ghost;    --  an index whose jump ends at Reach (when Reach > 1)
      function Ends (J : Index) return Long_Long_Integer is
        (Long_Long_Integer (J) + Long_Long_Integer (A (J)));
   begin
      for I in 1 .. N loop
         if Long_Long_Integer (I) > Reach then
            pragma Assert (for all J in 1 .. I - 1 => Ends (J) < Long_Long_Integer (I));
            pragma Assert (not Covered (A, I));
            return False;   --  no earlier index jumps as far as I
         end if;
         pragma Assert (I = 1 or else (Best < I and then Ends (Best) >= Long_Long_Integer (I)));
         pragma Assert (I = 1 or else Covered (A, I));
         pragma Assert (for all K in 2 .. I - 1 => Covered (A, K));
         if Ends (I) > Reach then
            Reach := Ends (I);
            Best := I;
         end if;
         pragma Loop_Invariant (Reach >= Long_Long_Integer (I) and Reach <= Long_Long_Integer (I) + Long_Long_Integer (Natural'Last));
         pragma Loop_Invariant (for all J in 1 .. I => Ends (J) <= Reach);
         pragma Loop_Invariant (Best <= I and then (Reach = 1 or else Ends (Best) = Reach));
         pragma Loop_Invariant (for all K in 2 .. I => Covered (A, K));
      end loop;
      return True;
   end Can_Jump;
end Jump_Game;
