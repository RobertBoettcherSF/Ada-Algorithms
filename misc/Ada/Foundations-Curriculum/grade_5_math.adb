package body Grade_5_Math is

   -- Helper function: maps the enumerated place value to its numeric divisor.
   function Divisor_For_Place (Place : Place_Value) return Natural_Value is
   begin
      case Place is
         when Tens              => return 10;
         when Hundreds          => return 100;
         when Thousands         => return 1_000;
         when Ten_Thousands     => return 10_000;
         when Hundred_Thousands => return 100_000;
         when Millions          => return 1_000_000;
      end case;
   end Divisor_For_Place;

   -- Variant 1: Implements standard x.5 rounding rules for natural numbers
   function Round (Value : Natural_Value; To_Place : Place_Value) return Natural_Value is
      Divisor   : constant Natural_Value := Divisor_For_Place (To_Place);
      Remainder : constant Natural_Value := Value mod Divisor;
      Halfway   : constant Natural_Value := Divisor / 2;
   begin
      if Remainder >= Halfway then
         -- Edge case: Check if rounding up causes standard integer overflow
         if Natural_Value'Last - Value < (Divisor - Remainder) then
            raise Rounding_Error with "Rounding up causes numeric overflow";
         end if;
         return Value + (Divisor - Remainder);
      else
         return Value - Remainder;
      end if;
   end Round;

   -- Variant 2
   function Rectangle_Perimeter (Length, Width : Safe_Dimension) return Length_Unit is
   begin
      return 2 * Length + 2 * Width;
   end Rectangle_Perimeter;

   -- Variant 3
   function Rectangle_Area (Length, Width : Safe_Dimension) return Area_Unit is
   begin
      return Area_Unit (Length) * Area_Unit (Width);
   end Rectangle_Area;

   -- Variant 4
   function Cuboid_Surface_Area (Length, Width, Height : Safe_Dimension) return Area_Unit is
      L : constant Area_Unit := Area_Unit (Length);
      W : constant Area_Unit := Area_Unit (Width);
      H : constant Area_Unit := Area_Unit (Height);
   begin
      return 2 * (L * W + W * H + H * L);
   end Cuboid_Surface_Area;

   -- Variant 5
   function Cuboid_Volume (Length, Width, Height : Safe_Dimension) return Volume_Unit is
   begin
      return Volume_Unit (Length) * Volume_Unit (Width) * Volume_Unit (Height);
   end Cuboid_Volume;

   -- Variant 6: Strict mathematical validation variant
   function Strict_Cuboid_Volume (Length, Width, Height : Safe_Dimension) return Volume_Unit is
   begin
      if Length = 0 or else Width = 0 or else Height = 0 then
         raise Dimension_Error with "Strict volume requires dimensions strictly > 0";
      end if;
      return Cuboid_Volume (Length, Width, Height);
   end Strict_Cuboid_Volume;

   -- Variant 7
   procedure Convert_Seconds
     (Total_Seconds : in  Natural_Value;
      Days          : out Natural_Value;
      Hours         : out Natural_Value;
      Minutes       : out Natural_Value;
      Seconds       : out Natural_Value)
   is
      Remaining : Natural_Value := Total_Seconds;
   begin
      Days      := Remaining / 86_400;
      Remaining := Remaining mod 86_400;

      Hours     := Remaining / 3_600;
      Remaining := Remaining mod 3_600;

      Minutes   := Remaining / 60;
      Seconds   := Remaining mod 60;
   end Convert_Seconds;

end Grade_5_Math;
