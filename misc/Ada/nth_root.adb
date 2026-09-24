--  Nth_Root body — Newton / Halley real roots + integer floor root.

pragma Ada_2022;

package body Nth_Root
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near
     (A, B : Long_Float; Tol : Long_Float := Near_Tol) return Boolean
   is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Abs_Error (A, B : Long_Float) return Long_Float is
   begin
      return abs (A - B);
   end Abs_Error;

   function Pow_Int (Y : Long_Float; K : Natural) return Long_Float is
      Base   : Long_Float := Y;
      Exp    : Natural    := K;
      Result : Long_Float := 1.0;
   begin
      if K = 0 then
         return 1.0;
      end if;
      while Exp > 0 loop
         if Exp rem 2 = 1 then
            Result := Result * Base;
         end if;
         Exp := Exp / 2;
         if Exp > 0 then
            Base := Base * Base;
         end if;
      end loop;
      return Result;
   end Pow_Int;

   function Domain_OK (X : Long_Float; N : Degree) return Boolean is
   begin
      if N rem 2 = 0 then
         return X >= 0.0;
      else
         return True;
      end if;
   end Domain_OK;

   --  Initial guess by doubling/halving from 1 so y^{n} brackets |x|.
   --  Avoids Abs_X/N ≪ 1 (which makes y^{n-1} underflow and Newton explode).
   function Initial_Guess (Abs_X : Long_Float; N : Degree) return Long_Float is
      G    : Long_Float := 1.0;
      G_N  : Long_Float;
      Guard : Natural := 0;
   begin
      if Abs_X = 0.0 then
         return 0.0;
      elsif Abs_X = 1.0 or else N = 1 then
         return Abs_X;
      end if;

      if Abs_X > 1.0 then
         loop
            G_N := Pow_Int (G, N);
            exit when G_N >= Abs_X or else G >= Abs_X;
            G := G * 2.0;
            Guard := Guard + 1;
            exit when Guard > 64;
         end loop;
         --  Prefer a slight underestimate when we overshot by doubling.
         if G > 1.0 and then Pow_Int (G, N) > Abs_X then
            G := G / 2.0;
         end if;
         if G < 1.0 then
            G := 1.0;
         end if;
      else
         --  0 < Abs_X < 1: shrink from 1 toward Abs_X.
         loop
            G_N := Pow_Int (G, N);
            exit when G_N <= Abs_X or else G <= Abs_X;
            G := G * 0.5;
            Guard := Guard + 1;
            exit when Guard > 64;
         end loop;
         if G <= 0.0 then
            G := Abs_X;
         end if;
      end if;
      return G;
   end Initial_Guess;

   function Fail_Domain return Root_Result is
   begin
      return (Value => 0.0, Iterations => 0, Status => Bad_Domain);
   end Fail_Domain;

   ---------------------------------------------------------------------------
   -- Newton
   ---------------------------------------------------------------------------

   function Root_Newton
     (X        : Long_Float;
      N        : Degree;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Root_Result
   is
      Sign_X : constant Long_Float :=
        (if X < 0.0 then -1.0 else 1.0);
      Abs_X  : constant Long_Float := abs (X);
      Y      : Long_Float;
      Y_Next : Long_Float;
      Y_Pow  : Long_Float;
      Rel    : Long_Float;
   begin
      if not Domain_OK (X, N) then
         return Fail_Domain;
      end if;

      if N = 1 then
         return (Value => X, Iterations => 0, Status => Converged);
      end if;

      if Abs_X = 0.0 then
         return (Value => 0.0, Iterations => 0, Status => Converged);
      end if;

      Y := Initial_Guess (Abs_X, N);
      if Y = 0.0 then
         Y := 1.0;
      end if;

      for Iter in 1 .. Max_Iter loop
         --  y^{n-1} once per iteration (Wikipedia efficient form).
         Y_Pow := Pow_Int (Y, N - 1);
         if Y_Pow = 0.0 then
            return Fail_Domain;
         end if;
         Y_Next :=
           (Long_Float (N - 1) * Y + Abs_X / Y_Pow) / Long_Float (N);

         Rel := abs (Y_Next - Y);
         Y := Y_Next;

         if Rel <= Tol or else Rel <= Tol * abs (Y) then
            return
              (Value      => Sign_X * Y,
               Iterations => Iter,
               Status     => Converged);
         end if;
      end loop;

      return
        (Value      => Sign_X * Y,
         Iterations => Max_Iter,
         Status     => Max_Iterations_Reached);
   end Root_Newton;

   function Root (X : Long_Float; N : Degree) return Long_Float is
      R : constant Root_Result := Root_Newton (X, N);
   begin
      if R.Status /= Converged then
         raise Invalid_Argument with "nth root: invalid argument or no converge";
      end if;
      return R.Value;
   end Root;

   function Sqrt (X : Long_Float) return Long_Float is
   begin
      return Root (X, 2);
   end Sqrt;

   function Cbrt (X : Long_Float) return Long_Float is
   begin
      return Root (X, 3);
   end Cbrt;

   ---------------------------------------------------------------------------
   -- Halley
   ---------------------------------------------------------------------------

   function Root_Halley
     (X        : Long_Float;
      N        : Degree;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Root_Result
   is
      Sign_X : constant Long_Float :=
        (if X < 0.0 then -1.0 else 1.0);
      Abs_X  : constant Long_Float := abs (X);
      Y      : Long_Float;
      Y_Next : Long_Float;
      Yn     : Long_Float;
      Num    : Long_Float;
      Den    : Long_Float;
      Rel    : Long_Float;
      NF     : constant Long_Float := Long_Float (N);
   begin
      if not Domain_OK (X, N) then
         return Fail_Domain;
      end if;

      if N = 1 then
         return (Value => X, Iterations => 0, Status => Converged);
      end if;

      if Abs_X = 0.0 then
         return (Value => 0.0, Iterations => 0, Status => Converged);
      end if;

      Y := Initial_Guess (Abs_X, N);
      if Y = 0.0 then
         Y := 1.0;
      end if;

      for Iter in 1 .. Max_Iter loop
         Yn := Pow_Int (Y, N);
         Num := (NF - 1.0) * Yn + (NF + 1.0) * Abs_X;
         Den := (NF + 1.0) * Yn + (NF - 1.0) * Abs_X;
         if Den = 0.0 then
            return Fail_Domain;
         end if;
         Y_Next := Y * (Num / Den);

         Rel := abs (Y_Next - Y);
         Y := Y_Next;

         if Rel <= Tol or else Rel <= Tol * abs (Y) then
            return
              (Value      => Sign_X * Y,
               Iterations => Iter,
               Status     => Converged);
         end if;
      end loop;

      return
        (Value      => Sign_X * Y,
         Iterations => Max_Iter,
         Status     => Max_Iterations_Reached);
   end Root_Halley;

   ---------------------------------------------------------------------------
   -- Integer floor nth root (binary search)
   ---------------------------------------------------------------------------

   --  Safe Natural power: True and Power = Base^Exp when it fits in
   --  Natural; False on overflow (treat as > any finite X).
   function Nat_Pow_Fits
     (Base : Natural; Exp : Degree; Power : out Natural) return Boolean
   is
      B : Natural := Base;
      E : Natural := Natural (Exp);
      P : Natural := 1;
   begin
      if Base = 0 then
         Power := 0;
         return True;
      end if;
      if Base = 1 then
         Power := 1;
         return True;
      end if;

      while E > 0 loop
         if E rem 2 = 1 then
            if P > Natural'Last / B then
               Power := 0;
               return False;
            end if;
            P := P * B;
         end if;
         E := E / 2;
         if E > 0 then
            if B > Natural'Last / B then
               Power := 0;
               return False;
            end if;
            B := B * B;
         end if;
      end loop;
      Power := P;
      return True;
   end Nat_Pow_Fits;

   function Integer_Nth_Root (X : Natural; N : Degree) return Natural is
      Lo, Hi, Mid : Natural;
      Pow         : Natural;
      Fits        : Boolean;
   begin
      if N = 1 then
         return X;
      end if;
      if X = 0 or else X = 1 then
         return X;
      end if;

      Lo := 0;
      Hi := X;

      --  Shrink Hi while Hi^N overflows or exceeds X.
      while Hi > 1 loop
         Fits := Nat_Pow_Fits (Hi, N, Pow);
         if Fits and then Pow <= X then
            exit;
         end if;
         Hi := Hi / 2;
         if Hi = 0 then
            Hi := 1;
            exit;
         end if;
      end loop;

      --  Grow Hi until Hi^N ≥ X (or overflow ⇒ “large enough”).
      loop
         Fits := Nat_Pow_Fits (Hi, N, Pow);
         if (not Fits) or else Pow >= X then
            exit;
         end if;
         if Hi >= Natural'Last / 2 then
            Hi := Natural'Last;
            exit;
         end if;
         Hi := Hi * 2;
      end loop;

      while Lo < Hi loop
         Mid := Lo + (Hi - Lo + 1) / 2;
         Fits := Nat_Pow_Fits (Mid, N, Pow);
         if Fits and then Pow <= X then
            Lo := Mid;
         else
            Hi := Mid - 1;
         end if;
      end loop;

      return Lo;
   end Integer_Nth_Root;

end Nth_Root;
