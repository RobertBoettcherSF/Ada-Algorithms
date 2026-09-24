pragma Ada_2022;
with Xor_Of_Numbers_Range;
with Interfaces;
procedure Tests is
   use type Interfaces.Unsigned_32;
   package X renames Xor_Of_Numbers_Range;
begin
   pragma Assert (X.Xor_0_To (0) = 0);
   pragma Assert (X.Xor_0_To (5) = 1);
   pragma Assert (X.Xor_0_To (10) = 11);
end Tests;
