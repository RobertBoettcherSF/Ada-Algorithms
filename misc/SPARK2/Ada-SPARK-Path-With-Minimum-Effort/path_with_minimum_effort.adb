pragma Ada_2022;
package body Path_With_Minimum_Effort with SPARK_Mode => On is
   function Step_Effort (A, B : Height) return Effort is
      D : Integer;
   begin
      if A >= B then D := A - B; else D := B - A; end if;
      return Effort (D);
   end Step_Effort;

   procedure Compute (Heights : in Height_Array; Result : out Effort) is
      Running : Effort := 0;
      Edge : Effort;
   begin
      for C in Cell loop
         if C > Cell'First then
            pragma Assert (C > Cell'First);
            Edge := Step_Effort (Heights (C - 1), Heights (C));
            if Edge > Running then Running := Edge; end if;
         end if;
      end loop;
      Result := Running;
   end Compute;
end Path_With_Minimum_Effort;
