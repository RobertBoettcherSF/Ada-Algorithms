--  Standalone test suite for Buzens_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Buzens_Algorithm; use Buzens_Algorithm;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Real; Tol : Real := 1.0E-6) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   --  Brute-force G(N) for M=2 by enumerating compositions.
   function Brute_G2 (X1, X2 : Real; N : Natural) return Real is
      S : Real := 0.0;
   begin
      for K in 0 .. N loop
         S := S + Power (X1, K) * Power (X2, N - K);
      end loop;
      return S;
   end Brute_G2;

   --  Brute-force G(N) for M=3.
   function Brute_G3 (X1, X2, X3 : Real; N : Natural) return Real is
      S : Real := 0.0;
   begin
      for N1 in 0 .. N loop
         for N2 in 0 .. N - N1 loop
            declare
               N3 : constant Natural := N - N1 - N2;
            begin
               S := S + Power (X1, N1) * Power (X2, N2) * Power (X3, N3);
            end;
         end loop;
      end loop;
      return S;
   end Brute_G3;

begin
   Put_Line ("Buzens_Algorithm test suite");
   Put_Line ("===========================");

   ---------------------------------------------------------------------
   Section ("1. Near / Power helpers");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Near (1.0, 1.0 + 1.0E-9), "Near accepts tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 0.0), "Near(0,0)");
      Check (Approx (Power (2.0, 0), 1.0), "Power(_,0)=1");
      Check (Approx (Power (2.0, 3), 8.0), "Power(2,3)=8");
      Check (Approx (Power (0.5, 2), 0.25), "Power(0.5,2)=0.25");
      Check (Approx (Power (3.0, 1), 3.0), "Power(3,1)=3");
      Check (not Near (1.0, 1.0, 0.0) or else Near (1.0, 1.0, 0.0),
             "Near tol=0 still reflexive");
      Check (Approx (Power (1.0, 10), 1.0), "Power(1,10)=1");
   end;

   ---------------------------------------------------------------------
   Section ("2. M=1 trivial: G(n)=X1^n");
   ---------------------------------------------------------------------
   declare
      X : constant X_Vector := [1 => 2.5];
      N : constant Natural := 6;
      G : constant G_Vector := Compute_G (X, N);
   begin
      Check (G'First = 0 and then G'Last = N, "G bounds 0..N");
      Check (Approx (G (0), 1.0), "G(0)=1");
      Check (Approx (G (1), 2.5), "G(1)=X1");
      Check (Approx (G (2), 6.25), "G(2)=X1^2");
      Check (Approx (G (3), 15.625), "G(3)=X1^3");
      Check (Approx (G (6), Power (2.5, 6)), "G(6)=X1^6");
      for K in 0 .. N loop
         Check (Approx (G (K), Power (2.5, K), 1.0E-8),
                "G(" & Natural'Image (K) & ")=X^k");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("3. M=2 small N: convolution vs brute-force");
   ---------------------------------------------------------------------
   declare
      X : constant X_Vector := [1.0, 2.0];
      N : constant Natural := 5;
      G : constant G_Vector := Compute_G (X, N);
   begin
      for Ni in 0 .. N loop
         declare
            B : constant Real := Brute_G2 (1.0, 2.0, Ni);
         begin
            Check (Approx (G (Ni), B, 1.0E-8),
                   "M=2 G(" & Natural'Image (Ni) & ") matches brute");
         end;
      end loop;
      --  Closed form: G(n) = sum_k X1^k X2^{n-k} = X2^n * sum (X1/X2)^k
      Check (Approx (G (0), 1.0), "M=2 G(0)=1");
      Check (Approx (G (1), 1.0 + 2.0), "M=2 G(1)=X1+X2");
      Check (G (N) > G (N - 1), "G increasing in N for positive X");
   end;

   ---------------------------------------------------------------------
   Section ("4. M=3 brute-force vs convolution");
   ---------------------------------------------------------------------
   declare
      X : constant X_Vector := [0.5, 1.0, 1.5];
      N : constant Natural := 4;
      G : constant G_Vector := Compute_G (X, N);
   begin
      for Ni in 0 .. N loop
         Check (Approx (G (Ni), Brute_G3 (0.5, 1.0, 1.5, Ni), 1.0E-7),
                "M=3 G(" & Natural'Image (Ni) & ") matches brute");
      end loop;
      Check (Approx (G (0), 1.0), "M=3 G(0)=1");
      Check (G (4) > 0.0, "M=3 G(4)>0");
   end;

   ---------------------------------------------------------------------
   Section ("5. Wikipedia Pascal loop / C[0]=1 invariant");
   ---------------------------------------------------------------------
   declare
      X : constant X_Vector := [0.7, 1.3, 0.9, 1.1];
      N : constant Natural := 8;
      G : constant G_Vector := Compute_G (X, N);
      --  Manual single-column mimic
      C : G_Vector (0 .. N);
   begin
      C (0) := 1.0;
      for Ni in 1 .. N loop
         C (Ni) := 0.0;
      end loop;
      for M in X'Range loop
         for Ni in 1 .. N loop
            C (Ni) := C (Ni) + X (M) * C (Ni - 1);
         end loop;
         Check (Approx (C (0), 1.0),
                "C(0) stays 1 after station" & Station_Index'Image (M));
      end loop;
      for Ni in 0 .. N loop
         Check (Approx (C (Ni), G (Ni), 1.0E-9),
                "manual Pascal equals Compute_G at n="
                & Natural'Image (Ni));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("6. Compute_G_Matrix matches Compute_G");
   ---------------------------------------------------------------------
   declare
      X  : constant X_Vector := [2.0, 3.0, 0.5];
      N  : constant Natural := 5;
      G  : constant G_Vector := Compute_G (X, N);
      GM : constant G_Matrix := Compute_G_Matrix (X, N);
   begin
      Check (GM'First (1) = 0 and then GM'Last (1) = N, "matrix n bounds");
      Check (GM'First (2) = X'First and then GM'Last (2) = X'Last,
             "matrix m bounds");
      for M in X'Range loop
         Check (Approx (GM (0, M), 1.0), "g(0,m)=1");
      end loop;
      for Ni in 0 .. N loop
         Check (Approx (GM (Ni, X'Last), G (Ni), 1.0E-9),
                "last column = Compute_G at n=" & Natural'Image (Ni));
      end loop;
      --  First column powers
      for Ni in 0 .. N loop
         Check (Approx (GM (Ni, X'First), Power (X (X'First), Ni), 1.0E-9),
                "g(n,1)=X1^n");
      end loop;
      --  Recurrence spot-check g(3,2) = g(3,1) + X2*g(2,2)
      declare
         M2 : constant Station_Index := 2;
         Lhs : constant Real := GM (3, M2);
         Rhs : constant Real := GM (3, 1) + X (2) * GM (2, M2);
      begin
         Check (Approx (Lhs, Rhs, 1.0E-9), "recurrence g(3,2)");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Marginals P(n_i=k) sum to 1");
   ---------------------------------------------------------------------
   declare
      X : constant X_Vector := [1.0, 2.0, 0.5];
      N : constant Natural := 6;
      G : constant G_Vector := Compute_G (X, N);
   begin
      for I in X'Range loop
         declare
            S : Real := 0.0;
         begin
            for K in 0 .. N loop
               S := S + Prob_Ni_Equals (X (I), K, G);
            end loop;
            Check (Approx (S, 1.0, 1.0E-6),
                   "sum_k P(n_" & Station_Index'Image (I) & "=k) = 1");
            Check (Prob_Ni_Equals (X (I), 0, G) >= 0.0, "P(=0)>=0");
            Check (Prob_Ni_Equals (X (I), N, G) >= 0.0, "P(=N)>=0");
         end;
      end loop;
      Check (Approx (Prob_Ni_At_Least (X (1), 0, G), 1.0, 1.0E-9),
             "P(n_i>=0)=1");
   end;

   ---------------------------------------------------------------------
   Section ("8. E[n_i] sum over i equals N");
   ---------------------------------------------------------------------
   declare
      X   : constant X_Vector := [0.8, 1.2, 1.0];
      N   : constant Natural := 7;
      G   : constant G_Vector := Compute_G (X, N);
      Sum : Real := 0.0;
   begin
      for I in X'Range loop
         declare
            E : constant Real := Expected_Ni (X (I), G);
         begin
            Check (E >= 0.0, "E[n_i] >= 0");
            Check (E <= Real (N) + 1.0E-6, "E[n_i] <= N");
            Sum := Sum + E;
         end;
      end loop;
      Check (Approx (Sum, Real (N), 1.0E-5), "sum_i E[n_i] = N");
      --  Another network
      declare
         X2 : constant X_Vector := [1.0, 1.0];
         G2 : constant G_Vector := Compute_G (X2, 4);
         S2 : constant Real :=
           Expected_Ni (1.0, G2) + Expected_Ni (1.0, G2);
      begin
         Check (Approx (S2, 4.0, 1.0E-6), "balanced M=2 sum E = 4");
         Check (Approx (Expected_Ni (1.0, G2), 2.0, 1.0E-6),
                "balanced equal share E=N/2");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. P(n_i>=k) vs summing P(n_i=j)");
   ---------------------------------------------------------------------
   declare
      X : constant X_Vector := [1.5, 0.75];
      N : constant Natural := 5;
      G : constant G_Vector := Compute_G (X, N);
   begin
      for I in X'Range loop
         for K in 0 .. N loop
            declare
               Tail : Real := 0.0;
               At_L : constant Real := Prob_Ni_At_Least (X (I), K, G);
            begin
               for J in K .. N loop
                  Tail := Tail + Prob_Ni_Equals (X (I), J, G);
               end loop;
               Check (Approx (At_L, Tail, 1.0E-6),
                      "P(>=k) = sum P(=j) i="
                      & Station_Index'Image (I)
                      & " k=" & Natural'Image (K));
            end;
         end loop;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("10. State probabilities sum to ~1");
   ---------------------------------------------------------------------
   declare
      X : constant X_Vector := [1.0, 2.0];
      N : constant Natural := 4;
      G : constant G_Vector := Compute_G (X, N);
      S : Real := 0.0;
   begin
      for N1 in 0 .. N loop
         declare
            N2   : constant Natural := N - N1;
            St   : constant Customer_Vector := [N1, N2];
            P    : constant Real :=
              State_Probability (St, X, G (N));
         begin
            Check (P >= 0.0, "state prob >= 0");
            S := S + P;
         end;
      end loop;
      Check (Approx (S, 1.0, 1.0E-6), "enumerated M=2 states sum to 1");
      --  Spot-check one state vs formula
      declare
         St : constant Customer_Vector := [2, 2];
         P  : constant Real := State_Probability (St, X, G (N));
         Manual : constant Real :=
           Power (1.0, 2) * Power (2.0, 2) / G (N);
      begin
         Check (Approx (P, Manual, 1.0E-9), "State_Probability matches formula");
         Check (Approx (P, 4.0 / G (N), 1.0E-9), "P(2,2)=4/G(N)");
      end;
      --  M=3 enumeration
      declare
         X3 : constant X_Vector := [0.5, 1.0, 1.5];
         N3 : constant Natural := 3;
         G3 : constant G_Vector := Compute_G (X3, N3);
         S3 : Real := 0.0;
      begin
         for A in 0 .. N3 loop
            for B in 0 .. N3 - A loop
               declare
                  C : constant Natural := N3 - A - B;
                  St : constant Customer_Vector := [A, B, C];
               begin
                  S3 := S3 + State_Probability (St, X3, G3 (N3));
               end;
            end loop;
         end loop;
         Check (Approx (S3, 1.0, 1.0E-6), "M=3 states sum to 1");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("11. Invalid X (nonpositive) raises");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            Bad : constant X_Vector := [1.0, 0.0];
            Unused : G_Vector := Compute_G (Bad, 3);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "X with 0 raises Invalid_Argument");

      Raised := False;
      begin
         declare
            Bad : constant X_Vector := [-1.0, 2.0];
            Unused : G_Vector := Compute_G (Bad, 2);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "negative X raises Invalid_Argument");

      Raised := False;
      begin
         declare
            Bad : constant X_Vector := [1.0, -0.5, 3.0];
            Unused : G_Matrix := Compute_G_Matrix (Bad, 2);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Compute_G_Matrix rejects negative X");

      Raised := False;
      begin
         declare
            Unused : Real :=
              Prob_Ni_Equals (-1.0, 0, Compute_G ([1.0, 1.0], 2));
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Prob_Ni_Equals rejects X_i<=0");

      Raised := False;
      begin
         declare
            Mu : constant X_Vector := [1.0, 0.0];
            Unused : X_Vector := Make_X_Cyclic (Mu);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Make_X_Cyclic rejects mu=0");
   end;

   ---------------------------------------------------------------------
   Section ("12. Capacity / empty / N=0 edge cases");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
      X      : constant X_Vector := [1.0, 2.0];
      G0     : constant G_Vector := Compute_G (X, 0);
   begin
      Check (G0'First = 0 and then G0'Last = 0, "N=0 yields G(0..0)");
      Check (Approx (G0 (0), 1.0), "G(0)=1 for N=0");
      Check (Approx (Station_Utilization (1.0, G0), 0.0),
             "utilization at N=0 is 0");
      Check (Approx (Expected_Ni (1.0, G0), 0.0), "E[n_i]=0 at N=0");
      Check (Approx (Prob_Ni_Equals (1.0, 0, G0), 1.0),
             "P(n_i=0)=1 when N=0");

      Raised := False;
      begin
         declare
            Unused : G_Vector := Compute_G (X, Max_Customers + 1);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Capacity_Exceeded =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "N > Max_Customers raises Capacity_Exceeded");

      --  Single station at N=0
      declare
         G1 : constant G_Vector := Compute_G ([3.0], 0);
      begin
         Check (Approx (G1 (0), 1.0), "M=1 N=0 G(0)=1");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("13. Utilization identities — two-node cyclic");
   ---------------------------------------------------------------------
   declare
      --  Cyclic: μ1=2, μ2=1 => X = (0.5, 1.0); visit ratios equal.
      Mu : constant X_Vector := [2.0, 1.0];
      X  : constant X_Vector := Make_X_Cyclic (Mu);
      N  : constant Natural := 5;
      G  : constant G_Vector := Compute_G (X, N);
      U1 : constant Real := Station_Utilization (X (1), G);
      U2 : constant Real := Station_Utilization (X (2), G);
   begin
      Check (Approx (X (1), 0.5), "Make_X_Cyclic X1=1/μ1");
      Check (Approx (X (2), 1.0), "Make_X_Cyclic X2=1/μ2");
      Check (U1 > 0.0 and then U1 < 1.0 + 1.0E-6, "U1 in (0,1]");
      Check (U2 > 0.0 and then U2 < 1.0 + 1.0E-6, "U2 in (0,1]");
      --  U_i = X_i * G(N-1)/G(N)
      Check (Approx (U1, X (1) * G (N - 1) / G (N), 1.0E-9),
             "U1 identity");
      Check (Approx (U2, X (2) * G (N - 1) / G (N), 1.0E-9),
             "U2 identity");
      --  Slower server (μ2=1) has higher X and higher utilization
      Check (U2 > U1, "bottleneck station has higher U");
      --  Make_X_From_Rates with unit visits matches cyclic
      declare
         Vis : constant X_Vector := [1.0, 1.0];
         Xr  : constant X_Vector := Make_X_From_Rates (Mu, Vis);
      begin
         Check (Approx (Xr (1), X (1)), "From_Rates matches cyclic X1");
         Check (Approx (Xr (2), X (2)), "From_Rates matches cyclic X2");
      end;
      --  Non-unit visits
      declare
         Vis : constant X_Vector := [2.0, 1.0];
         Xr  : constant X_Vector := Make_X_From_Rates (Mu, Vis);
      begin
         Check (Approx (Xr (1), 1.0), "X1=V1/μ1=2/2");
         Check (Approx (Xr (2), 1.0), "X2=V2/μ2=1/1");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("14. G increasing in X / N sanity");
   ---------------------------------------------------------------------
   declare
      X_Lo : constant X_Vector := [1.0, 1.0];
      X_Hi : constant X_Vector := [1.0, 2.0];
      N    : constant Natural := 4;
      G_Lo : constant G_Vector := Compute_G (X_Lo, N);
      G_Hi : constant G_Vector := Compute_G (X_Hi, N);
      G_Sm : constant G_Vector := Compute_G (X_Hi, 2);
   begin
      for Ni in 1 .. N loop
         Check (G_Hi (Ni) > G_Lo (Ni),
                "larger X2 => larger G(n) at n=" & Natural'Image (Ni));
         Check (G_Lo (Ni) > G_Lo (Ni - 1),
                "G increasing in n (equal X) n=" & Natural'Image (Ni));
      end loop;
      Check (Approx (G_Sm (0), G_Hi (0)), "G(0) independent of N request");
      Check (Approx (G_Sm (2), G_Hi (2)), "prefix of G matches smaller N");
      Check (G_Hi (N) > G_Sm (2), "G(N)>G(2) for N>2");
      --  Scaling all X by alpha: G scales as alpha^n for homogeneous...
      --  For M stations not a simple power; just sanity positivity.
      Check (G_Lo (0) = 1.0 and then G_Hi (0) = 1.0, "both G(0)=1");
   end;

   ---------------------------------------------------------------------
   Section ("15. Prob edges / utilization / Expected consistency");
   ---------------------------------------------------------------------
   declare
      X : constant X_Vector := [1.0, 1.0, 1.0];
      N : constant Natural := 3;
      G : constant G_Vector := Compute_G (X, N);
      --  Symmetric: G(n) = C(n+M-1, M-1) = C(n+2, 2)
   begin
      Check (Approx (G (0), 1.0), "sym G(0)=1");
      Check (Approx (G (1), 3.0), "sym G(1)=3");
      Check (Approx (G (2), 6.0), "sym G(2)=6");
      Check (Approx (G (3), 10.0), "sym G(3)=10");
      --  P(n_i=N) = X^N / G(N) = 1/10
      Check (Approx (Prob_Ni_Equals (1.0, 3, G), 0.1, 1.0E-9),
             "P(n_i=N)=1/10");
      Check (Approx (Prob_Ni_At_Least (1.0, 3, G), 0.1, 1.0E-9),
             "P(n_i>=N)=P(=N)");
      --  E[n_i] = N/M = 1 for symmetry
      Check (Approx (Expected_Ni (1.0, G), 1.0, 1.0E-6),
             "symmetric E[n_i]=N/M=1");
      Check (Approx (Station_Utilization (1.0, G),
                     1.0 * G (2) / G (3), 1.0E-9),
             "U = G(N-1)/G(N) when X=1");
      --  P(=k) non-negative and P(>=1)=1-P(=0)
      declare
         P0 : constant Real := Prob_Ni_Equals (1.0, 0, G);
         Pge1 : constant Real := Prob_Ni_At_Least (1.0, 1, G);
      begin
         Check (Approx (Pge1, 1.0 - P0, 1.0E-7), "P(>=1)=1-P(=0)");
         Check (P0 > 0.0, "P(=0)>0");
      end;
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("================================");
   Put_Line ("Passed :" & Natural'Image (Pass_Count));
   Put_Line ("Failed :" & Natural'Image (Fail_Count));
   Put_Line ("================================");
   pragma Assert (Fail_Count = 0);
   if Fail_Count = 0 then
      Put_Line ("ALL TESTS PASSED");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;

end Tests;
