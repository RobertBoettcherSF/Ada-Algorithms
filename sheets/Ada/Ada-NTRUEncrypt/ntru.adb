package body NTRU is

   -- Internal helper for scalar modulo ensuring positive results
   function Modulo_Coefficient (Val : Coefficient_Type; Mod_Val : Positive) return Coefficient_Type 
     with Global => null
   is
      M   : constant Integer := Integer (Mod_Val);
      V   : constant Integer := Integer (Val);
      Res : Integer;
   begin
      Res := V mod M;
      return Coefficient_Type (Res);
   end Modulo_Coefficient;

   -- Internal helper: Extended Euclidean Algorithm for scalar inversion
   function Scalar_Inverse (Value : Coefficient_Type; Mod_Val : Positive) return Coefficient_Type 
     with Global => null
   is
      T        : Integer := 0;
      New_T    : Integer := 1;
      R        : Integer := Mod_Val;
      New_R    : Integer := Integer (Modulo_Coefficient (Value, Mod_Val));
      Quotient : Integer := 0;
      Temp     : Integer := 0;
   begin
      while New_R /= 0 loop
         Quotient := R / New_R;
         
         Temp  := T - Quotient * New_T;
         T     := New_T;
         New_T := Temp;

         Temp  := R - Quotient * New_R;
         R     := New_R;
         New_R := Temp;
      end loop;
      
      if R > 1 then
         raise Not_Invertible;
      end if;
      
      if T < 0 then
         T := T + Mod_Val;
      end if;
      
      return Coefficient_Type (T);
   end Scalar_Inverse;

   -- ==========================================
   -- Polynomial Arithmetic Implementations
   -- ==========================================

   function "+" (A, B : Polynomial) return Polynomial is
      Result : Polynomial := [others => 0];
   begin
      for I in Degree_Type loop
         Result (I) := A (I) + B (I);
      end loop;
      return Result;
   end "+";

   function "-" (A, B : Polynomial) return Polynomial is
      Result : Polynomial := [others => 0];
   begin
      for I in Degree_Type loop
         Result (I) := A (I) - B (I);
      end loop;
      return Result;
   end "-";

   function "*" (Scalar : Coefficient_Type; Poly : Polynomial) return Polynomial is
      Result : Polynomial := [others => 0];
   begin
      for I in Degree_Type loop
         Result (I) := Scalar * Poly (I);
      end loop;
      return Result;
   end "*";

   function "*" (A, B : Polynomial) return Polynomial is
      Result : Polynomial := [others => 0];
   begin
      for I in Degree_Type loop
         for J in Degree_Type loop
            declare
               Idx : constant Integer := (Integer (I) + Integer (J)) mod N;
            begin
               Result (Degree_Type (Idx)) := Result (Degree_Type (Idx)) + A (I) * B (J);
            end;
         end loop;
      end loop;
      return Result;
   end "*";

   function Modulo_Poly (Poly : Polynomial; Mod_Val : Positive) return Polynomial is
      Result : Polynomial := [others => 0];
   begin
      for I in Degree_Type loop
         Result (I) := Modulo_Coefficient (Poly (I), Mod_Val);
      end loop;
      return Result;
   end Modulo_Poly;

   function Center (Poly : Polynomial; Mod_Val : Positive) return Polynomial is
      Result : Polynomial := [others => 0];
      Half   : constant Coefficient_Type := Coefficient_Type ((Mod_Val - 1) / 2);
      Mod_C  : constant Coefficient_Type := Coefficient_Type (Mod_Val);
   begin
      for I in Degree_Type loop
         Result (I) := Modulo_Coefficient (Poly (I), Mod_Val);
         if Result (I) > Half then
            Result (I) := Result (I) - Mod_C;
         end if;
      end loop;
      return Result;
   end Center;

   function Invert (Poly : Polynomial; Mod_Val : Positive) return Polynomial is
      type Matrix is array (Degree_Type, Degree_Type) of Coefficient_Type;
      M           : Matrix := [others => [others => 0]];
      I_Mat       : Matrix := [others => [others => 0]];
      Pivot_Row   : Degree_Type := 0;
      Pivot_Found : Boolean;
      Inv_Val     : Coefficient_Type := 0;
      Temp_Val    : Coefficient_Type := 0;
      Factor      : Coefficient_Type := 0;
      Result      : Polynomial := [others => 0];
   begin
      -- Construct the circulant matrix of the polynomial
      for Row in Degree_Type loop
         for Col in Degree_Type loop
            declare
               Diff : constant Integer := Integer (Row) - Integer (Col);
               Idx  : Degree_Type;
            begin
               if Diff < 0 then
                  Idx := Degree_Type (Diff + N);
               else
                  Idx := Degree_Type (Diff);
               end if;
               M (Row, Col) := Modulo_Coefficient (Poly (Idx), Mod_Val);
            end;
         end loop;
         I_Mat (Row, Row) := 1;
      end loop;

      -- Gaussian elimination over Z_Mod_Val
      for Col in Degree_Type loop
         Pivot_Found := False;
         Pivot_Row   := Col;
         
         for R in Col .. Degree_Type'Last loop
            begin
               Inv_Val := Scalar_Inverse (M (R, Col), Mod_Val);
               Pivot_Row := R;
               Pivot_Found := True;
               exit;
            exception
               when Not_Invertible => null;
            end;
         end loop;

         if not Pivot_Found then
            raise Not_Invertible;
         end if;

         -- Swap rows if necessary
         if Pivot_Row /= Col then
            for C in Degree_Type loop
               Temp_Val := M (Col, C);
               M (Col, C) := M (Pivot_Row, C);
               M (Pivot_Row, C) := Temp_Val;

               Temp_Val := I_Mat (Col, C);
               I_Mat (Col, C) := I_Mat (Pivot_Row, C);
               I_Mat (Pivot_Row, C) := Temp_Val;
            end loop;
         end if;

         -- Multiply row by inverse of the pivot
         for C in Degree_Type loop
            M (Col, C) := Modulo_Coefficient (M (Col, C) * Inv_Val, Mod_Val);
            I_Mat (Col, C) := Modulo_Coefficient (I_Mat (Col, C) * Inv_Val, Mod_Val);
         end loop;

         -- Eliminate other entries in the column
         for R in Degree_Type loop
            if R /= Col then
               Factor := M (R, Col);
               for C in Degree_Type loop
                  M (R, C) := Modulo_Coefficient (M (R, C) - Factor * M (Col, C), Mod_Val);
                  I_Mat (R, C) := Modulo_Coefficient (I_Mat (R, C) - Factor * I_Mat (Col, C), Mod_Val);
               end loop;
            end if;
         end loop;
      end loop;

      -- The first column of the inverted matrix corresponds to the inverse polynomial
      for Row in Degree_Type loop
         Result (Row) := I_Mat (Row, 0);
      end loop;

      return Result;
   end Invert;

   -- ==========================================
   -- Core NTRUEncrypt Implementations
   -- ==========================================

   procedure Generate_Key (F, G : in Polynomial;
                           Public_Key, Private_Key_F, Private_Key_Fp : out Polynomial) is
      F_Q : Polynomial;
   begin
      Private_Key_F := F;
      
      -- Calculate inverses in rings Rp and Rq
      Private_Key_Fp := Invert (F, P);
      F_Q            := Invert (F, Q);
      
      -- Public Key h = p * (f_q * g) mod q
      Public_Key := Modulo_Poly (Coefficient_Type (P) * (F_Q * G), Q);
   end Generate_Key;

   function Encrypt (Message, Random_Poly, Public_Key : Polynomial) return Polynomial is
   begin
      -- Ciphertext e = (r * h + m) mod q
      return Modulo_Poly (Random_Poly * Public_Key + Message, Q);
   end Encrypt;

   function Decrypt (Ciphertext, Private_Key_F, Private_Key_Fp : Polynomial) return Polynomial is
      A, B, C : Polynomial;
   begin
      -- Step 1: a = (f * e) mod q, then centered to [-q/2, q/2]
      A := Center (Modulo_Poly (Private_Key_F * Ciphertext, Q), Q);
      
      -- Step 2: b = a mod p
      B := Center (Modulo_Poly (A, P), P);
      
      -- Step 3: c = (f_p * b) mod p, then centered to [-p/2, p/2]
      C := Center (Modulo_Poly (Private_Key_Fp * B, P), P);
      
      return C;
   end Decrypt;

end NTRU;
