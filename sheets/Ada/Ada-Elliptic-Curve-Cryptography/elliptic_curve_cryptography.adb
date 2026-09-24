pragma Ada_2022;

package body Elliptic_Curve_Cryptography is

   --  Internal helper: Modular Addition
   function Mod_Add (A, B, P : Field_Element) return Field_Element is
   begin
      return (A + B) mod P;
   end Mod_Add;

   --  Internal helper: Modular Subtraction
   function Mod_Sub (A, B, P : Field_Element) return Field_Element is
   begin
      if A >= B then
         return (A - B) mod P;
      else
         return (P - ((B - A) mod P)) mod P;
      end if;
   end Mod_Sub;

   --  Internal helper: Modular Multiplication
   function Mod_Mul (A, B, P : Field_Element) return Field_Element is
      Tmp : constant Long_Long_Integer :=
        (Long_Long_Integer (A) * Long_Long_Integer (B)) mod Long_Long_Integer (P);
   begin
      return Field_Element (Tmp);
   end Mod_Mul;

   --  Computes the modular inverse using the Extended Euclidean Algorithm
   function Modular_Inverse (A, M : Field_Element) return Field_Element is
      T, New_T : Long_Long_Integer;
      R, New_R : Long_Long_Integer;
      Quotient : Long_Long_Integer;
      Aux      : Long_Long_Integer;
   begin
      T := 0;
      New_T := 1;
      R := Long_Long_Integer (M);
      New_R := Long_Long_Integer (A mod M);

      while New_R /= 0 loop
         Quotient := R / New_R;

         Aux := T - Quotient * New_T;
         T := New_T;
         New_T := Aux;

         Aux := R - Quotient * New_R;
         R := New_R;
         New_R := Aux;
      end loop;

      if R > 1 then
         raise Not_Invertible_Error;
      end if;

      if T < 0 then
         T := T + Long_Long_Integer (M);
      end if;

      return Field_Element (T);
   end Modular_Inverse;

   --  Validates the curve using the condition: 4a^3 + 27b^2 != 0 (mod p)
   function Is_Valid_Curve (Curve : Curve_Parameters) return Boolean is
      A3 : constant Field_Element := Mod_Mul (Curve.A, Mod_Mul (Curve.A, Curve.A, Curve.P), Curve.P);
      B2 : constant Field_Element := Mod_Mul (Curve.B, Curve.B, Curve.P);
      Term1 : constant Field_Element := Mod_Mul (4, A3, Curve.P);
      Term2 : constant Field_Element := Mod_Mul (27, B2, Curve.P);
      Discriminant : constant Field_Element := Mod_Add (Term1, Term2, Curve.P);
   begin
      return Discriminant /= 0;
   end Is_Valid_Curve;

   --  Checks whether the given point satisfies the Weierstrass curve equation
   function Is_On_Curve (Curve : Curve_Parameters; Pt : Point) return Boolean is
   begin
      case Pt.Kind is
         when Infinity =>
            return True;
         when Affine =>
            if Pt.X >= Curve.P or else Pt.Y >= Curve.P then
               return False;
            end if;

            declare
               Y2 : constant Field_Element := Mod_Mul (Pt.Y, Pt.Y, Curve.P);
               X2 : constant Field_Element := Mod_Mul (Pt.X, Pt.X, Curve.P);
               X3 : constant Field_Element := Mod_Mul (X2, Pt.X, Curve.P);
               AX : constant Field_Element := Mod_Mul (Curve.A, Pt.X, Curve.P);
               RHS : constant Field_Element := Mod_Add (Mod_Add (X3, AX, Curve.P), Curve.B, Curve.P);
            begin
               return Y2 = RHS;
            end;
      end case;
   end Is_On_Curve;

   --  Doubles a point geometrically (draws a tangent line at the point)
   function Point_Double (Curve : Curve_Parameters; Pt : Point) return Point is
   begin
      if Pt.Kind = Infinity then
         return Pt;
      end if;

      if Pt.Y = 0 then
         return (Kind => Infinity);
      end if;

      declare
         --  Lambda = (3x^2 + a) * (2y)^-1 mod p
         X2       : constant Field_Element := Mod_Mul (Pt.X, Pt.X, Curve.P);
         Three_X2 : constant Field_Element := Mod_Mul (3, X2, Curve.P);
         Num      : constant Field_Element := Mod_Add (Three_X2, Curve.A, Curve.P);
         Den      : constant Field_Element := Mod_Mul (2, Pt.Y, Curve.P);
         Inv_Den  : constant Field_Element := Modular_Inverse (Den, Curve.P);
         Lambda   : constant Field_Element := Mod_Mul (Num, Inv_Den, Curve.P);

         --  x3 = Lambda^2 - 2x mod p
         Lambda2 : constant Field_Element := Mod_Mul (Lambda, Lambda, Curve.P);
         Two_X   : constant Field_Element := Mod_Mul (2, Pt.X, Curve.P);
         X3      : constant Field_Element := Mod_Sub (Lambda2, Two_X, Curve.P);

         --  y3 = Lambda(x - x3) - y mod p
         X_Diff     : constant Field_Element := Mod_Sub (Pt.X, X3, Curve.P);
         Lam_X_Diff : constant Field_Element := Mod_Mul (Lambda, X_Diff, Curve.P);
         Y3         : constant Field_Element := Mod_Sub (Lam_X_Diff, Pt.Y, Curve.P);
      begin
         return (Kind => Affine, X => X3, Y => Y3);
      end;
   end Point_Double;

   --  Adds two points on the elliptic curve
   function Point_Add (Curve : Curve_Parameters; P1, P2 : Point) return Point is
   begin
      --  Identity element handling
      if P1.Kind = Infinity then
         return P2;
      end if;
      if P2.Kind = Infinity then
         return P1;
      end if;

      --  Vertical line or same point handling
      if P1.X = P2.X then
         if P1.Y = P2.Y then
            return Point_Double (Curve, P1);
         else
            --  The points are inverses of each other
            return (Kind => Infinity);
         end if;
      end if;

      declare
         --  Lambda = (y2 - y1) * (x2 - x1)^-1 mod p
         Num     : constant Field_Element := Mod_Sub (P2.Y, P1.Y, Curve.P);
         Den     : constant Field_Element := Mod_Sub (P2.X, P1.X, Curve.P);
         Inv_Den : constant Field_Element := Modular_Inverse (Den, Curve.P);
         Lambda  : constant Field_Element := Mod_Mul (Num, Inv_Den, Curve.P);

         --  x3 = Lambda^2 - x1 - x2 mod p
         Lambda2 : constant Field_Element := Mod_Mul (Lambda, Lambda, Curve.P);
         Sub1    : constant Field_Element := Mod_Sub (Lambda2, P1.X, Curve.P);
         X3      : constant Field_Element := Mod_Sub (Sub1, P2.X, Curve.P);

         --  y3 = Lambda(x1 - x3) - y1 mod p
         X_Diff     : constant Field_Element := Mod_Sub (P1.X, X3, Curve.P);
         Lam_X_Diff : constant Field_Element := Mod_Mul (Lambda, X_Diff, Curve.P);
         Y3         : constant Field_Element := Mod_Sub (Lam_X_Diff, P1.Y, Curve.P);
      begin
         return (Kind => Affine, X => X3, Y => Y3);
      end;
   end Point_Add;

   --  Performs scalar multiplication using Double-and-Add (analogous to square-and-multiply)
   function Scalar_Multiply (Curve : Curve_Parameters; K : Field_Element; Pt : Point) return Point is
      Result    : Point := (Kind => Infinity);
      Addend    : Point := Pt;
      Current_K : Field_Element := K;
   begin
      if Pt.Kind = Infinity or else K = 0 then
         return Result;
      end if;

      while Current_K > 0 loop
         if Current_K mod 2 = 1 then
            Result := Point_Add (Curve, Result, Addend);
         end if;
         Addend := Point_Double (Curve, Addend);
         Current_K := Current_K / 2;
      end loop;

      return Result;
   end Scalar_Multiply;

end Elliptic_Curve_Cryptography;
