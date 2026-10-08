pragma Ada_2022;

package body Gradient_Descent_Spark
  with SPARK_Mode => On
is
   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Point_Near
     (A, B : Point; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      for I in A'Range loop
         pragma Loop_Invariant (for all J in A'First .. I - 1 => abs (A (J) - B (J)) <= Tol);
         if abs (A (I) - B (I)) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Point_Near;

   function Dot (A, B : Point) return Real is
      S : Real := 0.0;
   begin
      for I in A'Range loop
         pragma Loop_Invariant (abs (S) <= Real (I - A'First) * 10_000.0);
         S := S + A (I) * B (I);
      end loop;
      return S;
   end Dot;

   function Add (A, B : Point) return Point is
      R : Point (A'Range);
   begin
      for I in A'Range loop
         R (I) := A (I) + B (I);
      end loop;
      return R;
   end Add;

   function Sub (A, B : Point) return Point is
      R : Point (A'Range);
   begin
      for I in A'Range loop
         R (I) := A (I) - B (I);
      end loop;
      return R;
   end Sub;

   function Scale (C : Real; X : Point) return Point is
      R : Point (X'Range);
   begin
      for I in X'Range loop
         R (I) := C * X (I);
      end loop;
      return R;
   end Scale;

   function Armijo_Accept
     (F_New, F_Old, Alpha, C1, Dir_Deriv : Real) return Boolean
   is
   begin
      return F_New <= F_Old + C1 * Alpha * Dir_Deriv;
   end Armijo_Accept;


   function Sphere (X : Point) return Real is
      S : Real := 0.0;
   begin
      for I in X'Range loop
         pragma Loop_Invariant (abs (S) <= Real (I - X'First) * 10_000.0);
         S := S + X (I) * X (I);
      end loop;
      return S;
   end Sphere;

   function Sphere_Grad (X : Point) return Point is
      R : Point (X'Range);
   begin
      for I in X'Range loop
         R (I) := 2.0 * X (I);
      end loop;
      return R;
   end Sphere_Grad;
end Gradient_Descent_Spark;
