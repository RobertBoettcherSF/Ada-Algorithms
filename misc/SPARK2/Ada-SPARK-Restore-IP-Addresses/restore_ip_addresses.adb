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

   --  The choices C = 0 .. 26 (spec) in lexicographic order; the fourth
   --  length is what is left.
   function Code (L1, L2, L3 : Segment_Length) return Choice is
     (9 * (L1 - 1) + 3 * (L2 - 1) + (L3 - 1));

   function Position (List : Address_List; Count : Address_Count; L1, L2, L3, L4 : Segment_Length)
     return Address_Count is
   begin
      for K in 1 .. Count loop
         pragma Loop_Invariant (for all J in 1 .. K - 1 => not Has_Lengths (List (J), L1, L2, L3, L4));
         if Has_Lengths (List (K), L1, L2, L3, L4) then
            return K;
         end if;
      end loop;
      return 0;
   end Position;

   procedure Restore
     (D : Digit_String; Len : String_Length; List : out Address_List; Count : out Address_Count)
   is
      L1, L2, L3 : Segment_Length;
      L4 : Integer;
      --  Where (C): index in List of the address of choice C (proof only).
      type Where_Table is array (Choice) of Address_Count;
      Where : Where_Table := [others => 0] with Ghost;

      function Fits (C : Choice) return Boolean is
        (Splits (D, Len, First_Of (C), Second_Of (C), Third_Of (C)));
   begin
      pragma Assert
        (for all M1 in Segment_Length => (for all M2 in Segment_Length => (for all M3 in Segment_Length =>
           First_Of (Code (M1, M2, M3)) = M1 and then Second_Of (Code (M1, M2, M3)) = M2
           and then Third_Of (Code (M1, M2, M3)) = M3)));
      List  := [others => [others => 1]];
      Count := 0;
      for C in Choice loop
         pragma Loop_Invariant (Count <= C);
         pragma Loop_Invariant (for all K in 1 .. Count => Valid (D, Len, List (K)));
         pragma Loop_Invariant
           (for all K in 1 .. Count => Code (List (K) (1), List (K) (2), List (K) (3)) < C);
         pragma Loop_Invariant
           (for all K in 1 .. Count - 1 =>
              Code (List (K) (1), List (K) (2), List (K) (3))
              < Code (List (K + 1) (1), List (K + 1) (2), List (K + 1) (3)));
         pragma Loop_Invariant
           (for all E in 0 .. C - 1 =>
              (if Fits (E) then Where (E) in 1 .. Count
                 and then List (Where (E)) = [First_Of (E), Second_Of (E), Third_Of (E),
                                              Len - First_Of (E) - Second_Of (E) - Third_Of (E)]));
         L1 := First_Of (C);
         L2 := Second_Of (C);
         L3 := Third_Of (C);
         pragma Assert (Code (L1, L2, L3) = C);
         L4 := Len - L1 - L2 - L3;
         if L4 in Segment_Length and then Valid (D, Len, L1, L2, L3, L4) then
            Count := Count + 1;
            List (Count) := [L1, L2, L3, L4];
            Where (C) := Count;
         end if;
      end loop;
      pragma Assert
        (for all K in 1 .. Count - 1 => Less (List (K), List (K + 1)));
      pragma Assert
        (for all M1 in Segment_Length => (for all M2 in Segment_Length => (for all M3 in Segment_Length =>
           (if Fits (Code (M1, M2, M3)) then
              Where (Code (M1, M2, M3)) in 1 .. Count
              and then List (Where (Code (M1, M2, M3))) = [M1, M2, M3, Len - M1 - M2 - M3]))));
      --  Name the witness: Position finds every valid address.
      for C in Choice loop
         pragma Loop_Invariant
           (for all E in 0 .. C - 1 =>
              (if Fits (E) then
                 Position (List, Count, First_Of (E), Second_Of (E), Third_Of (E),
                           Len - First_Of (E) - Second_Of (E) - Third_Of (E)) /= 0));
         if Fits (C) then
            pragma Assert (Where (C) in 1 .. Count
                           and then Has_Lengths (List (Where (C)), First_Of (C), Second_Of (C), Third_Of (C),
                                                 Len - First_Of (C) - Second_Of (C) - Third_Of (C)));
         end if;
      end loop;
   end Restore;
end Restore_IP_Addresses;
