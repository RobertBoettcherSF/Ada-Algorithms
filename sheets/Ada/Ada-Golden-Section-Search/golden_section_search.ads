package Golden_Section_Search is
   subtype Scalar is Long_Float;

   type Scalar_Fn is not null access function (X : Scalar) return Scalar;

   type Search_Config is record
      Tol            : Scalar  := 1.0E-8;
      Max_Iterations : Natural := 200;
   end record;

   type Interval is record
      Left  : Scalar;
      Right : Scalar;
   end record;

   type Search_Result is record
      X_Star     : Scalar;
      F_Star     : Scalar;
      Iterations : Natural;
      Bracket    : Interval;
   end record;

   type Search_Mode is (Find_Minimum, Find_Maximum);

   Golden_Ratio : constant Scalar := 1.618_033_988_749_894_848_2;
   Tau          : constant Scalar := Golden_Ratio - 1.0;

   type Probe_Pair is record
      Lower : Scalar;
      Upper : Scalar;
   end record;

   function Near
     (Left, Right : Scalar;
      Tol         : Scalar := 1.0E-9) return Boolean;

   function Golden_Probes (A, B : Scalar) return Probe_Pair
     with Pre => A < B;

   function Minimize
     (F      : Scalar_Fn;
      A, B   : Scalar;
      Config : Search_Config := (others => <>)) return Search_Result;

   function Maximize
     (F      : Scalar_Fn;
      A, B   : Scalar;
      Config : Search_Config := (others => <>)) return Search_Result;

   function Fibonacci_Search
     (F      : Scalar_Fn;
      A, B   : Scalar;
      Mode   : Search_Mode := Find_Minimum;
      Config : Search_Config := (others => <>)) return Search_Result;

   --  Demonstration objectives used by the tests and README examples.
   function Quartic_Unimodal (X : Scalar) return Scalar;
   function Negative_Quadratic_Max (X : Scalar) return Scalar;
   function Sphere_On_Line (X : Scalar) return Scalar;
   function Increasing_Boundary (X : Scalar) return Scalar;
   function Decreasing_Boundary (X : Scalar) return Scalar;
end Golden_Section_Search;
