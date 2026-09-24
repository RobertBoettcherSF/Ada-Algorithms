pragma Ada_2022;
with Horner_Scheme;
procedure Tests is
   C : constant Horner_Scheme.Coefficients := (1 => 1, 2 => 2, 3 => 3, 4 => 4);
begin
   pragma Assert (Horner_Scheme.Evaluate (C, 2) = 26);
   pragma Assert (Horner_Scheme.Evaluate (C, 0) = 4);
end Tests;
