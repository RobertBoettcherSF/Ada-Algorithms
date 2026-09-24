--  Miser — package body (recursive stratified Monte Carlo).

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;
with Ada.Numerics.Float_Random;

package body Miser is

   package EF renames Ada.Numerics.Elementary_Functions;
   package FR renames Ada.Numerics.Float_Random;

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Bounds_Valid (B : Bounds) return Boolean is
   begin
      for I in 1 .. B.D loop
         if B.Lo (I) >= B.Hi (I) then
            return False;
         end if;
      end loop;
      return True;
   end Bounds_Valid;

   function Volume (B : Bounds) return Real is
      V : Real := 1.0;
   begin
      if not Bounds_Valid (B) then
         raise Invalid_Argument with "Miser.Volume: invalid bounds";
      end if;
      for I in 1 .. B.D loop
         V := V * (B.Hi (I) - B.Lo (I));
      end loop;
      return V;
   end Volume;

   function Sqrt_Nonneg (X : Real) return Real is
   begin
      if X <= 0.0 then
         return 0.0;
      end if;
      return Real (EF.Sqrt (Float (X)));
   end Sqrt_Nonneg;

   procedure Sample_Point
     (B   : Bounds;
      Gen : in out FR.Generator;
      X   : out Point)
   is
      U : Float;
   begin
      for I in 1 .. B.D loop
         U := FR.Random (Gen);
         X (I) := B.Lo (I)
           + Real (U) * (B.Hi (I) - B.Lo (I));
      end loop;
   end Sample_Point;

   --  Plain MC on a region with an already-initialized generator.
   --  Returns integral estimate (mean * volume) and variance of that estimate.
   procedure Plain_MC_Inner
     (F        : Integrand;
      B        : Bounds;
      N        : Positive;
      Gen      : in out FR.Generator;
      Estimate : out Real;
      Var_Est  : out Real)
   is
      X     : Point (1 .. B.D);
      Fval  : Real;
      Sum   : Real := 0.0;
      Sum2  : Real := 0.0;
      Mean  : Real;
      Var_F : Real;
      Vol   : constant Real := Volume (B);
      Nn    : constant Real := Real (N);
   begin
      for K in 1 .. N loop
         Sample_Point (B, Gen, X);
         Fval := F (X);
         Sum  := Sum + Fval;
         Sum2 := Sum2 + Fval * Fval;
      end loop;

      Mean := Sum / Nn;
      if N > 1 then
         Var_F := (Sum2 - Sum * Sum / Nn) / Real (N - 1);
         if Var_F < 0.0 then
            Var_F := 0.0;
         end if;
      else
         Var_F := 0.0;
      end if;

      Estimate := Vol * Mean;
      Var_Est  := Vol * Vol * Var_F / Nn;
   end Plain_MC_Inner;

   --  Estimate sample standard deviation of f on B using N points
   --  (not scaled by volume — used for allocation / axis choice).
   function Estimate_Sigma
     (F   : Integrand;
      B   : Bounds;
      N   : Positive;
      Gen : in out FR.Generator) return Real
   is
      X     : Point (1 .. B.D);
      Fval  : Real;
      Sum   : Real := 0.0;
      Sum2  : Real := 0.0;
      Var_F : Real;
      Nn    : constant Real := Real (N);
   begin
      for K in 1 .. N loop
         Sample_Point (B, Gen, X);
         Fval := F (X);
         Sum  := Sum + Fval;
         Sum2 := Sum2 + Fval * Fval;
      end loop;
      if N > 1 then
         Var_F := (Sum2 - Sum * Sum / Nn) / Real (N - 1);
         if Var_F < 0.0 then
            Var_F := 0.0;
         end if;
      else
         Var_F := 0.0;
      end if;
      return Sqrt_Nonneg (Var_F);
   end Estimate_Sigma;

   -------------------------------------------------------------------------
   -- Recursive MISER
   -------------------------------------------------------------------------

   procedure Miser_Recurse
     (F        : Integrand;
      B        : Bounds;
      N        : Positive;
      Depth    : Natural;
      Cfg      : Config;
      Gen      : in out FR.Generator;
      Estimate : out Real;
      Var_Est  : out Real)
   is
      --  Bisect only if we have enough points beyond exploration + leaves.
      Min_Bisect : constant Positive :=
        Positive'Max (Cfg.Min_Points * 4, Cfg.Min_Points + 8);

      Frac : Real;
      N_Pre : Natural;
      N_Side_Est : Positive;
      Best_Dim : Dimension_Count := 1;
      Best_Sig_L : Real := 0.0;
      Best_Sig_R : Real := 0.0;
      Best_Score : Real := Real'Last;
      Sig_L, Sig_R, Score : Real;
      Left, Right : Bounds (B.D);
      Mid : Real;
      N_Left, N_Right : Positive;
      Remaining_Pts : Integer;
      Est_L, Est_R, Var_L, Var_R : Real;
      Denom : Real;
   begin
      --  Leaf: plain Monte Carlo
      if N <= Cfg.Min_Points
        or else Depth >= Cfg.Max_Depth
        or else N < Min_Bisect
      then
         Plain_MC_Inner (F, B, N, Gen, Estimate, Var_Est);
         return;
      end if;

      Frac := Cfg.Dither;
      if Frac <= 0.0 then
         Frac := 0.1;
      elsif Frac >= 1.0 then
         Frac := 0.5;
      end if;

      --  Points used to explore variance on each side of each cut.
      N_Pre := Natural (Real (N) * Frac);
      if N_Pre < 2 * B.D * 2 then
         N_Pre := 2 * B.D * 2;
      end if;
      if N_Pre >= N then
         Plain_MC_Inner (F, B, N, Gen, Estimate, Var_Est);
         return;
      end if;

      N_Side_Est := Positive'Max (2, N_Pre / (2 * B.D));

      --  Examine each possible bisection axis; pick lowest σ_L + σ_R.
      for Dim in 1 .. B.D loop
         Left  := B;
         Right := B;
         Mid   := 0.5 * (B.Lo (Dim) + B.Hi (Dim));
         Left.Hi (Dim)  := Mid;
         Right.Lo (Dim) := Mid;

         Sig_L := Estimate_Sigma (F, Left,  N_Side_Est, Gen);
         Sig_R := Estimate_Sigma (F, Right, N_Side_Est, Gen);
         Score := Sig_L + Sig_R;

         if Score < Best_Score then
            Best_Score := Score;
            Best_Dim   := Dim;
            Best_Sig_L := Sig_L;
            Best_Sig_R := Sig_R;
         end if;
      end loop;

      --  Rebuild best split (midpoint bisection).
      Left  := B;
      Right := B;
      Mid   := 0.5 * (B.Lo (Best_Dim) + B.Hi (Best_Dim));
      Left.Hi (Best_Dim)  := Mid;
      Right.Lo (Best_Dim) := Mid;

      Remaining_Pts := Integer (N) - Integer (2 * B.D * N_Side_Est);
      if Remaining_Pts < Integer (2 * Cfg.Min_Points) then
         Plain_MC_Inner (F, B, N, Gen, Estimate, Var_Est);
         return;
      end if;

      --  Allocate remaining points: N_L/(N_L+N_R) = σ_L/(σ_L+σ_R).
      Denom := Best_Sig_L + Best_Sig_R;
      if Denom <= Epsilon_Tol then
         N_Left := Positive (Remaining_Pts / 2);
      else
         N_Left := Positive
           (Integer'Max
              (Integer (Cfg.Min_Points),
               Integer
                 (Real (Remaining_Pts) * Best_Sig_L / Denom)));
         if Integer (N_Left) > Remaining_Pts - Integer (Cfg.Min_Points) then
            N_Left := Positive (Remaining_Pts - Integer (Cfg.Min_Points));
         end if;
      end if;
      N_Right := Positive (Remaining_Pts - Integer (N_Left));

      Miser_Recurse
        (F, Left, N_Left, Depth + 1, Cfg, Gen, Est_L, Var_L);
      Miser_Recurse
        (F, Right, N_Right, Depth + 1, Cfg, Gen, Est_R, Var_R);

      Estimate := Est_L + Est_R;
      Var_Est  := Var_L + Var_R;
   end Miser_Recurse;

   -------------------------------------------------------------------------
   -- Public entry points
   -------------------------------------------------------------------------

   function Plain_Monte_Carlo
     (F   : Integrand;
      B   : Bounds;
      Cfg : Config := (others => <>)) return Result
   is
      Gen : FR.Generator;
      R   : Result;
   begin
      if F = null then
         raise Invalid_Argument with "Miser.Plain_Monte_Carlo: null integrand";
      end if;
      if not Bounds_Valid (B) then
         raise Invalid_Argument with "Miser.Plain_Monte_Carlo: invalid bounds";
      end if;

      FR.Reset (Gen, Cfg.Seed);
      Plain_MC_Inner
        (F, B, Cfg.N_Points, Gen, R.Estimate, R.Variance_Estimate);
      R.Std_Error := Sqrt_Nonneg (R.Variance_Estimate);
      return R;
   end Plain_Monte_Carlo;

   function Integrate_Miser
     (F   : Integrand;
      B   : Bounds;
      Cfg : Config := (others => <>)) return Result
   is
      Gen : FR.Generator;
      R   : Result;
   begin
      if F = null then
         raise Invalid_Argument with "Miser.Integrate_Miser: null integrand";
      end if;
      if not Bounds_Valid (B) then
         raise Invalid_Argument with "Miser.Integrate_Miser: invalid bounds";
      end if;

      FR.Reset (Gen, Cfg.Seed);
      Miser_Recurse
        (F, B, Cfg.N_Points, 0, Cfg, Gen, R.Estimate, R.Variance_Estimate);
      R.Std_Error := Sqrt_Nonneg (R.Variance_Estimate);
      return R;
   end Integrate_Miser;

   -------------------------------------------------------------------------
   -- Sample integrands
   -------------------------------------------------------------------------

   function Constant_One (X : Point) return Real is
      pragma Unreferenced (X);
   begin
      return 1.0;
   end Constant_One;

   function Constant_Three (X : Point) return Real is
      pragma Unreferenced (X);
   begin
      return 3.0;
   end Constant_Three;

   function Quarter_Circle (X : Point) return Real is
   begin
      if X'Length < 2 then
         return 0.0;
      end if;
      if X (X'First) ** 2 + X (X'First + 1) ** 2 <= 1.0 then
         return 1.0;
      else
         return 0.0;
      end if;
   end Quarter_Circle;

   function Poly_X_Squared (X : Point) return Real is
   begin
      return X (X'First) ** 2;
   end Poly_X_Squared;

   function Poly_Linear_1D (X : Point) return Real is
   begin
      return 2.0 * X (X'First);
   end Poly_Linear_1D;

   function Product_XY (X : Point) return Real is
   begin
      if X'Length < 2 then
         return 0.0;
      end if;
      return X (X'First) * X (X'First + 1);
   end Product_XY;

   function Separable_Peak (X : Point) return Real is
      T : constant Real := X (X'First) - 0.5;
   begin
      return Real (EF.Exp (-10.0 * Float (T) * Float (T)));
   end Separable_Peak;

end Miser;
