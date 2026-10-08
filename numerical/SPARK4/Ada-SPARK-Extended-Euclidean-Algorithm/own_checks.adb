pragma Ada_2022;
--  Own tests for Extended_Euclidean_Algorithm (see tests/SOURCES.txt).
--  Gcd / Extended_Gcd / Are_Coprime / Quotients_By_Gcd / Divides / Mod_Nonneg / Modular_Inverse against own
--  references: brute-force largest common divisor, the Bezout identity checked in wide integers, modular inverse
--  by search.
with Ada.Text_IO; use Ada.Text_IO;
with Extended_Euclidean_Algorithm; use Extended_Euclidean_Algorithm;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   Seed : Long_Long_Integer := 20261008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   function Own_Gcd (A, B : Educational) return Educational is
   begin
      if A = 0 then return B; end if;
      if B = 0 then return A; end if;
      for D in reverse 1 .. Integer'Min (A, B) loop
         if A mod D = 0 and then B mod D = 0 then return D; end if;
      end loop;
      return 1;
   end Own_Gcd;
   procedure Check (A, B : Educational) is
      G : constant Educational := Own_Gcd (A, B);
      R : constant Extended_Gcd_Result := Extended_Gcd (A, B);
      Q : constant Quotient_Pair := Quotients_By_Gcd (A, B);
   begin
      Report (Gcd (A, B) = G, "Gcd" & A'Image & B'Image);
      Report (R.Gcd = G and then abs R.X <= Coeff_Bound and then abs R.Y <= Coeff_Bound
              and then Long_Long_Integer (A) * Long_Long_Integer (R.X) + Long_Long_Integer (B) * Long_Long_Integer (R.Y) = Long_Long_Integer (G),
              "Extended_Gcd (Bezout)" & A'Image & B'Image);
      Report (Verify_Bezout (A, B, R), "Verify_Bezout" & A'Image & B'Image);
      Report (Are_Coprime (A, B) = (G = 1), "Are_Coprime" & A'Image & B'Image);
      Report ((if G = 0 then Q.A_Over_G = 0 and then Q.B_Over_G = 0 else Q.A_Over_G * G = A and then Q.B_Over_G * G = B),
              "Quotients_By_Gcd" & A'Image & B'Image);
      Report (Divides (A, B) = (A /= 0 and then B mod A = 0), "Divides" & A'Image & B'Image);
      if B > 0 then
         Report (Mod_Nonneg (A, B) = A mod B, "Mod_Nonneg" & A'Image & B'Image);
      end if;
      if B > 1 and then A < B and then G = 1 then
         declare
            Inv : constant Educational := Modular_Inverse (A, B);
            Own : Natural := 0;
         begin
            for X in 1 .. B - 1 loop
               if (A * X) mod B = 1 then Own := X; exit; end if;
            end loop;
            Report (Inv = Own and then Is_Modular_Inverse (A, Inv, B), "Modular_Inverse" & A'Image & B'Image);
         end;
      end if;
   end Check;
begin
   for A in 0 .. 60 loop
      for B in 0 .. 60 loop Check (A, B); end loop;
   end loop;
   for Run in 1 .. 4000 loop Check (Next (0, Max_Educational), Next (0, Max_Educational)); end loop;
   Check (Max_Educational, Max_Educational - 1); Check (0, Max_Educational); Check (Max_Educational, 0);
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
