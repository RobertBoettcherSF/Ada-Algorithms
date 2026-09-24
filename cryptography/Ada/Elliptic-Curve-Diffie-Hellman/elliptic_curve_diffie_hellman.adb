package body Elliptic_Curve_Diffie_Hellman is

   -- Internal Helpers

   -- Modular exponentiation for Big_Integer: computes (Base^Exp) mod Modulus.
   function Modular_Exponentiation (Base, Exp, Modulus : Big_Integer) return Big_Integer is
      Result : Big_Integer := To_Big_Integer (1);
      B      : Big_Integer := Base mod Modulus;
      E      : Big_Integer := Exp;
      Zero   : constant Big_Integer := To_Big_Integer (0);
      Two    : constant Big_Integer := To_Big_Integer (2);
   begin
      while E > Zero loop
         if (E mod Two) /= Zero then
            Result := (Result * B) mod Modulus;
         end if;
         E := E / Two;
         B := (B * B) mod Modulus;
      end loop;
      return Result;
   end Modular_Exponentiation;

   -- Computes the modular inverse using Fermat's Little Theorem (Modulus must be prime)
   function Modular_Inverse (A, Modulus : Big_Integer) return Big_Integer is
      Two : constant Big_Integer := To_Big_Integer (2);
   begin
      return Modular_Exponentiation (A, Modulus - Two, Modulus);
   end Modular_Inverse;

   -- Core Key Agreement routine sharing common implementation logic for all variants
   procedure Perform_Key_Agreement
     (Domain        : Domain_Parameters;
      My_Private    : Big_Integer;
      Other_Public  : Curve_Point;
      Shared_Secret : out Curve_Point)
   is
      Zero : constant Big_Integer := To_Big_Integer (0);
   begin
      if not Is_Valid_Domain (Domain) then
         raise Invalid_Domain_Parameters;
      end if;
      if My_Private <= Zero or else My_Private >= Domain.N then
         raise Invalid_Private_Key;
      end if;
      if not Is_On_Curve (Other_Public, Domain) or else Other_Public.Is_Infinity then
         raise Invalid_Point;
      end if;

      Shared_Secret := Scalar_Multiply (My_Private, Other_Public, Domain);
   end Perform_Key_Agreement;

   -- Public Subprogram Implementations

   function Is_On_Curve (P : Curve_Point; Domain : Domain_Parameters) return Boolean is
   begin
      if P.Is_Infinity then
         return True;
      end if;

      declare
         Y2    : constant Big_Integer := (P.Y * P.Y) mod Domain.P;
         X3    : constant Big_Integer := (P.X * P.X * P.X) mod Domain.P;
         Right : constant Big_Integer := (X3 + (Domain.A * P.X) + Domain.B) mod Domain.P;
      begin
         return Y2 = Right;
      end;
   end Is_On_Curve;

   function Is_Valid_Domain (Domain : Domain_Parameters) return Boolean is
      Zero         : constant Big_Integer := To_Big_Integer (0);
      Two          : constant Big_Integer := To_Big_Integer (2);
      Four         : constant Big_Integer := To_Big_Integer (4);
      Twenty_Seven : constant Big_Integer := To_Big_Integer (27);
   begin
      if Domain.P <= Two then
         return False;
      end if;
      
      -- Verify non-singular curve (discriminant 4a^3 + 27b^2 != 0)
      declare
         Disc_A : constant Big_Integer := (Four * Domain.A * Domain.A * Domain.A) mod Domain.P;
         Disc_B : constant Big_Integer := (Twenty_Seven * Domain.B * Domain.B) mod Domain.P;
         Discriminant : constant Big_Integer := (Disc_A + Disc_B) mod Domain.P;
      begin
         if Discriminant = Zero then
            return False;
         end if;
      end;
      
      -- Validate base point
      if not Is_On_Curve (Domain.G, Domain) or else Domain.G.Is_Infinity then
         return False;
      end if;
      if Domain.N <= Zero then
         return False;
      end if;
      return True;
   end Is_Valid_Domain;

   function Point_Double (P : Curve_Point; Domain : Domain_Parameters) return Curve_Point is
      Zero  : constant Big_Integer := To_Big_Integer (0);
      Two   : constant Big_Integer := To_Big_Integer (2);
      Three : constant Big_Integer := To_Big_Integer (3);
   begin
      if P.Is_Infinity or else P.Y = Zero then
         return (X => Zero, Y => Zero, Is_Infinity => True);
      end if;

      declare
         Num    : constant Big_Integer := (Three * P.X * P.X + Domain.A) mod Domain.P;
         Den    : constant Big_Integer := (Two * P.Y) mod Domain.P;
         Inv    : constant Big_Integer := Modular_Inverse (Den, Domain.P);
         Lambda : constant Big_Integer := (Num * Inv) mod Domain.P;
         X3     : constant Big_Integer := (Lambda * Lambda - Two * P.X) mod Domain.P;
         Y3     : constant Big_Integer := (Lambda * (P.X - X3) - P.Y) mod Domain.P;
      begin
         return (X => X3, Y => Y3, Is_Infinity => False);
      end;
   end Point_Double;

   function Point_Add (P, Q : Curve_Point; Domain : Domain_Parameters) return Curve_Point is
      Zero : constant Big_Integer := To_Big_Integer (0);
   begin
      if P.Is_Infinity then return Q; end if;
      if Q.Is_Infinity then return P; end if;

      if P.X = Q.X then
         if (P.Y + Q.Y) mod Domain.P = Zero then
            -- Points are inverses of each other (Q = -P)
            return (X => Zero, Y => Zero, Is_Infinity => True);
         else
            -- Points are equal (Q = P), requiring point doubling instead
            return Point_Double (P, Domain);
         end if;
      end if;

      declare
         Num    : constant Big_Integer := (Q.Y - P.Y) mod Domain.P;
         Den    : constant Big_Integer := (Q.X - P.X) mod Domain.P;
         Inv    : constant Big_Integer := Modular_Inverse (Den, Domain.P);
         Lambda : constant Big_Integer := (Num * Inv) mod Domain.P;
         X3     : constant Big_Integer := (Lambda * Lambda - P.X - Q.X) mod Domain.P;
         Y3     : constant Big_Integer := (Lambda * (P.X - X3) - P.Y) mod Domain.P;
      begin
         return (X => X3, Y => Y3, Is_Infinity => False);
      end;
   end Point_Add;

   function Scalar_Multiply (K : Big_Integer; P : Curve_Point; Domain : Domain_Parameters) return Curve_Point is
      Result  : Curve_Point := (X => To_Big_Integer (0), Y => To_Big_Integer (0), Is_Infinity => True);
      Current : Curve_Point := P;
      Temp_K  : Big_Integer := K;
      Zero    : constant Big_Integer := To_Big_Integer (0);
      Two     : constant Big_Integer := To_Big_Integer (2);
   begin
      if P.Is_Infinity or else K = Zero then
         return Result;
      end if;

      -- Standard double-and-add algorithm for scalar multiplication
      while Temp_K > Zero loop
         if (Temp_K mod Two) /= Zero then
            Result := Point_Add (Result, Current, Domain);
         end if;
         Current := Point_Double (Current, Domain);
         Temp_K := Temp_K / Two;
      end loop;
      return Result;
   end Scalar_Multiply;

   function Generate_Key_Pair (Domain : Domain_Parameters; Private_Key : Big_Integer) return Curve_Point is
      Zero : constant Big_Integer := To_Big_Integer (0);
   begin
      if not Is_Valid_Domain (Domain) then
         raise Invalid_Domain_Parameters;
      end if;
      if Private_Key <= Zero or else Private_Key >= Domain.N then
         raise Invalid_Private_Key;
      end if;
      
      return Scalar_Multiply (Private_Key, Domain.G, Domain);
   end Generate_Key_Pair;

   procedure Static_ECDH
     (Domain        : Domain_Parameters;
      My_Private    : Big_Integer;
      Other_Public  : Curve_Point;
      Shared_Secret : out Curve_Point)
   is
   begin
      Perform_Key_Agreement (Domain, My_Private, Other_Public, Shared_Secret);
   end Static_ECDH;

   procedure Ephemeral_ECDHE
     (Domain          : Domain_Parameters;
      My_Ephemeral    : Big_Integer;
      Other_Ephemeral : Curve_Point;
      Shared_Secret   : out Curve_Point)
   is
   begin
      Perform_Key_Agreement (Domain, My_Ephemeral, Other_Ephemeral, Shared_Secret);
   end Ephemeral_ECDHE;

   procedure Anonymous_ECDH
     (Domain        : Domain_Parameters;
      My_Key        : Big_Integer;
      Other_Key     : Curve_Point;
      Shared_Secret : out Curve_Point)
   is
   begin
      Perform_Key_Agreement (Domain, My_Key, Other_Key, Shared_Secret);
   end Anonymous_ECDH;

end Elliptic_Curve_Diffie_Hellman;
