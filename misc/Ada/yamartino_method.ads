--  Yamartino_Method — Ada 2023 educational single-pass circular mean and
--  standard deviation of wind direction (angular data).
--  Implements the Wikipedia "Yamartino method" (Robert J. Yamartino, 1984):
--  accumulate sa = (1/n) Σ sin θ_i, ca = (1/n) Σ cos θ_i, then
--  θ_a = arctan2(sa, ca), ε = sqrt(1 − (sa²+ca²)),
--  σ_θ = arcsin(ε) · [1 + (2/√3 − 1) · ε³].
--  Also provides two-pass circular reference helpers and a deliberately
--  naive linear mean/std (wrong for wrap-around) for educational contrast.
--  Related: directional statistics, circular dispersion, EPA meteorological
--  monitoring guidance; Farrugia & Micallef (2006).

pragma Ada_2022;

package Yamartino_Method
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   --  Digits 12 for stable trig / resultant-length arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;

   subtype Angle_Radians is Real;
   subtype Angle_Degrees is Real;

   Pi : constant Real := 3.14159265358979;
   Two_Pi : constant Real := 2.0 * Pi;

   Max_Samples : constant Positive := 4096;
   subtype Sample_Count is Natural range 0 .. Max_Samples;
   subtype Sample_Index is Positive range 1 .. Max_Samples;

   type Angle_Array is array (Sample_Index range <>) of Angle_Radians;
   type Degree_Array is array (Sample_Index range <>) of Angle_Degrees;

   --  Online / single-pass accumulator (no storage of individual angles).
   type Running_Yamartino is private;

   type Yamartino_Result is record
      Mean       : Angle_Radians := 0.0;
      Std_Dev    : Non_Negative := 0.0;
      Count      : Natural := 0;
      Epsilon    : Non_Negative := 0.0;
      Resultant  : Non_Negative := 0.0;  -- R = sqrt(sa²+ca²)
      Sa         : Real := 0.0;          -- average sin
      Ca         : Real := 0.0;          -- average cos
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Empty_Sample      : exception;
   Capacity_Exceeded : exception;
   --  Degenerate_Geometry kept as alias name for sibling consistency.
   Degenerate_Geometry : exception renames Empty_Sample;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near_Angle
     (A, B : Angle_Radians; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  Circular closeness after normalizing both to (−π, π].

   ---------------------------------------------------------------------------
   -- Angle conversion / normalization
   ---------------------------------------------------------------------------

   function To_Radians (D : Angle_Degrees) return Angle_Radians
     with Global => null;

   function To_Degrees (R : Angle_Radians) return Angle_Degrees
     with Global => null;

   function Normalize_Angle (R : Angle_Radians) return Angle_Radians
     with Global => null,
          Post => Normalize_Angle'Result > -Pi
            and then Normalize_Angle'Result <= Pi;
   --  Wrap to (−π, π].

   function Normalize_Degrees (D : Angle_Degrees) return Angle_Degrees
     with Global => null,
          Post => Normalize_Degrees'Result >= 0.0
            and then Normalize_Degrees'Result < 360.0;
   --  Wrap to [0, 360).

   function Mean_Degrees (R : Yamartino_Result) return Angle_Degrees
     with Global => null;

   function Std_Dev_Degrees (R : Yamartino_Result) return Non_Negative
     with Global => null;

   ---------------------------------------------------------------------------
   -- Running (online) accumulator
   ---------------------------------------------------------------------------

   function Make_Empty return Running_Yamartino
     with Global => null,
          Post => Count (Make_Empty'Result) = 0;

   procedure Reset (Acc : in out Running_Yamartino)
     with Post => Count (Acc) = 0;

   function Count (Acc : Running_Yamartino) return Natural
     with Global => null;

   procedure Add_Sample
     (Acc : in out Running_Yamartino; Theta : Angle_Radians)
     with Pre => Count (Acc) < Natural'Last,
          Post => Count (Acc) = Count (Acc)'Old + 1;

   procedure Add_Degrees
     (Acc : in out Running_Yamartino; Degrees : Angle_Degrees)
     with Pre => Count (Acc) < Natural'Last,
          Post => Count (Acc) = Count (Acc)'Old + 1;

   function Finalize (Acc : Running_Yamartino) return Yamartino_Result
     with Pre => Count (Acc) >= 1,
          Global => null;
   --  Raises Empty_Sample if Count = 0 (also enforced by Pre when checks on).

   function Compute (Acc : Running_Yamartino) return Yamartino_Result
     renames Finalize;

   ---------------------------------------------------------------------------
   -- Batch Yamartino
   ---------------------------------------------------------------------------

   function Yamartino (Samples : Angle_Array) return Yamartino_Result
     with Pre => Samples'Length >= 1,
          Global => null;

   function Yamartino_Degrees (Samples : Degree_Array) return Yamartino_Result
     with Pre => Samples'Length >= 1,
          Global => null;

   ---------------------------------------------------------------------------
   -- Formula pieces / accessors
   ---------------------------------------------------------------------------

   function Mean_Resultant_Length (Sa, Ca : Real) return Non_Negative
     with Global => null;
   --  R = sqrt(sa² + ca²), clamped to [0, 1].

   function Epsilon_From_Resultant (R : Non_Negative) return Non_Negative
     with Pre => R <= 1.0 + Epsilon_Tol,
          Global => null;
   --  ε = sqrt(1 − R²), clamped.

   function Yamartino_Sigma (Eps : Non_Negative) return Non_Negative
     with Pre => Eps <= 1.0 + Epsilon_Tol,
          Global => null;
   --  σ_θ = arcsin(ε) · [1 + (2/√3 − 1) · ε³].

   ---------------------------------------------------------------------------
   -- Two-pass circular reference (for tests / comparison)
   ---------------------------------------------------------------------------

   function Circular_Mean (Samples : Angle_Array) return Angle_Radians
     with Pre => Samples'Length >= 1,
          Global => null;

   function Circular_Std_Dev_Two_Pass
     (Samples : Angle_Array) return Non_Negative
     with Pre => Samples'Length >= 1,
          Global => null;
   --  Exact-ish circular std via mean resultant length:
   --  σ = sqrt(−2 ln R) when R > 0, else a large sentinel near π/√3 scale;
   --  also provides angular-difference RMS for small dispersion checks.

   function Circular_Std_Dev_Angular
     (Samples : Angle_Array) return Non_Negative
     with Pre => Samples'Length >= 1,
          Global => null;
   --  RMS of shortest signed angular differences from Circular_Mean.

   ---------------------------------------------------------------------------
   -- Naive linear stats (WRONG for wrap-around — educational contrast)
   ---------------------------------------------------------------------------

   function Naive_Linear_Mean (Samples : Angle_Array) return Angle_Radians
     with Pre => Samples'Length >= 1,
          Global => null;

   function Naive_Linear_Std_Dev (Samples : Angle_Array) return Non_Negative
     with Pre => Samples'Length >= 1,
          Global => null;

private

   type Running_Yamartino is record
      N       : Natural := 0;
      Sum_Sin : Real := 0.0;
      Sum_Cos : Real := 0.0;
   end record;

end Yamartino_Method;
