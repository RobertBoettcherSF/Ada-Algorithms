with Ada.Assertions; use Ada.Assertions;
with Logger_Rate_Limiter_Lite; use Logger_Rate_Limiter_Lite;
procedure Tests is L : Limiter := Create;
begin Allow (L); Allow (L); Assert (Used (L) = 2); Reset (L); Assert (Used (L) = 0); end Tests;
