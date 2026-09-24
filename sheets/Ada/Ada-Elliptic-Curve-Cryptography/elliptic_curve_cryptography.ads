pragma Ada_2022;

package Elliptic_Curve_Cryptography is

   --  Field_Element represents an integer in the finite field.
   --  Bounded to prevent overflow during intermediate Long_Long_Integer calculations.
   type Field_Element is new Long_Long_Integer range 0 .. 2**31 - 1;

   --  Curve parameters for Weierstrass form: y^2 = x^3 + Ax + B (mod P)
   type Curve_Parameters is record
      P, A, B : Field_Element;
   end record;

   type Point_Kind is (Infinity, Affine);

   --  A Point on the elliptic curve, either the Point at Infinity or an affine (X, Y) coordinate
   type Point (Kind : Point_Kind := Infinity) is record
      case Kind is
         when Infinity => null;
         when Affine =>
            X, Y : Field_Element;
      end case;
   end record;

   --  Exceptions for invalid operations
   Invalid_Curve_Error      : exception;
   Point_Not_On_Curve_Error : exception;
   Not_Invertible_Error     : exception;

   --  Validates that the curve parameters form a valid elliptic curve (discriminant /= 0)
   function Is_Valid_Curve (Curve : Curve_Parameters) return Boolean
     with Global => null;

   --  Checks if a given point satisfies the curve equation
   function Is_On_Curve (Curve : Curve_Parameters; Pt : Point) return Boolean
     with Global => null;

   --  Adds two points on the elliptic curve
   function Point_Add (Curve : Curve_Parameters; P1, P2 : Point) return Point
     with Pre => Is_Valid_Curve (Curve) and then
                 Is_On_Curve (Curve, P1) and then
                 Is_On_Curve (Curve, P2),
          Post => Is_On_Curve (Curve, Point_Add'Result),
          Global => null;

   --  Doubles a point on the elliptic curve
   function Point_Double (Curve : Curve_Parameters; Pt : Point) return Point
     with Pre => Is_Valid_Curve (Curve) and then
                 Is_On_Curve (Curve, Pt),
          Post => Is_On_Curve (Curve, Point_Double'Result),
          Global => null;

   --  Performs scalar multiplication (K * Pt) using the Double-and-Add algorithm
   function Scalar_Multiply (Curve : Curve_Parameters; K : Field_Element; Pt : Point) return Point
     with Pre => Is_Valid_Curve (Curve) and then
                 Is_On_Curve (Curve, Pt),
          Post => Is_On_Curve (Curve, Scalar_Multiply'Result),
          Global => null;

   --  Helper: Computes the modular inverse of A mod M using Extended Euclidean Algorithm
   function Modular_Inverse (A, M : Field_Element) return Field_Element
     with Pre => M > 1,
          Global => null;

end Elliptic_Curve_Cryptography;
