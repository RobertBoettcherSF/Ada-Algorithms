with Ada.Numerics.Big_Numbers.Big_Integers;
use Ada.Numerics.Big_Numbers.Big_Integers;

package Elliptic_Curve_Diffie_Hellman is
   pragma Preelaborate;

   -- Domain types for the elliptic curve over a prime field Fp
   type Curve_Point is record
      X           : Big_Integer;
      Y           : Big_Integer;
      Is_Infinity : Boolean := True;
   end record;

   type Domain_Parameters is record
      P : Big_Integer; -- Prime modulus
      A : Big_Integer; -- Curve coefficient a
      B : Big_Integer; -- Curve coefficient b
      G : Curve_Point; -- Generator / Base point
      N : Big_Integer; -- Order of the base point G
   end record;

   -- Named exceptions for robust error handling
   Invalid_Domain_Parameters : exception;
   Invalid_Point             : exception;
   Invalid_Private_Key       : exception;

   -- Pure computational and validation functions
   function Is_On_Curve (P : Curve_Point; Domain : Domain_Parameters) return Boolean
     with Global => null;

   function Is_Valid_Domain (Domain : Domain_Parameters) return Boolean
     with Global => null;

   function Point_Double (P : Curve_Point; Domain : Domain_Parameters) return Curve_Point
     with Pre    => Is_Valid_Domain (Domain) and then Is_On_Curve (P, Domain),
          Post   => Is_On_Curve (Point_Double'Result, Domain),
          Global => null;

   function Point_Add (P, Q : Curve_Point; Domain : Domain_Parameters) return Curve_Point
     with Pre    => Is_Valid_Domain (Domain) and then 
                    Is_On_Curve (P, Domain) and then Is_On_Curve (Q, Domain),
          Post   => Is_On_Curve (Point_Add'Result, Domain),
          Global => null;

   function Scalar_Multiply (K : Big_Integer; P : Curve_Point; Domain : Domain_Parameters) return Curve_Point
     with Pre    => Is_Valid_Domain (Domain) and then 
                    Is_On_Curve (P, Domain) and then K >= To_Big_Integer (0),
          Post   => Is_On_Curve (Scalar_Multiply'Result, Domain),
          Global => null;

   -- Key pair generation
   function Generate_Key_Pair (Domain : Domain_Parameters; Private_Key : Big_Integer) return Curve_Point
     with Pre    => Is_Valid_Domain (Domain) and then
                    Private_Key > To_Big_Integer (0) and then Private_Key < Domain.N,
          Post   => Is_On_Curve (Generate_Key_Pair'Result, Domain),
          Global => null;

   -- Variant 1: Static Elliptic-Curve Diffie-Hellman (ECDH)
   -- Both parties use long-term, static keys.
   procedure Static_ECDH
     (Domain        : Domain_Parameters;
      My_Private    : Big_Integer;
      Other_Public  : Curve_Point;
      Shared_Secret : out Curve_Point)
     with Pre    => Is_Valid_Domain (Domain) and then
                    Is_On_Curve (Other_Public, Domain) and then
                    My_Private > To_Big_Integer (0) and then My_Private < Domain.N,
          Post   => Is_On_Curve (Shared_Secret, Domain),
          Global => null;

   -- Variant 2: Ephemeral Elliptic-Curve Diffie-Hellman (ECDHE)
   -- Keys are randomly generated for each session, providing perfect forward secrecy.
   procedure Ephemeral_ECDHE
     (Domain          : Domain_Parameters;
      My_Ephemeral    : Big_Integer;
      Other_Ephemeral : Curve_Point;
      Shared_Secret   : out Curve_Point)
     with Pre    => Is_Valid_Domain (Domain) and then
                    Is_On_Curve (Other_Ephemeral, Domain) and then
                    My_Ephemeral > To_Big_Integer (0) and then My_Ephemeral < Domain.N,
          Post   => Is_On_Curve (Shared_Secret, Domain),
          Global => null;

   -- Variant 3: Anonymous Elliptic-Curve Diffie-Hellman
   -- One party uses a static key (usually a server), the other uses an ephemeral key.
   procedure Anonymous_ECDH
     (Domain        : Domain_Parameters;
      My_Key        : Big_Integer;
      Other_Key     : Curve_Point;
      Shared_Secret : out Curve_Point)
     with Pre    => Is_Valid_Domain (Domain) and then
                    Is_On_Curve (Other_Key, Domain) and then
                    My_Key > To_Big_Integer (0) and then My_Key < Domain.N,
          Post   => Is_On_Curve (Shared_Secret, Domain),
          Global => null;

end Elliptic_Curve_Diffie_Hellman;
