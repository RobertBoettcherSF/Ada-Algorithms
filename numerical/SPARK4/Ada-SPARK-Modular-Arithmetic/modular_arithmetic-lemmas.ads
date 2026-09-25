--  Version: 0.001
--  Modular_Arithmetic.Lemmas: ghost lemmas about "mod" on bounded integers.
--  Each lemma is a ghost procedure whose postcondition is the stated fact;
--  GNATprove proves the body, callers use the postcondition.

pragma Ada_2022;

package Modular_Arithmetic.Lemmas
  with SPARK_Mode => On, Ghost, Pure
is

   --  Division with remainder is unique.
   procedure Mod_Unique (X : Mag126; Q : Mag63; R : Wide; N : Wide_Pos)
     with Global => null,
          Pre  => R in 0 .. N - 1 and then X = Q * N + R,
          Post => X mod N = R;

   --  Quotient/remainder decomposition for a nonnegative dividend.
   procedure Div_Mod (X : Mag126; N : Wide_Pos)
     with Global => null,
          Pre  => X >= 0,
          Post => X / N >= 0 and then X / N <= X
                  and then X = (X / N) * N + X mod N
                  and then X mod N = X rem N;

   --  Floor quotient of an arbitrary (possibly negative) dividend.
   function Floor_Div (X : Mag126; N : Wide_Pos) return Mag126 is
     ((X - X mod N) / N)
     with Global => null,
          Post => Floor_Div'Result * N = X - X mod N
                  and then abs Floor_Div'Result <= abs X;

   --  Adding a multiple of N does not change the residue.
   procedure Mod_Add_Multiple (X : Mag126; K : Mag126; N : Wide_Pos)
     with Global => null,
          Pre  => abs K <= (2**126 - 1) / N,
          Post => (X + K * N) mod N = X mod N;

   --  A multiple of a multiple of N is a multiple of N.
   procedure Mul_Of_Multiple (A, M : Mag63; N : Wide_Pos)
     with Global => null,
          Pre  => M mod N = 0,
          Post => (A * M) mod N = 0;

   --  a * (b mod n) = a * b  (mod n)
   procedure Mul_Mod_Right (A : Mag63; B : Wide_Nat; N : Wide_Pos)
     with Global => null,
          Post => (A * (B mod N)) mod N = (A * B) mod N;

   --  (a mod n) * b = a * b  (mod n)
   procedure Mul_Mod_Left (A : Wide_Nat; B : Mag63; N : Wide_Pos)
     with Global => null,
          Post => ((A mod N) * B) mod N = (A * B) mod N;

   --  a + (b mod n) = a + b  (mod n)
   procedure Add_Mod_Right (A, B : Mag126; N : Wide_Pos)
     with Global => null,
          Pre  => abs A <= 2**125 and abs B <= 2**125,
          Post => (A + (B mod N)) mod N = (A + B) mod N;

   --  Associativity of multiplication modulo n on residues.
   procedure Mul_Assoc (X, Y, Z : Wide_Nat; N : Wide_Pos)
     with Global => null,
          Pre  => X < N and Y < N and Z < N,
          Post => (((X * Y) mod N) * Z) mod N = (X * ((Y * Z) mod N)) mod N;

   --  If m divides p then (y mod p) mod m = y mod m.
   procedure Mod_Mod (Y : Mag126; P, M : Wide_Pos)
     with Global => null,
          Pre  => Y >= 0 and then P mod M = 0,
          Post => (Y mod P) mod M = Y mod M;

   --  (x*y)^2 = (x^2 * y) * y  (mod n) on residues.
   procedure Sq_Mul (X, Y : Wide_Nat; N : Wide_Pos)
     with Global => null,
          Pre  => X < N and Y < N,
          Post => (((X * Y) mod N) * ((X * Y) mod N)) mod N
                  = ((((X * X) mod N) * Y) mod N * Y) mod N;

   --  (a*b) * (c*d) = (a*c) * (b*d)  (mod n) on residues.
   procedure Mul4 (A, B, C, D : Wide_Nat; N : Wide_Pos)
     with Global => null,
          Pre  => A < N and B < N and C < N and D < N,
          Post => (((A * B) mod N) * ((C * D) mod N)) mod N
                  = (((A * C) mod N) * ((B * D) mod N)) mod N;

   --  Sign and monotonicity of products (kept tiny so that the provers
   --  see them without the surrounding context).
   procedure Nonneg_Mul (A, B : Mag63)
     with Global => null,
          Pre  => A >= 0 and then B >= 0,
          Post => A * B >= 0;

   procedure Le_Mul (S, G : Mag63)
     with Global => null,
          Pre  => S >= 0 and then G >= 1,
          Post => S <= S * G;

end Modular_Arithmetic.Lemmas;
