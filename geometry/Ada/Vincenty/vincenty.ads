--  Vincenty — Ada 2023 educational package for Wikipedia "Vincenty's formulae"
--  (Thaddeus Vincenty, Survey Review 1975). Direct and inverse geodesics on an
--  oblate spheroid (WGS-84 defaults), more accurate than spherical great-circle
--  / haversine methods. Truncated series O(f^3); ~0.5 mm on the Earth ellipsoid
--  away from near-antipodes. Inverse may fail to converge for nearly antipodal
--  points (status flag). Optional spherical haversine helper for short arcs.

pragma Ada_2022;

package Vincenty
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   --  Long_Float-class precision for geodesy (metres / radians).
   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Pi : constant Real :=
     3.141592653589793_23846;
   Two_Pi : constant Real := 2.0 * Pi;
   Half_Pi : constant Real := Pi / 2.0;

   Deg_To_Rad_Factor : constant Real := Pi / 180.0;
   Rad_To_Deg_Factor : constant Real := 180.0 / Pi;

   ---------------------------------------------------------------------------
   -- Ellipsoid
   ---------------------------------------------------------------------------

   type Ellipsoid is record
      A : Positive_Real;  --  semi-major axis (equatorial radius), metres
      F : Positive_Real;  --  flattening (0 < f < 1)
   end record;

   --  WGS-84: a = 6378137 m, f = 1/298.257223563
   WGS84_A : constant Real := 6_378_137.0;
   WGS84_F : constant Real := 1.0 / 298.257223563;

   function WGS84 return Ellipsoid
     with Global => null;

   function Semi_Minor (E : Ellipsoid) return Positive_Real
     with Global => null;
   --  b = a (1 − f)

   ---------------------------------------------------------------------------
   -- Exceptions / status
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Max_Iterations : constant Natural := 200;
   --  Typical inverse converges in < 10; near-antipodes may need many more.
   --  Beyond this limit Inverse returns Converged => False.

   Convergence_Tol : constant Real := 1.0E-12;
   --  ~0.006 mm on the Earth ellipsoid (Wikipedia).

   ---------------------------------------------------------------------------
   -- Result records
   ---------------------------------------------------------------------------

   type Inverse_Result is record
      Distance   : Non_Negative := 0.0;  --  s, metres
      Azimuth1   : Real := 0.0;          --  forward azimuth α1, radians
      Azimuth2   : Real := 0.0;          --  reverse azimuth α2, radians
      Converged  : Boolean := False;
      Iterations : Natural := 0;
   end record;

   type Direct_Result is record
      Lat2       : Real := 0.0;          --  φ2, radians
      Lon2       : Real := 0.0;          --  L2, radians
      Azimuth2   : Real := 0.0;          --  α2, radians
      Converged  : Boolean := False;
      Iterations : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-9;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Deg_To_Rad (Degrees : Real) return Real
     with Global => null;

   function Rad_To_Deg (Radians : Real) return Real
     with Global => null;

   function Normalize_Longitude (Lon : Real) return Real
     with Global => null;
   --  Wrap to (−π, π].

   ---------------------------------------------------------------------------
   -- Inverse problem (radians)
   ---------------------------------------------------------------------------
   --  Given (φ1, L1), (φ2, L2) → distance s, forward α1, reverse α2.
   --  Coincident points: s = 0, azimuths 0, Converged True.
   --  Near-antipodal failure: Converged False (Iterations = Max_Iterations
   --  or λ diverged); Distance / azimuths are undefined / best-effort.

   function Inverse
     (Lat1, Lon1, Lat2, Lon2 : Real;
      E                      : Ellipsoid := WGS84) return Inverse_Result
     with Global => null;

   ---------------------------------------------------------------------------
   -- Direct problem (radians)
   ---------------------------------------------------------------------------
   --  Given (φ1, L1), azimuth α1, distance s → (φ2, L2), α2.

   function Direct
     (Lat1, Lon1, Azimuth1, Distance : Real;
      E                              : Ellipsoid := WGS84) return Direct_Result
     with Global => null;

   ---------------------------------------------------------------------------
   -- Degree wrappers
   ---------------------------------------------------------------------------

   function Inverse_Degrees
     (Lat1_Deg, Lon1_Deg, Lat2_Deg, Lon2_Deg : Real;
      E                                      : Ellipsoid := WGS84)
      return Inverse_Result
     with Global => null;
   --  Inputs in degrees; Distance in metres; Azimuth1/2 in radians
   --  (same as Inverse). Use Rad_To_Deg on azimuths if needed.

   function Direct_Degrees
     (Lat1_Deg, Lon1_Deg, Azimuth1_Deg, Distance : Real;
      E                                          : Ellipsoid := WGS84)
      return Direct_Result
     with Global => null;
   --  Lat/Lon/Azimuth inputs in degrees; Distance in metres.
   --  Lat2/Lon2/Azimuth2 in the result are in radians (same as Direct).

   ---------------------------------------------------------------------------
   -- Spherical haversine (comparison helper)
   ---------------------------------------------------------------------------
   --  Great-circle distance on a sphere of radius R (default mean Earth
   --  radius ≈ 6371000 m). Useful for short baselines vs ellipsoidal s.

   Mean_Earth_Radius : constant Real := 6_371_000.0;

   function Haversine
     (Lat1, Lon1, Lat2, Lon2 : Real;
      Radius                 : Positive_Real := Mean_Earth_Radius)
      return Non_Negative
     with Global => null;

   function Haversine_Degrees
     (Lat1_Deg, Lon1_Deg, Lat2_Deg, Lon2_Deg : Real;
      Radius : Positive_Real := Mean_Earth_Radius) return Non_Negative
     with Global => null;

end Vincenty;
