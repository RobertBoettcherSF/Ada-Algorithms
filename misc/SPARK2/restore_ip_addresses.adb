pragma Ada_2022;

package body Restore_IP_Addresses with SPARK_Mode => On is
   function Valid_Segment
     (D : Digit_Sequence; Start : Start_Index; Length : Segment_Length)
      return Boolean
   is
      Value : Natural := D (Start);
   begin
      if Length > 1 and then D (Start) = 0 then
         return False;
      end if;
      if Length >= 2 then
         Value := Value * 10 + D (Start + 1);
      end if;
      if Length = 3 then
         Value := Value * 10 + D (Start + 2);
      end if;
      return Value <= 255;
   end Valid_Segment;

   function Count_Valid_Segments (D : Digit_Sequence) return Natural is
      Result : Natural range 0 .. 9 := 0;
   begin
      for S in Start_Index range 1 .. 3 loop
         for L in Segment_Length loop
            if Valid_Segment (D, S, L) then
               Result := Result + 1;
            end if;
         end loop;
      end loop;
      return Result;
   end Count_Valid_Segments;
end Restore_IP_Addresses;
