--  Shoelace_Algorithm body — Gauss / surveyor shoelace area & centroid.

pragma Ada_2022;

package body Shoelace_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   procedure Require_Vertex_Count (N : Natural) is
   begin
      if N < 3 or else N > Max_Vertices then
         raise Invalid_Argument;
      end if;
   end Require_Vertex_Count;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near_Point (A, B : Point; Tol : Real := Epsilon) return Boolean is
   begin
      return Near (A.X, B.X, Tol) and then Near (A.Y, B.Y, Tol);
   end Near_Point;

   ---------------------------------------------------------------------------
   -- Core shoelace accumulation
   ---------------------------------------------------------------------------
   --  Returns Σ (x_i y_{i+1} − x_{i+1} y_i) with wrap-around. Caller has
   --  already validated vertex count. Does not divide by 2.

   function Accumulated_Cross (Poly : Polygon) return Real is
      Sum : Real := 0.0;
      J   : Vertex_Index;
   begin
      for I in Poly'Range loop
         if I = Poly'Last then
            J := Poly'First;
         else
            J := I + 1;
         end if;
         Sum := Sum + Poly (I).X * Poly (J).Y
                    - Poly (J).X * Poly (I).Y;
      end loop;
      return Sum;
   end Accumulated_Cross;

   ---------------------------------------------------------------------------
   -- Public API
   ---------------------------------------------------------------------------

   function Determinant_Sum (Poly : Polygon) return Real is
   begin
      Require_Vertex_Count (Poly'Length);
      return Accumulated_Cross (Poly);
   end Determinant_Sum;

   function Signed_Area (Poly : Polygon) return Real is
   begin
      Require_Vertex_Count (Poly'Length);
      return Accumulated_Cross (Poly) / 2.0;
   end Signed_Area;

   function Area (Poly : Polygon) return Real is
   begin
      return abs (Signed_Area (Poly));
   end Area;

   function Is_CCW (Poly : Polygon) return Boolean is
   begin
      return Signed_Area (Poly) > Epsilon;
   end Is_CCW;

   function Is_CW (Poly : Polygon) return Boolean is
   begin
      return Signed_Area (Poly) < -Epsilon;
   end Is_CW;

   function Centroid (Poly : Polygon) return Point is
      Cross_Sum : Real;
      A         : Real;
      Cx, Cy    : Real := 0.0;
      Cross     : Real;
      J         : Vertex_Index;
   begin
      Require_Vertex_Count (Poly'Length);
      Cross_Sum := Accumulated_Cross (Poly);
      A := Cross_Sum / 2.0;
      if abs (A) <= Epsilon then
         raise Invalid_Argument;
      end if;

      for I in Poly'Range loop
         if I = Poly'Last then
            J := Poly'First;
         else
            J := I + 1;
         end if;
         Cross := Poly (I).X * Poly (J).Y - Poly (J).X * Poly (I).Y;
         Cx := Cx + (Poly (I).X + Poly (J).X) * Cross;
         Cy := Cy + (Poly (I).Y + Poly (J).Y) * Cross;
      end loop;

      --  C = (1/(6A)) Σ …  and A = Cross_Sum/2, so 6A = 3·Cross_Sum.
      return (X => Cx / (6.0 * A), Y => Cy / (6.0 * A));
   end Centroid;

end Shoelace_Algorithm;
