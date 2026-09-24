package body Reed_Solomon is

   type GF_Table is array (Symbol) of Symbol;
   type Tables_Record is record
      Exp : GF_Table;
      Log : GF_Table;
   end record;

   -- Initialize Exp and Log tables at elaboration time
   function Init_Tables return Tables_Record is
      T : Tables_Record := (Exp => [others => 0], Log => [others => 0]);
      type Calc_Type is mod 512;
      V : Calc_Type := 1;
   begin
      for I in 0 .. 254 loop
         T.Exp (Symbol (I)) := Symbol (V);
         T.Log (Symbol (V)) := Symbol (I);
         V := V * 2;
         if V > 255 then
            V := V xor 285; -- Standard GF(2^8) irreducible polynomial
         end if;
      end loop;
      T.Exp (255) := T.Exp (0); -- Wrap around for edge cases
      return T;
   end Init_Tables;

   Tables : constant Tables_Record := Init_Tables;

   function "+" (Left, Right : Symbol) return Symbol is (Left xor Right);

   function "*" (Left, Right : Symbol) return Symbol is
   begin
      if Left = 0 or else Right = 0 then
         return 0;
      end if;
      return Tables.Exp (Symbol ((Integer (Tables.Log (Left)) + Integer (Tables.Log (Right))) mod 255));
   end "*";

   function "/" (Left, Right : Symbol) return Symbol is
   begin
      if Left = 0 then
         return 0;
      end if;
      return Tables.Exp (Symbol ((Integer (Tables.Log (Left)) - Integer (Tables.Log (Right)) + 255) mod 255));
   end "/";

   function Poly_Add (Left, Right : Polynomial) return Polynomial is
      Max_Len : constant Natural := Natural'Max (Left'Length, Right'Length);
      Result  : Polynomial (0 .. Max_Len - 1) := [others => 0];
   begin
      for I in Left'Range loop
         Result (I - Left'First) := Left (I);
      end loop;
      for I in Right'Range loop
         Result (I - Right'First) := Result (I - Right'First) + Right (I);
      end loop;
      return Result;
   end Poly_Add;

   function Poly_Mult (Left, Right : Polynomial) return Polynomial is
      Result : Polynomial (0 .. Left'Length + Right'Length - 2) := [others => 0];
   begin
      for I in Left'Range loop
         for J in Right'Range loop
            Result ((I - Left'First) + (J - Right'First)) :=
              Result ((I - Left'First) + (J - Right'First)) + (Left (I) * Right (J));
         end loop;
      end loop;
      return Result;
   end Poly_Mult;

   function Poly_Eval (Poly : Polynomial; X : Symbol) return Symbol is
      Y : Symbol := 0;
   begin
      -- Horner's Method adapted for polynomials mapped where index is the degree
      for I in reverse Poly'Range loop
         Y := Poly (I) + (Y * X);
      end loop;
      return Y;
   end Poly_Eval;

   function Encode_Original_View (Message : Polynomial; N : Positive) return Polynomial is
      Result : Polynomial (0 .. N - 1);
   begin
      for I in 0 .. N - 1 loop
         Result (I) := Poly_Eval (Message, Tables.Exp (Symbol (I mod 255)));
      end loop;
      return Result;
   end Encode_Original_View;

   function Generate_Polynomial (ECC_Count : Natural) return Polynomial is
      function Gen_Rec (Idx : Natural; Acc : Polynomial) return Polynomial is
      begin
         if Idx >= ECC_Count then
            return Acc;
         else
            declare
               Root : constant Symbol := Tables.Exp (Symbol (Idx mod 255));
               Term : constant Polynomial := [0 => Root, 1 => 1];
            begin
               return Gen_Rec (Idx + 1, Poly_Mult (Acc, Term));
            end;
         end if;
      end Gen_Rec;
   begin
      return Gen_Rec (0, [0 => 1]);
   end Generate_Polynomial;

   function Encode_BCH (Message : Polynomial; ECC_Count : Natural) return Polynomial is
      G : constant Polynomial := Generate_Polynomial (ECC_Count);
      Shifted : Polynomial (0 .. Message'Length + ECC_Count - 1) := [others => 0];
   begin
      -- Place message into higher powers
      for I in Message'Range loop
         Shifted ((I - Message'First) + ECC_Count) := Message (I);
      end loop;

      declare
         Rem_Poly : Polynomial := Shifted;
      begin
         -- Polynomial long division
         for I in reverse ECC_Count .. Shifted'Last loop
            if Rem_Poly (I) /= 0 then
               declare
                  Coef : constant Symbol := Rem_Poly (I);
               begin
                  for J in G'Range loop
                     Rem_Poly (I - ECC_Count + (J - G'First)) :=
                       Rem_Poly (I - ECC_Count + (J - G'First)) + (Coef * G (J));
                  end loop;
               end;
            end if;
         end loop;
         
         -- Form the systematic codeword: Message + Remainder Parity
         for I in 0 .. ECC_Count - 1 loop
            Shifted (I) := Rem_Poly (I);
         end loop;
      end;
      return Shifted;
   end Encode_BCH;

   function Calculate_Syndromes (Codeword : Polynomial; ECC_Count : Natural) return Polynomial is
      S : Polynomial (0 .. ECC_Count - 1);
   begin
      for I in 0 .. ECC_Count - 1 loop
         S (I) := Poly_Eval (Codeword, Tables.Exp (Symbol (I mod 255)));
      end loop;
      return S;
   end Calculate_Syndromes;

   function Decode_BCH (Codeword : Polynomial; ECC_Count : Natural) return Polynomial is
      Syndromes : constant Polynomial := Calculate_Syndromes (Codeword, ECC_Count);
      Has_Error : Boolean := False;
   begin
      for I in Syndromes'Range loop
         if Syndromes (I) /= 0 then
            Has_Error := True;
            exit;
         end if;
      end loop;

      if not Has_Error then
         declare
            Msg : Polynomial (0 .. Codeword'Length - ECC_Count - 1);
         begin
            for I in Msg'Range loop
               Msg (I) := Codeword (Codeword'First + ECC_Count + I);
            end loop;
            return Msg;
         end;
      end if;

      -- Berlekamp-Massey Algorithm to find Error Locator Polynomial (Lambda)
      declare
         C     : Polynomial (0 .. ECC_Count) := [0 => 1, others => 0];
         B     : Polynomial (0 .. ECC_Count) := [0 => 1, others => 0];
         L     : Natural := 0;
         M     : Natural := 1;
         B_Val : Symbol := 1;
         T     : Polynomial (0 .. ECC_Count);
      begin
         for I in 0 .. ECC_Count - 1 loop
            declare
               D : Symbol := Syndromes (Syndromes'First + I);
            begin
               for J in 1 .. L loop
                  D := D + (C (J) * Syndromes (Syndromes'First + I - J));
               end loop;

               if D = 0 then
                  M := M + 1;
               else
                  T := C;
                  declare
                     Coef : constant Symbol := D / B_Val;
                  begin
                     for J in 0 .. ECC_Count - M loop
                        C (J + M) := C (J + M) + (Coef * B (J));
                     end loop;
                  end;

                  if 2 * L <= I then
                     L := I + 1 - L;
                     B := T;
                     B_Val := D;
                     M := 1;
                  else
                     M := M + 1;
                  end if;
               end if;
            end;
         end loop;

         -- Isolate Lambda and proceed to Chien Search
         declare
            Lambda : constant Polynomial (0 .. L) := C (0 .. L);
            Error_Locs : array (1 .. L) of Natural;
            Err_Count  : Natural := 0;
         begin
            -- Chien Search to find the roots of Lambda
            for I in 0 .. Codeword'Length - 1 loop
               declare
                  -- Check \alpha^{-I}
                  X : constant Symbol := Tables.Exp (Symbol ((255 - (I mod 255)) mod 255));
                  Val : constant Symbol := Poly_Eval (Lambda, X);
               begin
                  if Val = 0 then
                     Err_Count := Err_Count + 1;
                     if Err_Count > L then
                        raise Decoding_Error with "Too many errors for capacity";
                     end if;
                     Error_Locs (Err_Count) := I;
                  end if;
               end;
            end loop;

            if Err_Count /= L then
               raise Decoding_Error with "Error locators do not match count";
            end if;

            -- Forney Algorithm to compute Error Magnitudes
            declare
               Omega_Full : constant Polynomial := Poly_Mult (Syndromes, Lambda);
               Omega      : Polynomial (0 .. ECC_Count - 1);
               Lambda_Deriv : Polynomial (0 .. L - 1) := [others => 0];
               Corrected  : Polynomial := Codeword;
            begin
               -- Omega is calculated modulo x^ECC_Count
               for I in Omega'Range loop
                  if I <= Omega_Full'Last then
                     Omega (I) := Omega_Full (Omega_Full'First + I);
                  else
                     Omega (I) := 0;
                  end if;
               end loop;

               -- Formal derivative of Lambda (drops odd powers in GF(2))
               for I in 1 .. L loop
                  if I mod 2 = 1 then
                     Lambda_Deriv (I - 1) := Lambda (I);
                  end if;
               end loop;

               -- Apply corrections
               for I in 1 .. Err_Count loop
                  declare
                     Pos : constant Natural := Error_Locs (I);
                     X_Inv  : constant Symbol := Tables.Exp (Symbol ((255 - (Pos mod 255)) mod 255));
                     X_Orig : constant Symbol := Tables.Exp (Symbol (Pos mod 255));
                     Num : constant Symbol := Poly_Eval (Omega, X_Inv) * X_Orig;
                     Den : constant Symbol := Poly_Eval (Lambda_Deriv, X_Inv);
                     Magnitude : constant Symbol := Num / Den;
                  begin
                     Corrected (Corrected'First + Pos) := Corrected (Corrected'First + Pos) + Magnitude;
                  end;
               end loop;

               -- Extract and return message payload
               declare
                  Msg : Polynomial (0 .. Corrected'Length - ECC_Count - 1);
               begin
                  for I in Msg'Range loop
                     Msg (I) := Corrected (Corrected'First + ECC_Count + I);
                  end loop;
                  return Msg;
               end;
            end;
         end;
      end;
   end Decode_BCH;

end Reed_Solomon;
