with Binary_Number_With_Alternating_Bits;
use Binary_Number_With_Alternating_Bits;
procedure Tests is
begin
   pragma Assert (Has_Alternating_Bits (85));
   pragma Assert (Has_Alternating_Bits (170));
   pragma Assert (not Has_Alternating_Bits (255));
end Tests;
