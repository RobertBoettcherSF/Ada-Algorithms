--  Kabsch body — centroids, H = PᵀQ, 3×3 SVD (Jacobi), rotation, RMSD.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Kabsch is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   -------------------------------------------------------------------------
   -- Near / vector helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near_Vec3 (A, B : Vec3; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return Near (A (1), B (1), Tol)
        and then Near (A (2), B (2), Tol)
        and then Near (A (3), B (3), Tol);
   end Near_Vec3;

   function Near_Mat3 (A, B : Mat3; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            if not Near (A (I, J), B (I, J), Tol) then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Near_Mat3;

   function Dot (A, B : Vec3) return Real is
   begin
      return A (1) * B (1) + A (2) * B (2) + A (3) * B (3);
   end Dot;

   function Norm2 (V : Vec3) return Non_Negative is
      S : constant Real := V (1) * V (1) + V (2) * V (2) + V (3) * V (3);
   begin
      if S <= 0.0 then
         return 0.0;
      end if;
      return Non_Negative (S);
   end Norm2;

   function Norm (V : Vec3) return Non_Negative is
      S2 : constant Non_Negative := Norm2 (V);
   begin
      if S2 = 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Math.Sqrt (Real (S2)));
   end Norm;

   function Cross (A, B : Vec3) return Vec3 is
   begin
      return
        [A (2) * B (3) - A (3) * B (2),
         A (3) * B (1) - A (1) * B (3),
         A (1) * B (2) - A (2) * B (1)];
   end Cross;

   -------------------------------------------------------------------------
   -- Matrix helpers
   -------------------------------------------------------------------------

   function Zero_Mat3 return Mat3 is
   begin
      return [others => [others => 0.0]];
   end Zero_Mat3;

   function Identity_Mat3 return Mat3 is
      I : Mat3 := Zero_Mat3;
   begin
      I (1, 1) := 1.0;
      I (2, 2) := 1.0;
      I (3, 3) := 1.0;
      return I;
   end Identity_Mat3;

   function Mat3_Transpose (A : Mat3) return Mat3 is
      T : Mat3;
   begin
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            T (I, J) := A (J, I);
         end loop;
      end loop;
      return T;
   end Mat3_Transpose;

   function Mat3_Mul (A, B : Mat3) return Mat3 is
      C : Mat3 := Zero_Mat3;
   begin
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            declare
               S : Real := 0.0;
            begin
               for K in 1 .. 3 loop
                  S := S + A (I, K) * B (K, J);
               end loop;
               C (I, J) := S;
            end;
         end loop;
      end loop;
      return C;
   end Mat3_Mul;

   function Mat3_Vec (A : Mat3; V : Vec3) return Vec3 is
   begin
      return
        [A (1, 1) * V (1) + A (1, 2) * V (2) + A (1, 3) * V (3),
         A (2, 1) * V (1) + A (2, 2) * V (2) + A (2, 3) * V (3),
         A (3, 1) * V (1) + A (3, 2) * V (2) + A (3, 3) * V (3)];
   end Mat3_Vec;

   function Mat3_Det (A : Mat3) return Real is
   begin
      return
        A (1, 1) * (A (2, 2) * A (3, 3) - A (2, 3) * A (3, 2))
        - A (1, 2) * (A (2, 1) * A (3, 3) - A (2, 3) * A (3, 1))
        + A (1, 3) * (A (2, 1) * A (3, 2) - A (2, 2) * A (3, 1));
   end Mat3_Det;

   function Mat3_Trace (A : Mat3) return Real is
   begin
      return A (1, 1) + A (2, 2) + A (3, 3);
   end Mat3_Trace;

   function Mat3_Frobenius (A : Mat3) return Non_Negative is
      S : Real := 0.0;
   begin
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            S := S + A (I, J) * A (I, J);
         end loop;
      end loop;
      if S <= 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Math.Sqrt (S));
   end Mat3_Frobenius;

   -------------------------------------------------------------------------
   -- Centroid / centering / covariance
   -------------------------------------------------------------------------

   function Centroid (P : Point_Cloud) return Vec3 is
      N : constant Real := Real (P'Length);
      C : Vec3 := [0.0, 0.0, 0.0];
   begin
      if P'Length = 0 then
         raise Invalid_Argument;
      end if;
      for I in P'Range loop
         C (1) := C (1) + P (I) (1);
         C (2) := C (2) + P (I) (2);
         C (3) := C (3) + P (I) (3);
      end loop;
      return [C (1) / N, C (2) / N, C (3) / N];
   end Centroid;

   function Translate_To_Origin (P : Point_Cloud) return Point_Cloud is
      C     : constant Vec3 := Centroid (P);
      Out_P : Point_Cloud (P'Range);
   begin
      for I in P'Range loop
         Out_P (I) :=
           [P (I) (1) - C (1), P (I) (2) - C (2), P (I) (3) - C (3)];
      end loop;
      return Out_P;
   end Translate_To_Origin;

   function Translate_By (P : Point_Cloud; T : Vec3) return Point_Cloud is
      Out_P : Point_Cloud (P'Range);
   begin
      for I in P'Range loop
         Out_P (I) :=
           [P (I) (1) + T (1), P (I) (2) + T (2), P (I) (3) + T (3)];
      end loop;
      return Out_P;
   end Translate_By;

   function Covariance_H (P, Q : Point_Cloud) return Mat3 is
      H : Mat3 := Zero_Mat3;
   begin
      if P'Length /= Q'Length or else P'Length = 0 then
         raise Invalid_Argument;
      end if;
      --  H_ij = sum_k P_ki Q_kj  (Pᵀ Q)
      for K in P'Range loop
         for I in 1 .. 3 loop
            for J in 1 .. 3 loop
               H (I, J) := H (I, J) + P (K) (I) * Q (K) (J);
            end loop;
         end loop;
      end loop;
      return H;
   end Covariance_H;

   -------------------------------------------------------------------------
   -- Jacobi symmetric 3 × 3 eigensolver (for AᵀA)
   -------------------------------------------------------------------------

   procedure Jacobi_3x3
     (A         : in out Mat3;
      V         : out Mat3;
      Eigenvals : out Vec3)
   is
      Max_Sweeps : constant Natural := 64;
      Tol        : constant Real := Jacobi_Tol;
   begin
      V := Identity_Mat3;

      for Sweep in 1 .. Max_Sweeps loop
         declare
            Off : Real := 0.0;
         begin
            Off := abs (A (1, 2)) + abs (A (1, 3)) + abs (A (2, 3));
            exit when Off < Tol * 3.0;

            for P in 1 .. 2 loop
               for Q in P + 1 .. 3 loop
                  declare
                     App : constant Real := A (P, P);
                     Aqq : constant Real := A (Q, Q);
                     Apq : constant Real := A (P, Q);
                  begin
                     if abs (Apq) > Tol then
                        declare
                           Tau : constant Real :=
                             (Aqq - App) / (2.0 * Apq);
                           T_Rot : Real;
                           C, S  : Real;
                        begin
                           if Tau >= 0.0 then
                              T_Rot :=
                                1.0 / (Tau + Math.Sqrt (1.0 + Tau * Tau));
                           else
                              T_Rot :=
                                -1.0 / (-Tau + Math.Sqrt (1.0 + Tau * Tau));
                           end if;
                           C := 1.0 / Math.Sqrt (1.0 + T_Rot * T_Rot);
                           S := T_Rot * C;

                           A (P, P) := App - T_Rot * Apq;
                           A (Q, Q) := Aqq + T_Rot * Apq;
                           A (P, Q) := 0.0;
                           A (Q, P) := 0.0;

                           for R in 1 .. 3 loop
                              if R /= P and then R /= Q then
                                 declare
                                    Trp : constant Real := A (R, P);
                                    Trq : constant Real := A (R, Q);
                                 begin
                                    A (R, P) := C * Trp - S * Trq;
                                    A (P, R) := A (R, P);
                                    A (R, Q) := S * Trp + C * Trq;
                                    A (Q, R) := A (R, Q);
                                 end;
                              end if;
                           end loop;

                           for R in 1 .. 3 loop
                              declare
                                 Vrp : constant Real := V (R, P);
                                 Vrq : constant Real := V (R, Q);
                              begin
                                 V (R, P) := C * Vrp - S * Vrq;
                                 V (R, Q) := S * Vrp + C * Vrq;
                              end;
                           end loop;
                        end;
                     end if;
                  end;
               end loop;
            end loop;
         end;
      end loop;

      Eigenvals := [A (1, 1), A (2, 2), A (3, 3)];

      --  Sort eigenpairs descending (largest eigenvalue first).
      for I in 1 .. 2 loop
         for J in I + 1 .. 3 loop
            if Eigenvals (J) > Eigenvals (I) then
               declare
                  Tmp : constant Real := Eigenvals (I);
               begin
                  Eigenvals (I) := Eigenvals (J);
                  Eigenvals (J) := Tmp;
               end;
               for R in 1 .. 3 loop
                  declare
                     U : constant Real := V (R, I);
                  begin
                     V (R, I) := V (R, J);
                     V (R, J) := U;
                  end;
               end loop;
            end if;
         end loop;
      end loop;
   end Jacobi_3x3;

   -------------------------------------------------------------------------
   -- 3 × 3 SVD via AᵀA
   -------------------------------------------------------------------------

   procedure SVD_3x3
     (A  : Mat3;
      U  : out Mat3;
      S  : out Singular_Values;
      Vt : out Mat3)
   is
      AtA   : Mat3 := Mat3_Mul (Mat3_Transpose (A), A);
      V     : Mat3;
      Eigs  : Vec3;
      Sigma : array (1 .. 3) of Real;
   begin
      Jacobi_3x3 (AtA, V, Eigs);

      for I in 1 .. 3 loop
         if Eigs (I) < 0.0 then
            Eigs (I) := 0.0;
         end if;
         Sigma (I) := Math.Sqrt (Eigs (I));
         S (I) := Non_Negative (Sigma (I));
      end loop;

      --  Vt = Vᵀ
      Vt := Mat3_Transpose (V);

      --  U columns: u_i = A v_i / σ_i  (for σ_i > 0); complete via cross.
      U := Zero_Mat3;
      declare
         Used : Natural := 0;
         Cols : array (1 .. 3) of Vec3;
         Ok   : array (1 .. 3) of Boolean := [others => False];
      begin
         for I in 1 .. 3 loop
            declare
               Vi : constant Vec3 := [V (1, I), V (2, I), V (3, I)];
               Ui : Vec3 := Mat3_Vec (A, Vi);
               N  : Real;
            begin
               if Sigma (I) > 1.0E-14 then
                  Ui :=
                    [Ui (1) / Sigma (I),
                     Ui (2) / Sigma (I),
                     Ui (3) / Sigma (I)];
                  N := Real (Norm (Ui));
                  if N > 1.0E-14 then
                     Cols (I) :=
                       [Ui (1) / N, Ui (2) / N, Ui (3) / N];
                     Ok (I) := True;
                     Used := Used + 1;
                  end if;
               end if;
            end;
         end loop;

         --  Fill missing columns to keep U orthogonal (right-handed).
         if Used = 0 then
            Cols (1) := [1.0, 0.0, 0.0];
            Cols (2) := [0.0, 1.0, 0.0];
            Cols (3) := [0.0, 0.0, 1.0];
            Ok := [True, True, True];
         elsif Used = 1 then
            declare
               I0 : Positive := 1;
            begin
               for I in 1 .. 3 loop
                  if Ok (I) then
                     I0 := I;
                     exit;
                  end if;
               end loop;
               declare
                  A0 : constant Vec3 := Cols (I0);
                  Tmp : Vec3;
               begin
                  if abs (A0 (1)) < 0.9 then
                     Tmp := Cross (A0, [1.0, 0.0, 0.0]);
                  else
                     Tmp := Cross (A0, [0.0, 1.0, 0.0]);
                  end if;
                  declare
                     N : constant Real := Real (Norm (Tmp));
                  begin
                     Tmp := [Tmp (1) / N, Tmp (2) / N, Tmp (3) / N];
                  end;
                  for I in 1 .. 3 loop
                     if not Ok (I) then
                        Cols (I) := Tmp;
                        Ok (I) := True;
                        Tmp := Cross (A0, Tmp);
                        declare
                           N2 : constant Real := Real (Norm (Tmp));
                        begin
                           if N2 > 1.0E-14 then
                              Tmp :=
                                [Tmp (1) / N2, Tmp (2) / N2, Tmp (3) / N2];
                           end if;
                        end;
                     end if;
                  end loop;
               end;
            end;
         elsif Used = 2 then
            declare
               I_Miss : Positive := 3;
               I_A, I_B : Positive := 1;
               Found_A  : Boolean := False;
            begin
               for I in 1 .. 3 loop
                  if not Ok (I) then
                     I_Miss := I;
                  elsif not Found_A then
                     I_A := I;
                     Found_A := True;
                  else
                     I_B := I;
                  end if;
               end loop;
               Cols (I_Miss) := Cross (Cols (I_A), Cols (I_B));
               declare
                  N : constant Real := Real (Norm (Cols (I_Miss)));
               begin
                  if N > 1.0E-14 then
                     Cols (I_Miss) :=
                       [Cols (I_Miss) (1) / N,
                        Cols (I_Miss) (2) / N,
                        Cols (I_Miss) (3) / N];
                  else
                     Cols (I_Miss) := [0.0, 0.0, 1.0];
                  end if;
               end;
               --  Ensure right-handed: if det([u1 u2 u3]) < 0 flip missing.
            end;
         end if;

         --  Enforce det(U) = +1 relative to a right-handed frame when possible.
         for I in 1 .. 3 loop
            U (1, I) := Cols (I) (1);
            U (2, I) := Cols (I) (2);
            U (3, I) := Cols (I) (3);
         end loop;
      end;
   end SVD_3x3;

   -------------------------------------------------------------------------
   -- Kabsch rotation / RMSD / superimpose
   -------------------------------------------------------------------------

   function Kabsch_Rotation (P, Q : Point_Cloud) return Mat3 is
      Pc : constant Point_Cloud := Translate_To_Origin (P);
      Qc : constant Point_Cloud := Translate_To_Origin (Q);
      H  : constant Mat3 := Covariance_H (Pc, Qc);
      U, Vt, R : Mat3;
      S        : Singular_Values;
      D        : Real;
      Middle   : Mat3 := Identity_Mat3;
   begin
      --  Wikipedia: H = U Σ Vᵀ, R = U diag(1,1,d) Vᵀ with d = det(U Vᵀ).
      SVD_3x3 (H, U, S, Vt);
      --  Vᵀ is Vt; V = Vtᵀ.  det(U Vᵀ) = det(U) det(V) = det(U Vt) wait:
      --  Vᵀ = Vt, so U Vᵀ = U * Vt.
      D := Mat3_Det (Mat3_Mul (U, Vt));
      if D < 0.0 then
         Middle (3, 3) := -1.0;
      end if;
      R := Mat3_Mul (Mat3_Mul (U, Middle), Vt);

      --  Guarantee proper rotation (numerical cleanup).
      if Mat3_Det (R) < 0.0 then
         Middle (3, 3) := -Middle (3, 3);
         R := Mat3_Mul (Mat3_Mul (U, Middle), Vt);
      end if;
      return R;
   end Kabsch_Rotation;

   function Apply_Rotation_Vec (R : Mat3; V : Vec3) return Vec3 is
   begin
      return Mat3_Vec (R, V);
   end Apply_Rotation_Vec;

   function Apply_Rotation (R : Mat3; P : Point_Cloud) return Point_Cloud is
      Out_P : Point_Cloud (P'Range);
   begin
      for I in P'Range loop
         Out_P (I) := Mat3_Vec (R, P (I));
      end loop;
      return Out_P;
   end Apply_Rotation;

   function RMSD (P, Q : Point_Cloud) return Non_Negative is
      N   : constant Real := Real (P'Length);
      Acc : Real := 0.0;
   begin
      if P'Length /= Q'Length or else P'Length = 0 then
         raise Invalid_Argument;
      end if;
      for I in P'Range loop
         declare
            Dx : constant Real := P (I) (1) - Q (I) (1);
            Dy : constant Real := P (I) (2) - Q (I) (2);
            Dz : constant Real := P (I) (3) - Q (I) (3);
         begin
            Acc := Acc + Dx * Dx + Dy * Dy + Dz * Dz;
         end;
      end loop;
      if Acc <= 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Math.Sqrt (Acc / N));
   end RMSD;

   function Superimpose (P, Q : Point_Cloud) return Superimpose_Result is
      Res : Superimpose_Result;
      Cp  : constant Vec3 := Centroid (P);
      Cq  : constant Vec3 := Centroid (Q);
      R   : constant Mat3 := Kabsch_Rotation (P, Q);
      RCq : constant Vec3 := Mat3_Vec (R, Cq);
      T   : constant Vec3 :=
        [Cp (1) - RCq (1), Cp (2) - RCq (2), Cp (3) - RCq (3)];
      Aligned : Point_Cloud (Q'Range);
   begin
      Res.R := R;
      Res.Translation := T;
      Res.Centroid_P := Cp;
      Res.Centroid_Q := Cq;
      for I in Q'Range loop
         declare
            V : constant Vec3 := Mat3_Vec (R, Q (I));
         begin
            Aligned (I) := [V (1) + T (1), V (2) + T (2), V (3) + T (3)];
         end;
      end loop;
      Res.RMSD := RMSD (P, Aligned);
      return Res;
   end Superimpose;

   function Transformed_Cloud
     (Q : Point_Cloud; Res : Superimpose_Result) return Point_Cloud
   is
      Out_P : Point_Cloud (Q'Range);
   begin
      for I in Q'Range loop
         declare
            V : constant Vec3 := Mat3_Vec (Res.R, Q (I));
         begin
            Out_P (I) :=
              [V (1) + Res.Translation (1),
               V (2) + Res.Translation (2),
               V (3) + Res.Translation (3)];
         end;
      end loop;
      return Out_P;
   end Transformed_Cloud;

   -------------------------------------------------------------------------
   -- 2-D Kabsch
   -------------------------------------------------------------------------

   function Identity_Mat2 return Mat2 is
   begin
      return [[1.0, 0.0], [0.0, 1.0]];
   end Identity_Mat2;

   function Mat2_Det (A : Mat2) return Real is
   begin
      return A (1, 1) * A (2, 2) - A (1, 2) * A (2, 1);
   end Mat2_Det;

   function Mat2_Mul_Vec (A : Mat2; V : Vec2) return Vec2 is
   begin
      return
        [A (1, 1) * V (1) + A (1, 2) * V (2),
         A (2, 1) * V (1) + A (2, 2) * V (2)];
   end Mat2_Mul_Vec;

   function Centroid_2D (P : Point_Cloud_2D) return Vec2 is
      N : constant Real := Real (P'Length);
      C : Vec2 := [0.0, 0.0];
   begin
      for I in P'Range loop
         C (1) := C (1) + P (I) (1);
         C (2) := C (2) + P (I) (2);
      end loop;
      return [C (1) / N, C (2) / N];
   end Centroid_2D;

   function Kabsch_Rotation_2D (P, Q : Point_Cloud_2D) return Mat2 is
      Cp : constant Vec2 := Centroid_2D (P);
      Cq : constant Vec2 := Centroid_2D (Q);
      --  H = Pᵀ Q  (2 × 2)
      H11, H12, H21, H22 : Real := 0.0;
      U, Vt : Mat2;
      AtA11, AtA12, AtA22 : Real;
      Lam1, Lam2, V1x, V1y, V2x, V2y : Real;
      S1, S2 : Real;
      D : Real;
      R : Mat2;
   begin
      for I in P'Range loop
         declare
            Px : constant Real := P (I) (1) - Cp (1);
            Py : constant Real := P (I) (2) - Cp (2);
            Qx : constant Real := Q (I) (1) - Cq (1);
            Qy : constant Real := Q (I) (2) - Cq (2);
         begin
            H11 := H11 + Px * Qx;
            H12 := H12 + Px * Qy;
            H21 := H21 + Py * Qx;
            H22 := H22 + Py * Qy;
         end;
      end loop;

      AtA11 := H11 * H11 + H21 * H21;
      AtA12 := H11 * H12 + H21 * H22;
      AtA22 := H12 * H12 + H22 * H22;

      declare
         Trace : constant Real := AtA11 + AtA22;
         Detm  : constant Real := AtA11 * AtA22 - AtA12 * AtA12;
         Disc  : Real := Trace * Trace - 4.0 * Detm;
         Sdisc : Real;
         N1, N2 : Real;
      begin
         if Disc < 0.0 then
            Disc := 0.0;
         end if;
         Sdisc := Math.Sqrt (Disc);
         Lam1 := 0.5 * (Trace + Sdisc);
         Lam2 := 0.5 * (Trace - Sdisc);

         if abs (AtA12) > abs (Lam1 - AtA22) then
            V1x := AtA12;
            V1y := Lam1 - AtA11;
         else
            V1x := Lam1 - AtA22;
            V1y := AtA12;
         end if;
         N1 := Math.Sqrt (V1x * V1x + V1y * V1y);
         if N1 < 1.0E-30 then
            V1x := 1.0;
            V1y := 0.0;
         else
            V1x := V1x / N1;
            V1y := V1y / N1;
         end if;
         V2x := -V1y;
         V2y := V1x;
         N2 := Math.Sqrt (V2x * V2x + V2y * V2y);
         if N2 > 0.0 then
            V2x := V2x / N2;
            V2y := V2y / N2;
         end if;
      end;

      S1 := (if Lam1 > 0.0 then Math.Sqrt (Lam1) else 0.0);
      S2 := (if Lam2 > 0.0 then Math.Sqrt (Lam2) else 0.0);

      declare
         U1x : Real := H11 * V1x + H12 * V1y;
         U1y : Real := H21 * V1x + H22 * V1y;
         U2x, U2y : Real;
         N : Real;
      begin
         if S1 > 1.0E-14 then
            U1x := U1x / S1;
            U1y := U1y / S1;
         end if;
         N := Math.Sqrt (U1x * U1x + U1y * U1y);
         if N > 1.0E-14 then
            U1x := U1x / N;
            U1y := U1y / N;
         else
            U1x := 1.0;
            U1y := 0.0;
         end if;
         U2x := -U1y;
         U2y := U1x;
         if S2 > 1.0E-14 then
            declare
               Tx : constant Real := (H11 * V2x + H12 * V2y) / S2;
               Ty : constant Real := (H21 * V2x + H22 * V2y) / S2;
               Nt : constant Real := Math.Sqrt (Tx * Tx + Ty * Ty);
            begin
               if Nt > 1.0E-14 then
                  if Tx * U2x + Ty * U2y < 0.0 then
                     U2x := -Tx / Nt;
                     U2y := -Ty / Nt;
                  else
                     U2x := Tx / Nt;
                     U2y := Ty / Nt;
                  end if;
               end if;
            end;
         end if;
         U := [[U1x, U2x], [U1y, U2y]];
         --  V = [[V1x, V2x], [V1y, V2y]]  =>  Vt = Vᵀ
         Vt := [[V1x, V1y], [V2x, V2y]];
      end;

      declare
         UV11 : constant Real :=
           U (1, 1) * Vt (1, 1) + U (1, 2) * Vt (2, 1);
         UV12 : constant Real :=
           U (1, 1) * Vt (1, 2) + U (1, 2) * Vt (2, 2);
         UV21 : constant Real :=
           U (2, 1) * Vt (1, 1) + U (2, 2) * Vt (2, 1);
         UV22 : constant Real :=
           U (2, 1) * Vt (1, 2) + U (2, 2) * Vt (2, 2);
      begin
         D := UV11 * UV22 - UV12 * UV21;
      end;

      declare
         S22 : constant Real := (if D < 0.0 then -1.0 else 1.0);
         US11 : constant Real := U (1, 1);
         US12 : constant Real := U (1, 2) * S22;
         US21 : constant Real := U (2, 1);
         US22 : constant Real := U (2, 2) * S22;
      begin
         R :=
           [[US11 * Vt (1, 1) + US12 * Vt (2, 1),
             US11 * Vt (1, 2) + US12 * Vt (2, 2)],
            [US21 * Vt (1, 1) + US22 * Vt (2, 1),
             US21 * Vt (1, 2) + US22 * Vt (2, 2)]];
      end;

      if Mat2_Det (R) < 0.0 then
         declare
            US11 : constant Real := U (1, 1);
            US12 : constant Real := -U (1, 2);
            US21 : constant Real := U (2, 1);
            US22 : constant Real := -U (2, 2);
         begin
            R :=
              [[US11 * Vt (1, 1) + US12 * Vt (2, 1),
                US11 * Vt (1, 2) + US12 * Vt (2, 2)],
               [US21 * Vt (1, 1) + US22 * Vt (2, 1),
                US21 * Vt (1, 2) + US22 * Vt (2, 2)]];
         end;
      end if;
      return R;
   end Kabsch_Rotation_2D;

   function RMSD_2D (P, Q : Point_Cloud_2D) return Non_Negative is
      N   : constant Real := Real (P'Length);
      Acc : Real := 0.0;
   begin
      for I in P'Range loop
         declare
            Dx : constant Real := P (I) (1) - Q (I) (1);
            Dy : constant Real := P (I) (2) - Q (I) (2);
         begin
            Acc := Acc + Dx * Dx + Dy * Dy;
         end;
      end loop;
      if Acc <= 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Math.Sqrt (Acc / N));
   end RMSD_2D;

end Kabsch;
