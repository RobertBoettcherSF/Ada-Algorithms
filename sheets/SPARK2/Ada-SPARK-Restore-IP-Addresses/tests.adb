with Ada.Assertions; use Ada.Assertions;
with Restore_IP_Addresses; use Restore_IP_Addresses;
procedure Tests is
   D : constant Digit_Sequence := (1 => 1, 2 => 9, 3 => 2, 4 => 1, 5 => 6, 6 => 8,
      7 => 0, 8 => 1, 9 => 0, 10 => 0, 11 => 0, 12 => 0);
begin
   Assert (Valid_Segment (D, 1, 3));
   Assert (not Valid_Segment (D, 7, 2));
   Assert (Count_Valid_Segments (D) > 0);
end Tests;
