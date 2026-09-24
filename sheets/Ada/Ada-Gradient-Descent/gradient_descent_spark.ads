pragma Ada_2022;

--  SPARK Level-2 numeric core with bounded floats (overflow-safe classroom model).
--  Parent Gradient_Descent stays SPARK_Mode Off (access + Elementary_Functions).

package Gradient_Descent_Spark
  with SPARK_Mode => On
is
   --  Bounded domain so Level-2 overflow VCs discharge.
   type Real is digits 6 range -1.0E6 .. 1.0E6;
   Max_Dim : constant := 4;
   subtype Dim_Index is Positive range 1 .. Max_Dim;
   type Point is array (Dim_Index range <>) of Real;

   Epsilon_Tol : constant Real := 0.0001;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Global => null, Pre => Tol >= 0.0;

   function Point_Near
     (A, B : Point; Tol : Real := Epsilon_Tol) return Boolean
     with Global => null,
          Pre => A'First = B'First and then A'Last = B'Last and then Tol >= 0.0;

   function Dot (A, B : Point) return Real
     with Global => null,
          Pre => A'First = B'First and then A'Last = B'Last
             and then (for all I in A'Range =>
                         abs (A (I)) <= 100.0 and then abs (B (I)) <= 100.0);

   function Add (A, B : Point) return Point
     with Global => null,
          Pre => A'First = B'First and then A'Last = B'Last
             and then (for all I in A'Range =>
                         abs (A (I)) <= 1.0E5 and then abs (B (I)) <= 1.0E5);

   function Sub (A, B : Point) return Point
     with Global => null,
          Pre => A'First = B'First and then A'Last = B'Last
             and then (for all I in A'Range =>
                         abs (A (I)) <= 1.0E5 and then abs (B (I)) <= 1.0E5);

   function Scale (C : Real; X : Point) return Point
     with Global => null,
          Pre => abs (C) <= 10.0
             and then (for all I in X'Range => abs (X (I)) <= 1.0E5);

   function Armijo_Accept
     (F_New, F_Old, Alpha, C1, Dir_Deriv : Real) return Boolean
     with Global => null;


   function Sphere (X : Point) return Real
     with Global => null,
          Pre => (for all I in X'Range => abs (X (I)) <= 100.0);

   function Sphere_Grad (X : Point) return Point
     with Global => null,
          Pre => (for all I in X'Range => abs (X (I)) <= 1.0E5);
end Gradient_Descent_Spark;
