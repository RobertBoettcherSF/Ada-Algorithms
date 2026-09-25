--  Version: 0.001
--  Modular_Arithmetic.Montgomery: Montgomery multiplication (REDC) for an
--  odd modulus N < R = 2**62, with conversion into and out of Montgomery
--  form.  Proved: Multiply (A, B) = Mul_Mod (A, B, N).

pragma Ada_2022;

package Modular_Arithmetic.Montgomery
  with SPARK_Mode => On, Pure
is

   R_Bits : constant := 62;
   R      : constant := 2**R_Bits;
   --  Montgomery radix.  T + m*N < 2*N*R stays far inside Wide.

   Max_Montgomery_Modulus : constant := R - 1;

   type Context is record
      N       : Modulus_Type := 3;
      N_Prime : Natural_64 := 0;    --  N * N_Prime = -1 (mod R)
      R_Mod_N : Natural_64 := 0;    --  R mod N
      R_Inv   : Natural_64 := 0;    --  R * R_Inv = 1 (mod N)
   end record;

   --  PROOF-LATER: Importance 3/10, Urgency 1/10, Ada
   function Valid (C : Context) return Boolean is
     (C.N < R and then C.N mod 2 = 1
      and then C.N_Prime < R
      and then (Wide (C.N) * Wide (C.N_Prime)) mod R = R - 1
      and then C.R_Mod_N < C.N
      and then Wide (C.R_Mod_N) = R mod Wide (C.N)
      and then C.R_Inv < C.N
      and then (Wide (C.R_Mod_N) * Wide (C.R_Inv)) mod Wide (C.N) = 1)
     with Global => null;

   --  PROOF-LATER: Importance 9/10, Urgency 4/10, SPARK4
   function Make_Context (N : Modulus_Type) return Context
     with Global => null,
          Pre  => N < R and then N mod 2 = 1,
          Post => Valid (Make_Context'Result) and then Make_Context'Result.N = N;
   --  REQ-016: precomputes N' (via extended Euclid modulo R) and R^-1.

   --  PROOF-LATER: Importance 6/10, Urgency 2/10, SPARK4
   procedure Lemma_Odd_Coprime (N : Modulus_Type)
     with Ghost,
          Global => null,
          Pre  => N mod 2 = 1,
          Post => Gcd (N, R) = 1;
   --  An odd number is coprime to R = 2**62.

   --  PROOF-LATER: Importance 10/10, Urgency 4/10, SPARK4
   function Redc (T : Wide; C : Context) return Natural_64
     with Global => null,
          Pre  => Valid (C) and then T in 0 .. Wide (C.N) * R - 1,
          Post => Redc'Result < C.N
                  and then (Wide (Redc'Result) * R) mod Wide (C.N)
                           = T mod Wide (C.N)
                  and then Wide (Redc'Result)
                           = ((T mod Wide (C.N)) * Wide (C.R_Inv))
                             mod Wide (C.N);
   --  REQ-017: Montgomery reduction, T * R^-1 mod N, without dividing by N.

   --  PROOF-LATER: Importance 8/10, Urgency 3/10, SPARK4
   function To_Montgomery (A : Natural_64; C : Context) return Natural_64
     with Global => null,
          Pre  => Valid (C) and then A < C.N,
          Post => To_Montgomery'Result < C.N
                  and then Wide (To_Montgomery'Result)
                           = (Wide (A) * R) mod Wide (C.N);
   --  A * R mod N.

   --  PROOF-LATER: Importance 8/10, Urgency 3/10, SPARK4
   function From_Montgomery (X : Natural_64; C : Context) return Natural_64
     with Global => null,
          Pre  => Valid (C) and then X < C.N,
          Post => From_Montgomery'Result < C.N
                  and then Wide (From_Montgomery'Result)
                           = (Wide (X) * Wide (C.R_Inv)) mod Wide (C.N);
   --  X * R^-1 mod N (= REDC (X)).

   --  PROOF-LATER: Importance 9/10, Urgency 4/10, SPARK4
   function Montgomery_Multiply (X, Y : Natural_64; C : Context)
     return Natural_64
     with Global => null,
          Pre  => Valid (C) and then X < C.N and then Y < C.N,
          Post => Montgomery_Multiply'Result < C.N
                  and then Wide (Montgomery_Multiply'Result)
                           = (((Wide (X) * Wide (Y)) mod Wide (C.N))
                              * Wide (C.R_Inv)) mod Wide (C.N);
   --  X * Y * R^-1 mod N (= REDC (X * Y)).

   --  PROOF-LATER: Importance 9/10, Urgency 4/10, SPARK4
   function Multiply (A, B : Natural_64; C : Context) return Natural_64
     with Global => null,
          Pre  => Valid (C) and then A < C.N and then B < C.N,
          Post => Multiply'Result = Mul_Mod (A, B, C.N);
   --  REQ-018: From (Montgomery_Multiply (To (A), To (B))) = A * B mod N.

end Modular_Arithmetic.Montgomery;
