--  Mirror_Descent — Ada 2023 educational package for Wikipedia
--  "Mirror descent": first-order method that generalizes gradient descent
--  and multiplicative weights via a strongly convex mirror map ψ and its
--  Bregman divergence D_ψ. Dual step ∇ψ(y) ← ∇ψ(x) − η g, then project
--  back by minimizing D_ψ(·, y) over the feasible set.
--
--  Two classroom geometries:
--    Euclidean  : ψ(x) = ½‖x‖²  ⇒  x ← x − η g  (optional simplex project)
--    Entropic   : ψ(x) = Σ x_i ln x_i on the simplex ⇒ multiplicative /
--                 Hedge update x_i ← x_i exp(−η g_i) / Z
--
--  Reference:
--    https://en.wikipedia.org/wiki/Mirror_descent
--  Sibling contrast (README only — do not `with`): Ada-Multiplicative-
--  Weight-Update-Method / Ada regret-minimization packages.
--  Part of the RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Mirror_Descent
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   --  Soft classroom bound on ambient dimension.
   Max_Dim : constant Positive := 64;
   subtype Dimension is Positive range 1 .. Max_Dim;
   subtype Dim_Index is Positive range 1 .. Max_Dim;

   --  Unconstrained vectors; callers pass 1-based slices of length D.
   type Vector is array (Positive range <>) of Real;

   --  Euclidean : ψ = ½‖·‖²  →  projected / unprojected gradient descent
   --  Entropic  : negative entropy on the probability simplex → MWU/Hedge
   type Geometry is (Euclidean, Entropic);

   ---------------------------------------------------------------------------
   -- Opaque iterate / state
   ---------------------------------------------------------------------------

   --  Opaque mirror-descent iterate: dimension D, step size η, geometry,
   --  current point x ∈ R^D (on the simplex when Geometry = Entropic),
   --  and round count.
   type State is private;
   subtype Iterate is State;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for bad D, η ≤ 0, gradient length mismatches, non-finite
   --  entries, non-simplex points where required, or uninitialized state.

   ---------------------------------------------------------------------------
   -- Construction / reset
   ---------------------------------------------------------------------------

   function Create
     (D    : Dimension;
      Eta  : Positive_Real;
      Kind : Geometry := Euclidean) return State
     with Global => null;
   --  Euclidean: start at the origin. Entropic: uniform 1/D on the simplex.
   --  Raises Invalid_Argument if η is not finite / not positive.

   function Create
     (Eta     : Positive_Real;
      Initial : Vector;
      Kind    : Geometry := Euclidean) return State
     with Global => null;
   --  Custom initial point; length becomes D. For Entropic, Initial must
   --  be a probability vector (non-negative, sum ≈ 1, positive entries for
   --  a strict interior start — zeros are lifted to a tiny floor then
   --  re-normalized). Raises Invalid_Argument on bad length / η / values.

   procedure Reset (S : in out State)
     with Global => null;
   --  Restore the geometry-default start (origin / uniform); clear rounds.
   --  Keeps D, η, Kind.

   procedure Reset (S : in out State; Initial : Vector)
     with Global => null;
   --  Reset to a custom point of length Dimension_Of (S).

   ---------------------------------------------------------------------------
   -- Accessors
   ---------------------------------------------------------------------------

   function Dimension_Of (S : State) return Dimension
     with Global => null;

   function Learning_Rate (S : State) return Positive_Real
     with Global => null;

   function Geometry_Of (S : State) return Geometry
     with Global => null;

   function Rounds (S : State) return Natural
     with Global => null;

   function Point (S : State) return Vector
     with Global => null;
   --  Current primal iterate x, length D.

   function Get (S : State) return Vector
     with Global => null;
   --  Alias of Point.

   procedure Set_Learning_Rate (S : in out State; Eta : Positive_Real)
     with Global => null;
   --  Change η. Raises Invalid_Argument if η ≤ 0 or non-finite.

   ---------------------------------------------------------------------------
   -- Mirror step
   ---------------------------------------------------------------------------

   procedure Step (S : in out State; Gradient : Vector)
     with Global => null;
   --  One mirror-descent iteration with subgradient / gradient g:
   --    Euclidean :  x ← x − η g
   --                 (optionally project onto simplex if Project_After
   --                  was enabled — see Enable_Simplex_Projection)
   --    Entropic  :  x_i ← x_i · exp(−η g_i);  x ← x / Σ x   (Hedge)
   --  Gradient must have length D and be finite. Raises Invalid_Argument
   --  otherwise.

   procedure Enable_Simplex_Projection
     (S : in out State; Enabled : Boolean := True)
     with Global => null;
   --  For Euclidean geometry: after each Step, Euclidean-project x onto
   --  the probability simplex. Harmless no-op for Entropic (already on
   --  the simplex via Bregman / multiplicative normalization).

   function Simplex_Projection_Enabled (S : State) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Free vector helpers
   ---------------------------------------------------------------------------

   function Dot (A, B : Vector) return Real
     with Global => null;
   --  ⟨a, b⟩. Raises Invalid_Argument if lengths differ or either empty.

   function Norm2 (X : Vector) return Non_Negative
     with Global => null;
   --  ‖x‖₂ = √(⟨x, x⟩).

   function Scale (C : Real; X : Vector) return Vector
     with Global => null;

   function Add (A, B : Vector) return Vector
     with Global => null;

   function Sub (A, B : Vector) return Vector
     with Global => null;

   function Near (A, B : Real; Tol : Real := 1.0E-9) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Vector_Near
     (A, B : Vector; Tol : Real := 1.0E-9) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Simplex helpers / Bregman
   ---------------------------------------------------------------------------

   function Is_Simplex
     (X : Vector; Tol : Real := 1.0E-9) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  True iff every entry ≥ −Tol and |Σ x_i − 1| ≤ Tol.

   function Normalize_Simplex (X : Vector) return Vector
     with Global => null;
   --  x / Σ x_i (requires Σ x_i > 0 and finite). Raises Invalid_Argument
   --  otherwise. This is the entropic / Bregman projection of a positive
   --  vector onto the simplex.

   procedure Project_Simplex (X : in out Vector)
     with Global => null;
   --  Euclidean projection of X onto {x ≥ 0, Σ x_i = 1} via the standard
   --  soft-threshold τ search. Raises Invalid_Argument if X is empty.

   function Project_Simplex (X : Vector) return Vector
     with Global => null;
   --  Functional form of Project_Simplex.

   function Bregman_Euclidean (X, Y : Vector) return Non_Negative
     with Global => null;
   --  D_ψ(x, y) for ψ = ½‖·‖²:  ½‖x − y‖².
   --  Raises Invalid_Argument if lengths differ.

   function Bregman_Entropy (X, Y : Vector) return Non_Negative
     with Global => null;
   --  KL-style Bregman for negative entropy on the relative interior of
   --  the simplex: Σ_i x_i ln(x_i / y_i). Requires positive entries and
   --  equal lengths. Raises Invalid_Argument otherwise.

   function Suggested_Eta_Entropic
     (D : Dimension; T : Positive) return Positive_Real
     with Global => null;
   --  Classroom Hedge schedule η = √(ln(D) / T).

private

   type Store is array (Dim_Index) of Real;

   type State is record
      D              : Dimension     := 1;
      Eta            : Positive_Real := 0.1;
      Kind           : Geometry      := Euclidean;
      X              : Store         := [others => 0.0];
      Round_Count    : Natural       := 0;
      Project_Flag   : Boolean       := False;
      Initialized    : Boolean       := False;
   end record;

end Mirror_Descent;
