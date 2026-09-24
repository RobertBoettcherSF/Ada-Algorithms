with Nth_Digit_Stub;
procedure Tests is
begin
   pragma Assert (Nth_Digit_Stub.Nth_Digit (0) = 1);
   pragma Assert (Nth_Digit_Stub.Nth_Digit (4) = 5);
   pragma Assert (Nth_Digit_Stub.Nth_Digit (9) = 0);
end Tests;
