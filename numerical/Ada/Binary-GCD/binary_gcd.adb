--  Binary_GCD body — Stein binary GCD (iterative + recursive) and
--  classical Euclidean reference on U64.

pragma Ada_2022;

package body Binary_GCD
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Bit helpers
   -------------------------------------------------------------------------

   function Trailing_Zeros (N : U64) return Natural is
      X     : U64 := N;
      Count : Natural := 0;
   begin
      if X = 0 then
         return 64;
      end if;
      while (X and 1) = 0 loop
         X := X / 2;
         Count := Count + 1;
      end loop;
      return Count;
   end Trailing_Zeros;

   function Shift_Right (N : U64; Amount : Natural) return U64 is
      X : U64 := N;
   begin
      if Amount >= 64 then
         return 0;
      end if;
      for I in 1 .. Amount loop
         X := X / 2;
      end loop;
      return X;
   end Shift_Right;

   function Shift_Left (N : U64; Amount : Natural) return U64 is
      X : U64 := N;
   begin
      if Amount >= 64 then
         return 0;
      end if;
      for I in 1 .. Amount loop
         X := X * 2;
      end loop;
      return X;
   end Shift_Left;

   function Is_Odd (N : U64) return Boolean is
   begin
      return (N and 1) = 1;
   end Is_Odd;

   -------------------------------------------------------------------------
   -- Iterative Stein binary GCD
   --
   -- Identities (Wikipedia):
   --   gcd(u, 0) = u
   --   gcd(2u, 2v) = 2 · gcd(u, v)
   --   gcd(u, 2v) = gcd(u, v)   if u odd
   --   gcd(u, v) = gcd(u, v−u)  if u, v odd and u ≤ v
   --
   -- Performant layout: factor out the common power of two once, strip
   -- both operands to odd, then loop with subtract + re-normalize.
   -------------------------------------------------------------------------

   function Gcd (A, B : U64) return U64 is
      U     : U64 := A;
      V     : U64 := B;
      Shift : Natural;
      Zu, Zv : Natural;
      T     : U64;
   begin
      if U = 0 then
         return V;
      elsif V = 0 then
         return U;
      end if;

      Zu := Trailing_Zeros (U);
      Zv := Trailing_Zeros (V);
      if Zu < Zv then
         Shift := Zu;
      else
         Shift := Zv;
      end if;

      U := Shift_Right (U, Zu);
      V := Shift_Right (V, Zv);

      --  Invariant: U and V are odd.
      loop
         if U > V then
            T := U;
            U := V;
            V := T;
         end if;
         --  V ≥ U; both odd → V − U even.
         V := V - U;
         exit when V = 0;
         V := Shift_Right (V, Trailing_Zeros (V));
      end loop;

      return Shift_Left (U, Shift);
   end Gcd;

   -------------------------------------------------------------------------
   -- Recursive Stein (direct identities)
   -------------------------------------------------------------------------

   function Gcd_Recursive (A, B : U64) return U64 is
   begin
      if A = 0 then
         return B;
      elsif B = 0 then
         return A;
      elsif not Is_Odd (A) and then not Is_Odd (B) then
         return Shift_Left (Gcd_Recursive (Shift_Right (A, 1),
                                           Shift_Right (B, 1)), 1);
      elsif not Is_Odd (A) then
         return Gcd_Recursive (Shift_Right (A, 1), B);
      elsif not Is_Odd (B) then
         return Gcd_Recursive (A, Shift_Right (B, 1));
      elsif A >= B then
         return Gcd_Recursive (Shift_Right (A - B, 1), B);
      else
         return Gcd_Recursive (A, Shift_Right (B - A, 1));
      end if;
   end Gcd_Recursive;

   -------------------------------------------------------------------------
   -- Classical Euclidean (reference)
   -------------------------------------------------------------------------

   function Gcd_Euclidean (A, B : U64) return U64 is
      U : U64 := A;
      V : U64 := B;
      T : U64;
   begin
      while V /= 0 loop
         T := U rem V;
         U := V;
         V := T;
      end loop;
      return U;
   end Gcd_Euclidean;

   function Are_Coprime (A, B : U64) return Boolean is
   begin
      return Gcd (A, B) = 1;
   end Are_Coprime;

end Binary_GCD;
