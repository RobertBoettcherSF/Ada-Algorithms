--  Own checks (see tests/SOURCES.txt). Assume RSA is wrong or does nothing;
--  compare with references that use a different method:
--  * Modular_Exponentiation: repeated multiplication, every base 0 .. 24,
--    exponent 0 .. 24, modulus 1 .. 24 (and 10**30-sized operands against
--    Fermat's little theorem for the prime 2**61 - 1);
--  * GCD / LCM / Modular_Inverse: search over candidates; Extended_GCD:
--    the Bezout identity as a certificate;
--  * keys: Carmichael lambda by search (smallest k with a**k = 1 mod n for
--    every unit a), e * d = 1 mod lambda, and round trips for every message
--    (encrypt / decrypt, sign / verify, blinded decryption for every r).
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Big_Numbers.Big_Integers; use Ada.Numerics.Big_Numbers.Big_Integers;
with RSA; use RSA;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Expect (Cond : Boolean; What : String) is
   begin
      Checked := Checked + 1;
      if not Cond then
         Failures := Failures + 1;
         if Failures <= 25 then
            Put_Line ("  FAIL own: " & What);
         end if;
      end if;
   end Expect;

   function B (V : Integer) return RSA_Integer renames To_RSA;

   function Ref_Pow_Mod (Base, Exp, M : Natural) return Natural is
      R : Natural := 1 mod M;
   begin
      for K in 1 .. Exp loop
         R := (R * Base) mod M;
      end loop;
      return R;
   end Ref_Pow_Mod;

   function Ref_GCD (A, C : Natural) return Natural is
   begin
      if A = 0 then return C; elsif C = 0 then return A; end if;
      for D in reverse 1 .. Natural'Min (A, C) loop
         if A mod D = 0 and then C mod D = 0 then return D; end if;
      end loop;
      return 1;
   end Ref_GCD;

   function Is_Prime (P : Natural) return Boolean is
   begin
      if P < 2 then return False; end if;
      for D in 2 .. P - 1 loop
         if P mod D = 0 then return False; end if;
      end loop;
      return True;
   end Is_Prime;

   function Ref_Lambda (N : Positive) return Positive is
   begin
      for K in 1 .. N loop
         declare
            Ok : Boolean := True;
         begin
            for A in 1 .. N - 1 loop
               if Ref_GCD (A, N) = 1 and then Ref_Pow_Mod (A, K, N) /= 1 then
                  Ok := False; exit;
               end if;
            end loop;
            if Ok then return K; end if;
         end;
      end loop;
      return N;
   end Ref_Lambda;
begin
   for M in 1 .. 24 loop
      for Base in 0 .. 24 loop
         for E in 0 .. 24 loop
            Expect (Modular_Exponentiation (B (Base), B (E), B (M)) = B (Ref_Pow_Mod (Base, E, M)),
                    "Modular_Exponentiation" & Base'Image & E'Image & M'Image);
         end loop;
      end loop;
   end loop;
   declare
      P61 : constant RSA_Integer := To_RSA ("2305843009213693951");   --  2**61 - 1, prime
      A   : constant RSA_Integer := To_RSA ("123456789012345678901234567890");
   begin
      Expect (Modular_Exponentiation (A, P61 - One, P61) = One, "Fermat for 2**61 - 1");
      Expect (Modular_Exponentiation (A, P61, P61) = A mod P61, "a**p = a mod p for 2**61 - 1");
   end;
   for A in 0 .. 40 loop
      for C in 0 .. 40 loop
         Expect (GCD (B (A), B (C)) = B (Ref_GCD (A, C)), "GCD" & A'Image & C'Image);
         declare
            X, Y : RSA_Integer;
            G    : constant RSA_Integer := Extended_GCD (B (A), B (C), X, Y);
         begin
            Expect (G = B (Ref_GCD (A, C)) and then B (A) * X + B (C) * Y = G,
                    "Extended_GCD Bezout" & A'Image & C'Image);
         end;
         if A > 0 and then C > 0 then
            declare
               L : Natural := 0;
            begin
               for K in 1 .. A * C loop
                  if K mod A = 0 and then K mod C = 0 then L := K; exit; end if;
               end loop;
               Expect (LCM (B (A), B (C)) = B (L), "LCM" & A'Image & C'Image);
            end;
         end if;
         if A > 0 and then C > 1 then
            declare
               Inv : Integer := -1;
            begin
               for K in 0 .. C - 1 loop
                  if (A * K) mod C = 1 then Inv := K; exit; end if;
               end loop;
               declare
                  Got : constant RSA_Integer := Modular_Inverse (B (A), B (C));
               begin
                  Expect (Inv >= 0 and then Got = B (Inv), "Modular_Inverse" & A'Image & C'Image);
               end;
            exception
               when Math_Error => Expect (Inv < 0, "Modular_Inverse raised" & A'Image & C'Image);
            end;
         end if;
      end loop;
   end loop;
   for P in 2 .. 29 loop
      for Q in 2 .. 29 loop
         if P /= Q and then Is_Prime (P) and then Is_Prime (Q) then
            declare
               N   : constant Positive := P * Q;
               Lam : constant Positive := Ref_Lambda (N);
            begin
               for E in 2 .. 12 loop
                  begin
                     declare
                        K : constant Key_Pair := Generate_Key_Pair (B (P), B (Q), B (E));
                     begin
                        Expect (Ref_GCD (E, Lam) = 1, "key accepted although gcd (e, lambda) /= 1");
                        Expect (K.Pub.N = B (N) and then K.Priv.N = B (N) and then K.Pub.E = B (E)
                                and then (B (E) * K.Priv.D) mod B (Lam) = One
                                and then K.Priv.D > Zero and then K.Priv.D < B (Lam),
                                "key p=" & P'Image & " q=" & Q'Image & " e=" & E'Image);
                        for Msg in 0 .. N - 1 loop
                           declare
                              C : constant RSA_Integer := Encrypt (B (Msg), K.Pub);
                              S : constant RSA_Integer := Sign (B (Msg), K.Priv);
                           begin
                              Expect (C = B (Ref_Pow_Mod (Msg, E, N)) and then Decrypt (C, K.Priv) = B (Msg)
                                      and then Verify (S, B (Msg), K.Pub)
                                      and then not Verify (S, B ((Msg + 1) mod N), K.Pub),
                                      "round trip n=" & N'Image & " e=" & E'Image & " m=" & Msg'Image);
                              if N <= 35 then
                                 for R in 1 .. N - 1 loop
                                    if Ref_GCD (R, N) = 1 then
                                       Expect (Decrypt_Blinded (C, K.Priv, B (E), B (R)) = B (Msg),
                                               "blinded n=" & N'Image & " r=" & R'Image);
                                    end if;
                                 end loop;
                              end if;
                           end;
                        end loop;
                     end;
                  exception
                     when Invalid_Key_Error | Math_Error =>
                        Expect (Ref_GCD (E, Lam) /= 1, "key rejected although gcd (e, lambda) = 1, p="
                                & P'Image & " q=" & Q'Image & " e=" & E'Image);
                  end;
               end loop;
            end;
         end if;
      end loop;
   end loop;
   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Checked'Image & " (repeated multiplication, searches, Bezout, Carmichael lambda, round trips)");
end Own_Checks;
