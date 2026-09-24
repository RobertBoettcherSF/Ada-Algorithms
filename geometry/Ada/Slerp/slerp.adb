--  Slerp: Spherical Linear Interpolation and Variants
--  Implementation according to ISO/IEC 8652:2023 (Ada 2023)

package body Slerp is

   ----------------------------------------------------------------------
   -- Vector Helper Operations
   ----------------------------------------------------------------------

   function Dot (U, V : Vector_3D) return Real is
   begin
      return U.X * V.X + U.Y * V.Y + U.Z * V.Z;
   end Dot;

   function Norm_Squared (V : Vector_3D) return Real is
   begin
      return Dot (V, V);
   end Norm_Squared;

   function Norm (V : Vector_3D) return Real is
   begin
      return Math.Sqrt (Norm_Squared (V));
   end Norm;

   function Is_Normalized (V : Vector_3D; Tol : Real := 1.0e-5) return Boolean is
   begin
      return abs (Norm_Squared (V) - 1.0) <= Tol;
   end Is_Normalized;

   function Normalize (V : Vector_3D) return Vector_3D is
      N : constant Real := Norm (V);
   begin
      if N < Epsilon then
         raise Degenerate_Vector_Error with "Cannot normalize near-zero vector";
      end if;
      return (X => V.X / N, Y => V.Y / N, Z => V.Z / N);
   end Normalize;

   ----------------------------------------------------------------------
   -- Quaternion Helper Operations
   ----------------------------------------------------------------------

   function Dot (P, Q : Quaternion) return Real is
   begin
      return P.W * Q.W + P.X * Q.X + P.Y * Q.Y + P.Z * Q.Z;
   end Dot;

   function Norm_Squared (Q : Quaternion) return Real is
   begin
      return Dot (Q, Q);
   end Norm_Squared;

   function Norm (Q : Quaternion) return Real is
   begin
      return Math.Sqrt (Norm_Squared (Q));
   end Norm;

   function Is_Normalized (Q : Quaternion; Tol : Real := 1.0e-5) return Boolean is
   begin
      return abs (Norm_Squared (Q) - 1.0) <= Tol;
   end Is_Normalized;

   function Normalize (Q : Quaternion) return Quaternion is
      N : constant Real := Norm (Q);
   begin
      if N < Epsilon then
         raise Degenerate_Quaternion_Error with "Cannot normalize near-zero quaternion";
      end if;
      return (W => Q.W / N, X => Q.X / N, Y => Q.Y / N, Z => Q.Z / N);
   end Normalize;

   function Conjugate (Q : Quaternion) return Quaternion is
   begin
      return (W => Q.W, X => -Q.X, Y => -Q.Y, Z => -Q.Z);
   end Conjugate;

   function Inverse (Q : Quaternion) return Quaternion is
      Sq : constant Real := Norm_Squared (Q);
   begin
      if Sq < Epsilon then
         raise Degenerate_Quaternion_Error with "Cannot invert zero-length quaternion";
      end if;
      return (W =>  Q.W / Sq,
              X => -Q.X / Sq,
              Y => -Q.Y / Sq,
              Z => -Q.Z / Sq);
   end Inverse;

   function Multiply (P, Q : Quaternion) return Quaternion is
   begin
      return (W => P.W * Q.W - P.X * Q.X - P.Y * Q.Y - P.Z * Q.Z,
              X => P.W * Q.X + P.X * Q.W + P.Y * Q.Z - P.Z * Q.Y,
              Y => P.W * Q.Y - P.X * Q.Z + P.Y * Q.W + P.Z * Q.X,
              Z => P.W * Q.Z + P.X * Q.Y - P.Y * Q.X + P.Z * Q.W);
   end Multiply;

   function Log (Q : Quaternion) return Quaternion is
      Vec_Norm : constant Real := Math.Sqrt (Q.X * Q.X + Q.Y * Q.Y + Q.Z * Q.Z);
      Theta    : Real;
      Scale    : Real;
   begin
      --  Clamp Q.W to [-1.0, 1.0] against precision drift
      declare
         Clamped_W : constant Real := Real'Max (-1.0, Real'Min (1.0, Q.W));
      begin
         Theta := Math.Arccos (Clamped_W);
      end;

      if Vec_Norm > Epsilon then
         Scale := Theta / Vec_Norm;
         return (W => 0.0,
                 X => Q.X * Scale,
                 Y => Q.Y * Scale,
                 Z => Q.Z * Scale);
      else
         return (W => 0.0, X => 0.0, Y => 0.0, Z => 0.0);
      end if;
   end Log;

   function Exp (Q : Quaternion) return Quaternion is
      Theta : constant Real := Math.Sqrt (Q.X * Q.X + Q.Y * Q.Y + Q.Z * Q.Z);
      Scale : Real;
      Cos_T : constant Real := Math.Cos (Theta);
   begin
      if Theta > Epsilon then
         Scale := Math.Sin (Theta) / Theta;
         return (W => Cos_T,
                 X => Q.X * Scale,
                 Y => Q.Y * Scale,
                 Z => Q.Z * Scale);
      else
         return (W => 1.0, X => 0.0, Y => 0.0, Z => 0.0);
      end if;
   end Exp;

   function Power (Q : Quaternion; T : Real) return Quaternion is
      L : constant Quaternion := Log (Q);
      Scaled : constant Quaternion :=
        (W => 0.0,
         X => L.X * T,
         Y => L.Y * T,
         Z => L.Z * T);
   begin
      return Exp (Scaled);
   end Power;

   ----------------------------------------------------------------------
   -- Geometric Slerp
   ----------------------------------------------------------------------

   function Geometric_Slerp
     (P0, P1 : Vector_3D;
      T      : Unit_Interval) return Vector_3D
   is
      Cos_Omega : Real := Dot (P0, P1);
   begin
      --  Clamp dot product to avoid NaN from rounding errors
      Cos_Omega := Real'Max (-1.0, Real'Min (1.0, Cos_Omega));

      --  Check for antipodal vectors (undefined shortest great-circle arc)
      if Cos_Omega < -1.0 + Epsilon then
         raise Invalid_Argument_Error with "Slerp between antipodal vectors is ambiguous";
      end if;

      --  If vectors are nearly identical, fall back to linear interpolation to prevent 0/0
      if Cos_Omega > 1.0 - 1.0e-5 then
         declare
            Lerped : constant Vector_3D :=
              (X => (1.0 - T) * P0.X + T * P1.X,
               Y => (1.0 - T) * P0.Y + T * P1.Y,
               Z => (1.0 - T) * P0.Z + T * P1.Z);
         begin
            return Normalize (Lerped);
         end;
      end if;

      declare
         Omega     : constant Real := Math.Arccos (Cos_Omega);
         Sin_Omega : constant Real := Math.Sin (Omega);
         Scale0    : constant Real := Math.Sin ((1.0 - T) * Omega) / Sin_Omega;
         Scale1    : constant Real := Math.Sin (T * Omega) / Sin_Omega;
         Result    : constant Vector_3D :=
           (X => Scale0 * P0.X + Scale1 * P1.X,
            Y => Scale0 * P0.Y + Scale1 * P1.Y,
            Z => Scale0 * P0.Z + Scale1 * P1.Z);
      begin
         return Normalize (Result);
      end;
   end Geometric_Slerp;

   ----------------------------------------------------------------------
   -- Raw Quaternion Slerp
   ----------------------------------------------------------------------

   function Raw_Quaternion_Slerp
     (Q0, Q1 : Quaternion;
      T      : Unit_Interval) return Quaternion
   is
      Cos_Omega : Real := Dot (Q0, Q1);
   begin
      Cos_Omega := Real'Max (-1.0, Real'Min (1.0, Cos_Omega));

      if abs (Cos_Omega) > 1.0 - 1.0e-5 then
         declare
            Lerped : constant Quaternion :=
              (W => (1.0 - T) * Q0.W + T * Q1.W,
               X => (1.0 - T) * Q0.X + T * Q1.X,
               Y => (1.0 - T) * Q0.Y + T * Q1.Y,
               Z => (1.0 - T) * Q0.Z + T * Q1.Z);
         begin
            return Normalize (Lerped);
         end;
      end if;

      declare
         Omega     : constant Real := Math.Arccos (Cos_Omega);
         Sin_Omega : constant Real := Math.Sin (Omega);
         Scale0    : constant Real := Math.Sin ((1.0 - T) * Omega) / Sin_Omega;
         Scale1    : constant Real := Math.Sin (T * Omega) / Sin_Omega;
         Result    : constant Quaternion :=
           (W => Scale0 * Q0.W + Scale1 * Q1.W,
            X => Scale0 * Q0.X + Scale1 * Q1.X,
            Y => Scale0 * Q0.Y + Scale1 * Q1.Y,
            Z => Scale0 * Q0.Z + Scale1 * Q1.Z);
      begin
         return Normalize (Result);
      end;
   end Raw_Quaternion_Slerp;

   ----------------------------------------------------------------------
   -- Shortest-Path Quaternion Slerp
   ----------------------------------------------------------------------

   function Shortest_Path_Slerp
     (Q0, Q1 : Quaternion;
      T      : Unit_Interval) return Quaternion
   is
      Cos_Omega : Real := Dot (Q0, Q1);
      Target_Q1 : Quaternion := Q1;
   begin
      --  If the dot product is negative, invert one quaternion
      --  to take the acute (shortest) spherical arc.
      if Cos_Omega < 0.0 then
         Target_Q1 := (W => -Q1.W, X => -Q1.X, Y => -Q1.Y, Z => -Q1.Z);
         Cos_Omega := -Cos_Omega;
      end if;

      Cos_Omega := Real'Min (1.0, Cos_Omega);

      if Cos_Omega > 1.0 - 1.0e-5 then
         declare
            Lerped : constant Quaternion :=
              (W => (1.0 - T) * Q0.W + T * Target_Q1.W,
               X => (1.0 - T) * Q0.X + T * Target_Q1.X,
               Y => (1.0 - T) * Q0.Y + T * Target_Q1.Y,
               Z => (1.0 - T) * Q0.Z + T * Target_Q1.Z);
         begin
            return Normalize (Lerped);
         end;
      end if;

      declare
         Omega     : constant Real := Math.Arccos (Cos_Omega);
         Sin_Omega : constant Real := Math.Sin (Omega);
         Scale0    : constant Real := Math.Sin ((1.0 - T) * Omega) / Sin_Omega;
         Scale1    : constant Real := Math.Sin (T * Omega) / Sin_Omega;
         Result    : constant Quaternion :=
           (W => Scale0 * Q0.W + Scale1 * Target_Q1.W,
            X => Scale0 * Q0.X + Scale1 * Target_Q1.X,
            Y => Scale0 * Q0.Y + Scale1 * Target_Q1.Y,
            Z => Scale0 * Q0.Z + Scale1 * Target_Q1.Z);
      begin
         return Normalize (Result);
      end;
   end Shortest_Path_Slerp;

   ----------------------------------------------------------------------
   -- Normalized Linear Interpolation (Nlerp)
   ----------------------------------------------------------------------

   function Nlerp
     (Q0, Q1 : Quaternion;
      T      : Unit_Interval) return Quaternion
   is
      Target_Q1 : Quaternion := Q1;
   begin
      if Dot (Q0, Q1) < 0.0 then
         Target_Q1 := (W => -Q1.W, X => -Q1.X, Y => -Q1.Y, Z => -Q1.Z);
      end if;

      declare
         Lerped : constant Quaternion :=
           (W => (1.0 - T) * Q0.W + T * Target_Q1.W,
            X => (1.0 - T) * Q0.X + T * Target_Q1.X,
            Y => (1.0 - T) * Q0.Y + T * Target_Q1.Y,
            Z => (1.0 - T) * Q0.Z + T * Target_Q1.Z);
      begin
         return Normalize (Lerped);
      end;
   end Nlerp;

   ----------------------------------------------------------------------
   -- Squad Intermediate Control Point Computation
   ----------------------------------------------------------------------

   function Compute_Squad_Intermediate
     (Q_Prev, Q_Curr, Q_Next : Quaternion) return Quaternion
   is
      Inv_Curr   : constant Quaternion := Inverse (Q_Curr);
      Q_Prev_Adj : Quaternion := Q_Prev;
      Q_Next_Adj : Quaternion := Q_Next;
   begin
      --  Shortest path alignment relative to Q_Curr
      if Dot (Q_Curr, Q_Prev_Adj) < 0.0 then
         Q_Prev_Adj := (W => -Q_Prev_Adj.W, X => -Q_Prev_Adj.X,
                        Y => -Q_Prev_Adj.Y, Z => -Q_Prev_Adj.Z);
      end if;
      if Dot (Q_Curr, Q_Next_Adj) < 0.0 then
         Q_Next_Adj := (W => -Q_Next_Adj.W, X => -Q_Next_Adj.X,
                        Y => -Q_Next_Adj.Y, Z => -Q_Next_Adj.Z);
      end if;

      declare
         Term1 : constant Quaternion := Log (Multiply (Inv_Curr, Q_Prev_Adj));
         Term2 : constant Quaternion := Log (Multiply (Inv_Curr, Q_Next_Adj));
         Sum   : constant Quaternion :=
           (W => 0.0,
            X => -0.25 * (Term1.X + Term2.X),
            Y => -0.25 * (Term1.Y + Term2.Y),
            Z => -0.25 * (Term1.Z + Term2.Z));
         Factor : constant Quaternion := Exp (Sum);
      begin
         return Normalize (Multiply (Q_Curr, Factor));
      end;
   end Compute_Squad_Intermediate;

   ----------------------------------------------------------------------
   -- Squad Spline Interpolation
   ----------------------------------------------------------------------

   function Squad
     (P, A, B, Q : Quaternion;
      T          : Unit_Interval) return Quaternion
   is
      Slerp_PQ : constant Quaternion := Shortest_Path_Slerp (P, Q, T);
      Slerp_AB : constant Quaternion := Shortest_Path_Slerp (A, B, T);
      Factor   : constant Unit_Interval := 2.0 * T * (1.0 - T);
   begin
      return Shortest_Path_Slerp (Slerp_PQ, Slerp_AB, Factor);
   end Squad;

end Slerp;
