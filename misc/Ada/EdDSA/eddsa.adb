package body Eddsa is

   --  Provides mathematically robust modulo exponentiation.
   function Mod_Exp (Base, Exp, Modulus : Big_Integer) return Big_Integer is
      Result : Big_Integer := To_Big_Integer (1);
      B      : Big_Integer := Base mod Modulus;
      E      : Big_Integer := Exp;
      Zero   : constant Big_Integer := To_Big_Integer (0);
      Two    : constant Big_Integer := To_Big_Integer (2);
   begin
      while E > Zero loop
         if E mod Two = To_Big_Integer (1) then
            Result := (Result * B) mod Modulus;
         end if;
         B := (B * B) mod Modulus;
         E := E / Two;
      end loop;
      return Result;
   end Mod_Exp;

   --  Computes modular inverse using Fermat's Little Theorem (requires prime Modulus).
   function Mod_Inverse (Val, Modulus : Big_Integer) return Big_Integer is
   begin
      if Val mod Modulus = To_Big_Integer (0) then
         raise Division_By_Zero;
      end if;
      return Mod_Exp (Val, Modulus - To_Big_Integer (2), Modulus);
   end Mod_Inverse;

   --  Constructs the exact parameters for the Ed25519 Curve variant of EdDSA.
   function Get_Ed25519_Curve return Curve_Parameters is
      P : constant Big_Integer := To_Big_Integer (2) ** 255 - To_Big_Integer (19);
      A : constant Big_Integer := P - To_Big_Integer (1); -- Equivalant to -1 mod P
      
      --  D = -121665 / 121666 mod P
      D_Num : constant Big_Integer := P - To_Big_Integer (121665);
      D_Den : constant Big_Integer := To_Big_Integer (121666);
      D : constant Big_Integer := (D_Num * Mod_Inverse (D_Den, P)) mod P;
      
      --  L = 2^252 + 27742317777372353535851937790883648493
      L_Offset : constant Big_Integer := From_String ("27742317777372353535851937790883648493");
      L : constant Big_Integer := (To_Big_Integer (2) ** 252) + L_Offset;
      
      --  B_y = 4/5 mod P
      By_Num : constant Big_Integer := To_Big_Integer (4);
      By_Den : constant Big_Integer := To_Big_Integer (5);
      By : constant Big_Integer := (By_Num * Mod_Inverse (By_Den, P)) mod P;
      
      --  Known generator B_x for Ed25519
      Bx : constant Big_Integer := From_String ("15112221349535400772501151409588531511454012693041857206046113283949847762202");
      C : constant Big_Integer := To_Big_Integer (8);
   begin
      return (P => P, A => A, D => D, L => L, B => (X => Bx, Y => By), C => C);
   end Get_Ed25519_Curve;

   function Is_On_Curve (Curve : Curve_Parameters; Pt : Point) return Boolean is
      X2, Y2, LHS, RHS : Big_Integer;
   begin
      if Pt.X < To_Big_Integer (0) or else Pt.X >= Curve.P then
         return False;
      end if;
      if Pt.Y < To_Big_Integer (0) or else Pt.Y >= Curve.P then
         return False;
      end if;
      
      X2 := Mod_Exp (Pt.X, To_Big_Integer (2), Curve.P);
      Y2 := Mod_Exp (Pt.Y, To_Big_Integer (2), Curve.P);
      
      LHS := (Curve.A * X2 + Y2) mod Curve.P;
      RHS := (To_Big_Integer (1) + ((Curve.D * X2) mod Curve.P) * Y2) mod Curve.P;
      return LHS = RHS;
   end Is_On_Curve;

   function Point_Add (Curve : Curve_Parameters; P1, P2 : Point) return Point is
      X1Y2 : constant Big_Integer := (P1.X * P2.Y) mod Curve.P;
      Y1X2 : constant Big_Integer := (P1.Y * P2.X) mod Curve.P;
      Y1Y2 : constant Big_Integer := (P1.Y * P2.Y) mod Curve.P;
      X1X2 : constant Big_Integer := (P1.X * P2.X) mod Curve.P;
      
      Num_X : constant Big_Integer := (X1Y2 + Y1X2) mod Curve.P;
      Num_Y : constant Big_Integer := (Y1Y2 - (Curve.A * X1X2) mod Curve.P) mod Curve.P;
      
      Denom_Term : constant Big_Integer := (Curve.D * ((X1X2 * Y1Y2) mod Curve.P)) mod Curve.P;
      Denom_X : constant Big_Integer := (To_Big_Integer (1) + Denom_Term) mod Curve.P;
      Denom_Y : constant Big_Integer := (To_Big_Integer (1) - Denom_Term) mod Curve.P;
      
      Inv_X : Big_Integer;
      Inv_Y : Big_Integer;
   begin
      if Denom_X = To_Big_Integer (0) or else Denom_Y = To_Big_Integer (0) then
         raise Division_By_Zero;
      end if;
      
      Inv_X := Mod_Inverse (Denom_X, Curve.P);
      Inv_Y := Mod_Inverse (Denom_Y, Curve.P);
      
      return (X => (Num_X * Inv_X) mod Curve.P, 
              Y => (Num_Y * Inv_Y) mod Curve.P);
   end Point_Add;

   function Point_Multiply (Curve : Curve_Parameters; Scalar : Big_Integer; Pt : Point) return Point is
      Result  : Point := (X => To_Big_Integer (0), Y => To_Big_Integer (1)); -- Neutral element
      Current : Point := Pt;
      E       : Big_Integer := Scalar;
      Zero    : constant Big_Integer := To_Big_Integer (0);
      Two     : constant Big_Integer := To_Big_Integer (2);
   begin
      while E > Zero loop
         if E mod Two = To_Big_Integer (1) then
            Result := Point_Add (Curve, Result, Current);
         end if;
         Current := Point_Add (Curve, Current, Current);
         E := E / Two;
      end loop;
      return Result;
   end Point_Multiply;

   --  A simulated cryptographic hash mapped to modular constraints for independence from external libs.
   function Pseudo_Hash (Data : String; Modulus : Big_Integer) return Big_Integer is
      Result : Big_Integer := To_Big_Integer (5381);
      Mult   : constant Big_Integer := To_Big_Integer (33);
   begin
      for I in Data'Range loop
         Result := (Result * Mult + To_Big_Integer (Character'Pos (Data (I)))) mod Modulus;
      end loop;
      return Result;
   end Pseudo_Hash;

   function Point_To_String (Pt : Point) return String is
   begin
      return To_String (Pt.X) & "," & To_String (Pt.Y);
   end Point_To_String;

   function Generate_Public_Key (Curve : Curve_Parameters; Secret_Key : String) return Point is
      A_Scalar : Big_Integer := (Curve.C * Pseudo_Hash (Secret_Key & "_scalar", Curve.L)) mod Curve.L;
   begin
      if A_Scalar = To_Big_Integer (0) then
         A_Scalar := Curve.C;
      end if;
      return Point_Multiply (Curve, A_Scalar, Curve.B);
   end Generate_Public_Key;

   function Sign_Pure (Curve : Curve_Parameters; Message : String; Secret_Key : String) return Signature is
      A_Scalar : Big_Integer := (Curve.C * Pseudo_Hash (Secret_Key & "_scalar", Curve.L)) mod Curve.L;
      A_Point  : Point;
      Prefix   : constant String := Secret_Key & "_prefix";
      R_Scalar : Big_Integer;
      R_Point  : Point;
      H_RAM    : Big_Integer;
      S_Scalar : Big_Integer;
   begin
      if A_Scalar = To_Big_Integer (0) then A_Scalar := Curve.C; end if;
      A_Point := Point_Multiply (Curve, A_Scalar, Curve.B);
      
      R_Scalar := Pseudo_Hash (Prefix & Message, Curve.L);
      R_Point  := Point_Multiply (Curve, R_Scalar, Curve.B);
      
      H_RAM    := Pseudo_Hash (Point_To_String (R_Point) & Point_To_String (A_Point) & Message, Curve.L);
      S_Scalar := (R_Scalar + ((H_RAM * A_Scalar) mod Curve.L)) mod Curve.L;
      
      return (R => R_Point, S => S_Scalar);
   end Sign_Pure;

   function Verify_Pure (Curve : Curve_Parameters; Message : String; Pub_Key : Point; Sig : Signature) return Boolean is
      H_RAM        : constant Big_Integer := Pseudo_Hash (Point_To_String (Sig.R) & Point_To_String (Pub_Key) & Message, Curve.L);
      LHS_Scalar   : constant Big_Integer := (Curve.C * Sig.S) mod Curve.L;
      LHS          : constant Point := Point_Multiply (Curve, LHS_Scalar, Curve.B);
      
      RHS_1        : constant Point := Point_Multiply (Curve, Curve.C, Sig.R);
      RHS_2_Scalar : constant Big_Integer := (Curve.C * H_RAM) mod Curve.L;
      RHS_2        : constant Point := Point_Multiply (Curve, RHS_2_Scalar, Pub_Key);
      RHS          : constant Point := Point_Add (Curve, RHS_1, RHS_2);
   begin
      return LHS.X = RHS.X and then LHS.Y = RHS.Y;
   end Verify_Pure;

   function Sign_Hash (Curve : Curve_Parameters; Message : String; Secret_Key : String) return Signature is
      Ph_M : constant String := To_String (Pseudo_Hash (Message, Curve.P));
   begin
      return Sign_Pure (Curve, "HashEdDSA" & Ph_M, Secret_Key);
   end Sign_Hash;

   function Verify_Hash (Curve : Curve_Parameters; Message : String; Pub_Key : Point; Sig : Signature) return Boolean is
      Ph_M : constant String := To_String (Pseudo_Hash (Message, Curve.P));
   begin
      return Verify_Pure (Curve, "HashEdDSA" & Ph_M, Pub_Key, Sig);
   end Verify_Hash;

   function Sign_Context (Curve : Curve_Parameters; Message : String; Context : String; Secret_Key : String) return Signature is
   begin
      return Sign_Pure (Curve, "Ctx" & Context & Message, Secret_Key);
   end Sign_Context;

   function Verify_Context (Curve : Curve_Parameters; Message : String; Context : String; Pub_Key : Point; Sig : Signature) return Boolean is
   begin
      return Verify_Pure (Curve, "Ctx" & Context & Message, Pub_Key, Sig);
   end Verify_Context;

end Eddsa;
