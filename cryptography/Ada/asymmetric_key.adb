package body Asymmetric_Key is

   function Is_Prime (Value : Prime_Value) return Boolean is
   begin
      if Value <= 3 then
         return True;
      end if;
      if Value mod 2 = 0 or else Value mod 3 = 0 then
         return False;
      end if;
      
      declare
         I : Prime_Value := 5;
      begin
         while I * I <= Value loop
            if Value mod I = 0 or else Value mod (I + 2) = 0 then
               return False;
            end if;
            I := I + 6;
         end loop;
      end;
      return True;
   end Is_Prime;

   function Gcd (A, B : Key_Component) return Key_Component is
      type Extended_Component is range 0 .. 2147483647;
      Curr_A : Extended_Component := Extended_Component (A);
      Curr_B : Extended_Component := Extended_Component (B);
      Temp   : Extended_Component;
   begin
      pragma Warnings (Off, "-gnatwc");
      while Curr_B /= 0 loop
         Temp := Curr_B;
         Curr_B := Curr_A mod Curr_B;
         Curr_A := Temp;
      end loop;
      pragma Warnings (On, "-gnatwc");
      return Key_Component (Curr_A);
   end Gcd;

   function Mod_Pow (Base, Exp, Modulus : Key_Component) return Key_Component is
      Res : Long_Long_Integer := 1;
      B   : Long_Long_Integer := Long_Long_Integer (Base mod Modulus);
      E   : Long_Long_Integer := Long_Long_Integer (Exp);
      M   : constant Long_Long_Integer := Long_Long_Integer (Modulus);
   begin
      while E > 0 loop
         if E mod 2 = 1 then
            Res := (Res * B) mod M;
         end if;
         B := (B * B) mod M;
         E := E / 2;
      end loop;
      return Key_Component (Res);
   end Mod_Pow;

   type Extended_Gcd_Result is record
      Gcd, X, Y : Long_Long_Integer;
   end record;

   function Extended_Gcd (A, B : Long_Long_Integer) return Extended_Gcd_Result is
      Old_R : Long_Long_Integer := A;
      R     : Long_Long_Integer := B;
      Old_S : Long_Long_Integer := 1;
      S     : Long_Long_Integer := 0;
      Old_T : Long_Long_Integer := 0;
      T     : Long_Long_Integer := 1;
      Quot  : Long_Long_Integer;
      Temp  : Long_Long_Integer;
   begin
      while R /= 0 loop
         Quot := Old_R / R;
         
         Temp := R;
         R := Old_R - Quot * R;
         Old_R := Temp;

         Temp := S;
         S := Old_S - Quot * S;
         Old_S := Temp;

         Temp := T;
         T := Old_T - Quot * T;
         Old_T := Temp;
      end loop;
      return (Gcd => Old_R, X => Old_S, Y => Old_T);
   end Extended_Gcd;

   function Mod_Inverse (E, Phi : Key_Component) return Key_Component is
      Res : constant Extended_Gcd_Result := Extended_Gcd (Long_Long_Integer (E), Long_Long_Integer (Phi));
      Result : Long_Long_Integer;
   begin
      if Res.Gcd /= 1 then
         raise Invalid_Key_Error with "Modular inverse does not exist";
      end if;
      Result := Res.X mod Long_Long_Integer (Phi);
      if Result < 0 then
         Result := Result + Long_Long_Integer (Phi);
      end if;
      return Key_Component (Result);
   end Mod_Inverse;

   procedure Generate_Keys
     (P     : in     Prime_Value;
      Q     : in     Prime_Value;
      Pub   :    out Public_Key;
      Priv  :    out Private_Key)
   is
      N_Val   : constant Key_Component := Key_Component (P) * Key_Component (Q);
      Phi_Val : constant Key_Component := Key_Component (P - 1) * Key_Component (Q - 1);
      E_Val   : Key_Component := 65537;
   begin
      if P = Q then
         raise Invalid_Prime_Error with "Primes P and Q must be distinct";
      end if;

      if not Is_Prime (P) or else not Is_Prime (Q) then
         raise Invalid_Prime_Error with "Both P and Q must be prime numbers";
      end if;

      if Phi_Val <= E_Val then
         E_Val := 3;
         while E_Val < Phi_Val loop
            if Gcd (E_Val, Phi_Val) = 1 then
               exit;
            end if;
            E_Val := E_Val + 2;
         end loop;
      elsif Gcd (E_Val, Phi_Val) /= 1 then
         E_Val := 3;
         while E_Val < Phi_Val loop
            if Gcd (E_Val, Phi_Val) = 1 then
               exit;
            end if;
            E_Val := E_Val + 2;
         end loop;
      end if;

      if Gcd (E_Val, Phi_Val) /= 1 then
         raise Invalid_Key_Error with "Could not find a valid public exponent E";
      end if;

      declare
         D_Val : constant Key_Component := Mod_Inverse (E_Val, Phi_Val);
      begin
         Pub := (N => N_Val, E => E_Val);
         Priv := (N => N_Val, D => D_Val);
      end;
   end Generate_Keys;

   function Encrypt
     (M   : Message_Type;
      Pub : Public_Key) return Message_Type
   is
      M_Rem : constant Long_Long_Integer := Long_Long_Integer (M) mod Long_Long_Integer (Pub.N);
   begin
      if M_Rem = 0 then
         return 0;
      end if;
      return Message_Type (Mod_Pow (Key_Component (M_Rem), Pub.E, Pub.N));
   end Encrypt;

   function Decrypt
     (C    : Message_Type;
      Priv : Private_Key) return Message_Type
   is
      C_Rem : constant Long_Long_Integer := Long_Long_Integer (C) mod Long_Long_Integer (Priv.N);
   begin
      if C_Rem = 0 then
         return 0;
      end if;
      return Message_Type (Mod_Pow (Key_Component (C_Rem), Priv.D, Priv.N));
   end Decrypt;

   function Sign
     (M    : Message_Type;
      Priv : Private_Key) return Message_Type
   is
      M_Rem : constant Long_Long_Integer := Long_Long_Integer (M) mod Long_Long_Integer (Priv.N);
   begin
      if M_Rem = 0 then
         return 0;
      end if;
      return Message_Type (Mod_Pow (Key_Component (M_Rem), Priv.D, Priv.N));
   end Sign;

   function Verify
     (M   : Message_Type;
      S   : Message_Type;
      Pub : Public_Key) return Boolean
   is
      S_Rem : constant Long_Long_Integer := Long_Long_Integer (S) mod Long_Long_Integer (Pub.N);
      M_Rem : constant Long_Long_Integer := Long_Long_Integer (M) mod Long_Long_Integer (Pub.N);
      Decrypted_Signature : Message_Type;
   begin
      if S_Rem = 0 then
         Decrypted_Signature := 0;
      else
         Decrypted_Signature := Message_Type (Mod_Pow (Key_Component (S_Rem), Pub.E, Pub.N));
      end if;
      return Decrypted_Signature = Message_Type (M_Rem);
   end Verify;

end Asymmetric_Key;
