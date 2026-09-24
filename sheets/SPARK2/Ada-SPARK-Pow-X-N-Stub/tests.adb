with Pow_X_N_Stub;
procedure Tests is
begin
   pragma Assert (Pow_X_N_Stub.Power (2, 0) = 1);
   pragma Assert (Pow_X_N_Stub.Power (2, 5) = 32);
   pragma Assert (Pow_X_N_Stub.Power (4, 5) = 1024);
end Tests;
