--  Binary_Splitting body — recursive / iterative (P,Q) for e-series.

pragma Ada_2022;

package body Binary_Splitting
  with SPARK_Mode => Off
is

   procedure Check_Bounds (A, B : Natural) is
   begin
      if A > B then
         raise Invalid_Argument with "Binary_Split: A > B";
      end if;
      if B > Max_N then
         raise Invalid_Argument with "Binary_Split: B exceeds Max_N";
      end if;
   end Check_Bounds;

   ---------------------------------------------------------------------------
   -- Numeric helpers
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

   ---------------------------------------------------------------------------
   -- Core binary splitting
   ---------------------------------------------------------------------------

   function Binary_Split (A, B : Bound) return Split_Result is
      M     : Bound;
      Left  : Split_Result;
      Right : Split_Result;
   begin
      Check_Bounds (A, B);

      if A = B then
         --  Empty interval: empty sum contribution, empty product = 1.
         return (P => 0, Q => 1);
      elsif B = A + 1 then
         --  Single factor: Q = B, P = 1  (one term in the product tree).
         return (P => 1, Q => Long_Integer (B));
      else
         M := (A + B) / 2;
         Left  := Binary_Split (A, M);
         Right := Binary_Split (M, B);
         --  Wikipedia combine of left/right rational blocks specialised to
         --  the factorial product tree:
         --    Q = Q_L · Q_R
         --    P = P_L · Q_R + P_R
         return
           (P => Left.P * Right.Q + Right.P,
            Q => Left.Q * Right.Q);
      end if;
   end Binary_Split;

   function Binary_Split_Iterative (A, B : Bound) return Split_Result is
      P : Long_Integer;
      Q : Long_Integer;
   begin
      Check_Bounds (A, B);

      if A = B then
         return (P => 0, Q => 1);
      end if;

      --  Seed with the first factor (A+1): P = 1, Q = A+1.
      P := 1;
      Q := Long_Integer (A + 1);

      --  Fold k = A+2 .. B:  P ← P·k + 1 ;  Q ← Q·k
      for K in A + 2 .. B loop
         P := P * Long_Integer (K) + 1;
         Q := Q * Long_Integer (K);
      end loop;

      return (P => P, Q => Q);
   end Binary_Split_Iterative;

   ---------------------------------------------------------------------------
   -- Partial sums for e
   ---------------------------------------------------------------------------

   function Exact_Numerator (N : Split_Index) return Long_Integer is
      R : constant Split_Result := Binary_Split (0, N);
   begin
      return R.P + R.Q;
   end Exact_Numerator;

   function Exact_Denominator (N : Split_Index) return Long_Integer is
      R : constant Split_Result := Binary_Split (0, N);
   begin
      return R.Q;
   end Exact_Denominator;

   function Approximate_E (N : Split_Index) return Long_Float is
      R : constant Split_Result := Binary_Split (0, N);
   begin
      return Partial_Sum (R);
   end Approximate_E;

   function Sum_Naive_Float (N : Split_Index) return Long_Float is
      S : Long_Float := 1.0;  -- n = 0 term: 1/0! = 1
      T : Long_Float := 1.0;
   begin
      for K in 1 .. N loop
         T := T / Long_Float (K);
         S := S + T;
      end loop;
      return S;
   end Sum_Naive_Float;

   function Ratio (R : Split_Result) return Long_Float is
   begin
      if R.Q = 0 then
         raise Invalid_Argument with "Ratio: Q = 0";
      end if;
      return Long_Float (R.P) / Long_Float (R.Q);
   end Ratio;

   function Partial_Sum (R : Split_Result) return Long_Float is
   begin
      if R.Q = 0 then
         raise Invalid_Argument with "Partial_Sum: Q = 0";
      end if;
      return Long_Float (R.P + R.Q) / Long_Float (R.Q);
   end Partial_Sum;

   ---------------------------------------------------------------------------
   -- Factorial
   ---------------------------------------------------------------------------

   function Factorial (N : Split_Index) return Long_Integer is
      F : Long_Integer := 1;
   begin
      for K in 2 .. N loop
         F := F * Long_Integer (K);
      end loop;
      return F;
   end Factorial;

end Binary_Splitting;
