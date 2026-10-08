package Grade_5_Math is
   pragma Pure;

   -- We base our computations on a 64-bit integer to handle large unit 
   -- conversions and geometry calculations without silent overflow, 
   -- adhering to strong typing principles.
   type Math_Value is new Long_Long_Integer;
   subtype Natural_Value is Math_Value range 0 .. Math_Value'Last;

   -- Domain-specific types for physical quantities (strong typing)
   type Length_Unit is new Natural_Value;
   type Area_Unit   is new Natural_Value;
   type Volume_Unit is new Natural_Value;

   -- Subtype for dimensions, guaranteeing that typical 5th-grade 
   -- rectangular calculations will never exceed the underlying 64-bit bounds.
   subtype Safe_Dimension is Length_Unit range 0 .. 1_000_000;

   -- Place values required by the Bavarian grade 5 curriculum for rounding.
   type Place_Value is 
     (Tens, Hundreds, Thousands, Ten_Thousands, Hundred_Thousands, Millions);

   -- Named exceptions for specific edge cases
   Dimension_Error : exception;
   Rounding_Error  : exception;

   -- Variant 1: Number Rounding
   -- Rounds a natural number to the specified decimal place value.
   function Round (Value : Natural_Value; To_Place : Place_Value) return Natural_Value
     with Global => null;

   -- Variant 2: Rectangle Geometry (Perimeter)
   function Rectangle_Perimeter (Length, Width : Safe_Dimension) return Length_Unit
     with Global => null,
          Post   => Rectangle_Perimeter'Result = 2 * Length + 2 * Width;

   -- Variant 3: Rectangle Geometry (Area)
   function Rectangle_Area (Length, Width : Safe_Dimension) return Area_Unit
     with Global => null;

   -- Variant 4: Cuboid Geometry (Surface Area)
   function Cuboid_Surface_Area (Length, Width, Height : Safe_Dimension) return Area_Unit
     with Global => null;

   -- Variant 5: Cuboid Geometry (Volume)
   function Cuboid_Volume (Length, Width, Height : Safe_Dimension) return Volume_Unit
     with Global => null;

   -- Variant 6: Strict Cuboid Volume 
   -- Dynamic variant enforcing strictly positive dimensions; raises exception on 0.
   function Strict_Cuboid_Volume (Length, Width, Height : Safe_Dimension) return Volume_Unit
     with Global => null;

   -- Variant 7: Time Unit Conversion
   -- Converts a total number of seconds into decomposed days, hours, minutes, and seconds.
   procedure Convert_Seconds
     (Total_Seconds : in  Natural_Value;
      Days          : out Natural_Value;
      Hours         : out Natural_Value;
      Minutes       : out Natural_Value;
      Seconds       : out Natural_Value)
     with Global => null,
          Post   => Total_Seconds = Seconds + 60 * Minutes + 3600 * Hours + 86400 * Days;

end Grade_5_Math;
