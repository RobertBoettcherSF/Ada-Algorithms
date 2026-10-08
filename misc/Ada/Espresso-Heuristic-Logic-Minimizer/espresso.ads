pragma Ada_2022;

with Ada.Containers.Indefinite_Vectors;

package Espresso is

   --  Represents the state of a boolean variable in a logic cube
   type Logic_Value is (Zero, One, Dont_Care);

   --  A logic cube represents a product term (e.g., A and not B).
   --  It is an array of Logic_Value, where the index maps to a specific variable.
   type Cube is array (Positive range <>) of Logic_Value;

   --  We use Indefinite_Vectors to store cubes of potentially varying lengths,
   --  though valid logic covers enforce uniform length.
   package Cube_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type   => Positive,
      Element_Type => Cube);

   --  A Cover represents a sum-of-products boolean function.
   type Cover is new Cube_Vectors.Vector with null record;

   --  Exceptions for invalid input data
   Invalid_Cover       : exception;
   Inconsistent_Covers : exception;

   --  -------------------------------------------------------------------------
   --  Pure Functions for Cube Relationships
   --  -------------------------------------------------------------------------

   --  Returns True if Cube A and Cube B share at least one minterm.
   --  They overlap if they do not conflict (Zero vs One) on any variable.
   function Overlaps (A, B : Cube) return Boolean
     with Global => null,
          Pre    => A'Length = B'Length;

   --  Returns True if Cube A completely covers Cube B.
   --  This occurs if for every variable, A is Dont_Care or A(i) = B(i).
   function Subsumes (A, B : Cube) return Boolean
     with Global => null,
          Pre    => A'Length = B'Length;

   --  -------------------------------------------------------------------------
   --  Validation Helpers
   --  -------------------------------------------------------------------------

   --  Returns True if all cubes in the cover have the same number of variables.
   function Is_Uniform (C : Cover) return Boolean
     with Global => null;

   --  Returns the number of variables in the cover (0 if empty).
   function Variables_Count (C : Cover) return Natural
     with Global => null;

   --  Returns True if F and R have the same number of variables (or if either is empty).
   function Consistent (F, R : Cover) return Boolean
     with Global => null;

   --  -------------------------------------------------------------------------
   --  Heuristic Logic Minimizer Core Operations
   --  These algorithms operate on F (the ON-set) and use R (the OFF-set)
   --  for collision detection. Don't Cares are implicitly the remainder.
   --  -------------------------------------------------------------------------

   --  Expands each cube in F to be as large as possible (replacing 0/1 with Dont_Care)
   --  without intersecting any cube in the OFF-set R.
   procedure Expand (F : in out Cover; R : in Cover)
     with Pre  => Is_Uniform (F) and Is_Uniform (R) and Consistent (F, R),
          Post => Is_Uniform (F);

   --  Removes cubes from F that are completely covered by another cube in F.
   procedure Irredundant (F : in out Cover)
     with Pre  => Is_Uniform (F),
          Post => Is_Uniform (F);

   --  Shrinks cubes in F if a portion of the cube is already covered by another
   --  cube in F. This helps escape local minima before another Expand phase.
   procedure Reduce (F : in out Cover)
     with Pre  => Is_Uniform (F),
          Post => Is_Uniform (F);

   --  -------------------------------------------------------------------------
   --  Minimization Variants
   --  -------------------------------------------------------------------------

   --  Variant 1: Single Pass. A fast, greedy minimization that expands prime
   --  implicants and removes subsumed (redundant) cubes exactly once.
   procedure Minimize_Single_Pass (F : in out Cover; R : in Cover)
     with Pre  => Is_Uniform (F) and Is_Uniform (R) and Consistent (F, R),
          Post => Is_Uniform (F);

   --  Variant 2: Iterative Espresso Loop. Continuously loops through Reduce,
   --  Expand, and Irredundant phases until the size of the cover stops shrinking.
   procedure Minimize_Iterative (F : in out Cover; R : in Cover)
     with Pre  => Is_Uniform (F) and Is_Uniform (R) and Consistent (F, R),
          Post => Is_Uniform (F);

end Espresso;
