pragma Ada_2022;
with Bitwise_Or_Of_Numbers_Range;
with Interfaces;
procedure Tests is
   use type Interfaces.Unsigned_32;
   package O renames Bitwise_Or_Of_Numbers_Range;
begin
   pragma Assert (O.Or_0_To (0) = 0);
   pragma Assert (O.Or_0_To (1) = 1);
   pragma Assert (O.Or_0_To (5) = 7);
   pragma Assert (O.Or_0_To (16#100#) = 16#1FF#);
end Tests;
