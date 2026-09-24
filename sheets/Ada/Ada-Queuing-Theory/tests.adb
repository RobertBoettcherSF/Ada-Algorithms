--  Standalone test suite for Queuing_Theory (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Queuing_Theory; use Queuing_Theory;

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

begin
   Put_Line ("Queuing_Theory test suite");
   Put_Line ("=========================");

   ---------------------------------------------------------------------
   Section ("1. Near / Power / Factorial_Real helpers");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Near (1.0, 1.0 + 1.0E-9), "Near accepts tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 0.0), "Near(0,0)");
      Check (Approx (Power (2.0, 0), 1.0), "Power(_,0)=1");
      Check (Approx (Power (2.0, 3), 8.0), "Power(2,3)=8");
      Check (Approx (Power (0.5, 2), 0.25), "Power(0.5,2)=0.25");
      Check (Approx (Factorial_Real (0), 1.0), "0!=1");
      Check (Approx (Factorial_Real (1), 1.0), "1!=1");
      Check (Approx (Factorial_Real (5), 120.0), "5!=120");
      Check (Approx (Factorial_Real (10), 3_628_800.0), "10!=3628800");
   end;

   ---------------------------------------------------------------------
   Section ("2. Little's law identities");
   ---------------------------------------------------------------------
   declare
      Lam : constant Real := 2.5;
      W   : constant Real := 4.0;
      L   : constant Real := Littles_L (Lam, W);
   begin
      Check (Approx (L, 10.0), "L=λW => 2.5*4=10");
      Check (Approx (Littles_W (L, Lam), W), "W=L/λ recovers W");
      Check (Approx (Littles_Lambda (L, W), Lam), "λ=L/W recovers λ");
      Check (Approx (Littles_L (1.0, 0.0), 0.0), "L=λ*0=0");
      Check (Approx (Littles_W (0.0, 3.0), 0.0), "W=0/λ=0");
      begin
         declare
            Ign : Real := Littles_L (-1.0, 1.0);
            pragma Unreferenced (Ign);
         begin
            Check (False, "Littles_L neg λ should raise");
         end;
      exception
         when Invalid_Argument =>
            Check (True, "Littles_L neg λ raises Invalid_Argument");
      end;
      begin
         declare
            Ign : Real := Littles_W (1.0, 0.0);
            pragma Unreferenced (Ign);
         begin
            Check (False, "Littles_W λ=0 should raise");
         end;
      exception
         when Invalid_Argument =>
            Check (True, "Littles_W λ=0 raises Invalid_Argument");
      end;
      begin
         declare
            Ign : Real := Littles_Lambda (1.0, 0.0);
            pragma Unreferenced (Ign);
         begin
            Check (False, "Littles_Lambda W=0 should raise");
         end;
      exception
         when Invalid_Argument =>
            Check (True, "Littles_Lambda W=0 raises Invalid_Argument");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("3. Kendall notation Format / Parse");
   ---------------------------------------------------------------------
   declare
      S1 : constant String := Format_Kendall ("M", "M", 1);
      S2 : constant String := Format_Kendall ("M", "M", 2, K => 10);
      S3 : constant String := Format_Kendall ("M", "G", 3, K => 20, N => 50);
      S4 : constant String := Format_Kendall (M, M, 1);
      S5 : constant String := Format_Kendall (M, D, 5, K => 100);
   begin
      Check (S1 = "M/M/1", "Format M/M/1");
      Check (S2 = "M/M/2/10", "Format M/M/2/10");
      Check (S3 = "M/G/3/20/50", "Format M/G/3/20/50");
      Check (S4 = "M/M/1", "Enum Format M/M/1");
      Check (S5 = "M/D/5/100", "Enum Format M/D/5/100");
      Check (Parse_Kendall_Servers ("M/M/1") = 1, "Parse c=1");
      Check (Parse_Kendall_Servers ("M/M/c") = 0, "Parse non-numeric c => 0");
      Check (Parse_Kendall_Servers ("M/M/8/100") = 8, "Parse c=8 with K");
      Check (Parse_Kendall_Servers ("") = 0, "Parse empty => 0");
      begin
         declare
            Ign : constant String := Format_Kendall ("", "M", 1);
            pragma Unreferenced (Ign);
         begin
            Check (False, "empty A should raise");
         end;
      exception
         when Invalid_Argument =>
            Check (True, "empty A raises Invalid_Argument");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("4. Traffic intensity Rho / stability");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Approx (Rho (1.0, 2.0), 0.5), "Rho(1,2)=0.5");
      Check (Approx (Rho (2.0, 2.0, 2), 0.5), "Rho(2,2,c=2)=0.5");
      Check (Approx (Rho (0.0, 5.0), 0.0), "Rho(0,μ)=0");
      Check (Is_Stable_MM1 (1.0, 2.0), "stable MM1 λ=1 μ=2");
      Check (not Is_Stable_MM1 (2.0, 2.0), "unstable MM1 ρ=1");
      Check (not Is_Stable_MM1 (3.0, 2.0), "unstable MM1 ρ>1");
      Check (Is_Stable_MMc (3.0, 2.0, 2), "stable MMc λ=3 μ=2 c=2");
      Check (not Is_Stable_MMc (5.0, 2.0, 2), "unstable MMc");
      begin
         declare
            Ign : Real := Rho (1.0, 0.0);
            pragma Unreferenced (Ign);
         begin
            Check (False, "Rho μ=0 should raise");
         end;
      exception
         when Invalid_Argument =>
            Check (True, "Rho μ=0 raises Invalid_Argument");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("5. M/M/1 classic fixture λ=1 μ=2");
   ---------------------------------------------------------------------
   declare
      Lam : constant Real := 1.0;
      Mu  : constant Real := 2.0;
      R   : constant MM1_Result := Analyze_MM1 (Lam, Mu);
      Sum_P : Real := 0.0;
   begin
      Check (Approx (R.Rho, 0.5), "ρ=0.5");
      Check (Approx (R.P0, 0.5), "P0=1-ρ=0.5");
      Check (Approx (R.L, 1.0), "L=ρ/(1-ρ)=1");
      Check (Approx (R.Lq, 0.5), "Lq=ρ²/(1-ρ)=0.5");
      Check (Approx (R.W, 1.0), "W=1/(μ-λ)=1");
      Check (Approx (R.Wq, 0.5), "Wq=λ/(μ(μ-λ))=0.5");
      Check (Approx (R.Utilization, 0.5), "U=ρ=0.5");
      Check (Approx (MM1_Pn (Lam, Mu, 0), 0.5), "P0 via MM1_Pn");
      Check (Approx (MM1_Pn (Lam, Mu, 1), 0.25), "P1=(1-ρ)ρ");
      Check (Approx (MM1_Pn (Lam, Mu, 2), 0.125), "P2=(1-ρ)ρ²");
      for N in 0 .. 40 loop
         Sum_P := Sum_P + MM1_Pn (Lam, Mu, N);
      end loop;
      Check (Approx (Sum_P, 1.0, 1.0E-9), "Σ Pn ≈ 1 (n=0..40)");
      Check (Approx (R.L, Littles_L (Lam, R.W)), "Little: L=λW");
      Check (Approx (R.Lq, Littles_L (Lam, R.Wq)), "Little: Lq=λWq");
   end;

   ---------------------------------------------------------------------
   Section ("6. M/M/1 second fixture + component API");
   ---------------------------------------------------------------------
   declare
      Lam : constant Real := 3.0;
      Mu  : constant Real := 5.0;
      R   : constant Real := Lam / Mu;  -- 0.6
   begin
      Check (Approx (MM1_P0 (Lam, Mu), 1.0 - R), "P0=1-ρ");
      Check (Approx (MM1_L (Lam, Mu), R / (1.0 - R)), "L formula");
      Check (Approx (MM1_Lq (Lam, Mu), (R * R) / (1.0 - R)), "Lq formula");
      Check (Approx (MM1_W (Lam, Mu), 1.0 / (Mu - Lam)), "W formula");
      Check (Approx (MM1_Wq (Lam, Mu), Lam / (Mu * (Mu - Lam))), "Wq formula");
      Check (Approx (MM1_Utilization (Lam, Mu), R), "U=ρ");
      Check (Approx (MM1_L (Lam, Mu), Lam * MM1_W (Lam, Mu)), "L=λW check");
      Check (Approx (MM1_L (Lam, Mu) - MM1_Lq (Lam, Mu), R, 1.0E-9),
             "L-Lq=ρ (busy servers)");
   end;

   ---------------------------------------------------------------------
   Section ("7. M/M/1 unstable raises Degenerate_Geometry");
   ---------------------------------------------------------------------
   declare
   begin
      begin
         declare
            Ign : Real := MM1_L (2.0, 2.0);
            pragma Unreferenced (Ign);
         begin
            Check (False, "ρ=1 should raise");
         end;
      exception
         when Degenerate_Geometry =>
            Check (True, "ρ=1 raises Degenerate_Geometry");
      end;
      begin
         declare
            Ign : Real := MM1_W (5.0, 3.0);
            pragma Unreferenced (Ign);
         begin
            Check (False, "ρ>1 should raise");
         end;
      exception
         when Degenerate_Geometry =>
            Check (True, "ρ>1 raises Degenerate_Geometry");
      end;
      begin
         declare
            Ign : MM1_Result := Analyze_MM1 (1.0, 0.5);
            pragma Unreferenced (Ign);
         begin
            Check (False, "Analyze unstable should raise");
         end;
      exception
         when Degenerate_Geometry =>
            Check (True, "Analyze_MM1 unstable raises");
      end;
      begin
         declare
            Ign : Real := MM1_P0 (-1.0, 2.0);
            pragma Unreferenced (Ign);
         begin
            Check (False, "neg λ should raise");
         end;
      exception
         when Invalid_Argument =>
            Check (True, "neg λ raises Invalid_Argument");
         when Degenerate_Geometry =>
            Check (True, "neg λ raises (degenerate path ok)");
      end;
      Check (not Is_Stable_MM1 (1.0, 1.0), "Is_Stable false at ρ=1");
   end;

   ---------------------------------------------------------------------
   Section ("8. M/M/c reduces to M/M/1 when c=1");
   ---------------------------------------------------------------------
   declare
      Lam : constant Real := 1.0;
      Mu  : constant Real := 2.0;
      R1  : constant MM1_Result := Analyze_MM1 (Lam, Mu);
      Rc  : constant MMc_Result := Analyze_MMc (Lam, Mu, 1);
   begin
      Check (Approx (Rc.P0, R1.P0, 1.0E-9), "MMc c=1 P0 = MM1 P0");
      Check (Approx (Rc.L, R1.L, 1.0E-9), "MMc c=1 L = MM1 L");
      Check (Approx (Rc.Lq, R1.Lq, 1.0E-9), "MMc c=1 Lq = MM1 Lq");
      Check (Approx (Rc.W, R1.W, 1.0E-9), "MMc c=1 W = MM1 W");
      Check (Approx (Rc.Wq, R1.Wq, 1.0E-9), "MMc c=1 Wq = MM1 Wq");
      Check (Approx (Rc.Erlang_C, R1.Rho, 1.0E-9),
             "Erlang-C c=1 equals ρ");
      Check (Approx (Rc.Utilization, R1.Utilization, 1.0E-9), "U match");
      Check (Rc.Servers = 1, "Servers=1");
   end;

   ---------------------------------------------------------------------
   Section ("9. M/M/c multi-server fixture");
   ---------------------------------------------------------------------
   declare
      --  λ=5, μ=3, c=2 => a=5/3≈1.667, ρ=5/6≈0.833
      Lam : constant Real := 5.0;
      Mu  : constant Real := 3.0;
      C   : constant Server_Count := 2;
      Res : constant MMc_Result := Analyze_MMc (Lam, Mu, C);
      --  Manual: P0 = 1 / (1 + a + a^2/(2(1-ρ)))
      A   : constant Real := Lam / Mu;
      R   : constant Real := Lam / (Real (C) * Mu);
      P0_Manual : constant Real :=
        1.0 / (1.0 + A + (A * A) / (2.0 * (1.0 - R)));
      EC_Manual : constant Real :=
        ((A * A) / (2.0 * (1.0 - R))) * P0_Manual;
   begin
      Check (Approx (Res.A, A, 1.0E-9), "offered load a=λ/μ");
      Check (Approx (Res.Rho, R, 1.0E-9), "ρ=λ/(cμ)");
      Check (Approx (Res.P0, P0_Manual, 1.0E-8), "P0 matches hand calc");
      Check (Approx (Res.Erlang_C, EC_Manual, 1.0E-8), "Erlang-C hand calc");
      Check (Approx (Res.Lq, EC_Manual * R / (1.0 - R), 1.0E-8), "Lq");
      Check (Approx (Res.L, Res.Lq + A, 1.0E-9), "L=Lq+a");
      Check (Approx (Res.W, Res.L / Lam, 1.0E-9), "W=L/λ");
      Check (Approx (Res.Wq, Res.Lq / Lam, 1.0E-9), "Wq=Lq/λ");
      Check (Res.P0 > 0.0 and then Res.P0 < 1.0, "P0 in (0,1)");
      Check (Res.Erlang_C > 0.0 and then Res.Erlang_C < 1.0,
             "Erlang-C in (0,1)");
      Check (Approx (MMc_P0 (Lam, Mu, C), Res.P0), "MMc_P0 matches");
      Check (Approx (MMc_Erlang_C (Lam, Mu, C), Res.Erlang_C),
             "MMc_Erlang_C matches");
   end;

   ---------------------------------------------------------------------
   Section ("10. M/M/c unstable / more servers lower wait");
   ---------------------------------------------------------------------
   declare
      Lam : constant Real := 4.0;
      Mu  : constant Real := 3.0;
      W2  : constant Real := MMc_W (Lam, Mu, 2);
      W3  : constant Real := MMc_W (Lam, Mu, 3);
   begin
      Check (W3 < W2, "more servers => smaller W");
      Check (MMc_Lq (Lam, Mu, 3) < MMc_Lq (Lam, Mu, 2),
             "more servers => smaller Lq");
      begin
         declare
            Ign : Real := MMc_L (6.0, 2.0, 2);  -- ρ=6/4=1.5
            pragma Unreferenced (Ign);
         begin
            Check (False, "unstable MMc should raise");
         end;
      exception
         when Degenerate_Geometry =>
            Check (True, "unstable MMc raises Degenerate_Geometry");
      end;
      begin
         declare
            Ign : Real := MMc_Erlang_C (4.0, 2.0, 2);  -- ρ=1
            pragma Unreferenced (Ign);
         begin
            Check (False, "ρ=1 MMc should raise");
         end;
      exception
         when Degenerate_Geometry =>
            Check (True, "ρ=1 MMc raises Degenerate_Geometry");
      end;
      Check (not Is_Stable_MMc (4.0, 2.0, 2), "Is_Stable_MMc false at ρ=1");
   end;

   ---------------------------------------------------------------------
   Section ("11. M/M/1/K truncated geometric + blocking");
   ---------------------------------------------------------------------
   declare
      Lam : constant Real := 1.0;
      Mu  : constant Real := 2.0;
      K   : constant Capacity_Count := 5;
      Res : constant MM1K_Result := Analyze_MM1K (Lam, Mu, K);
      Sum_P : Real := 0.0;
   begin
      Check (Approx (Res.Rho, 0.5), "MM1K ρ=0.5");
      Check (Res.P_Block = MM1K_Pn (Lam, Mu, K, Natural (K)),
             "P_Block = PK");
      Check (Res.P_Block > 0.0 and then Res.P_Block < Res.P0,
             "PK < P0 for ρ<1");
      Check (Approx (Res.Lambda_Eff, Lam * (1.0 - Res.P_Block), 1.0E-12),
             "λ_eff=λ(1-PK)");
      for N in 0 .. Natural (K) loop
         Sum_P := Sum_P + MM1K_Pn (Lam, Mu, K, N);
      end loop;
      Check (Approx (Sum_P, 1.0, 1.0E-9), "Σ Pn = 1 over 0..K");
      Check (Approx (Res.L, MM1K_L (Lam, Mu, K)), "L matches");
      Check (Approx (Res.W, Res.L / Res.Lambda_Eff, 1.0E-9), "W=L/λ_eff");
      Check (Approx (Res.Lq, Res.L - (1.0 - Res.P0), 1.0E-9),
             "Lq=L-(1-P0)");
      Check (Res.Utilization = 1.0 - Res.P0, "U=1-P0");
      Check (Res.Capacity = K, "Capacity field");
      --  ρ=1 special case
      declare
         R1 : constant MM1K_Result := Analyze_MM1K (2.0, 2.0, 4);
      begin
         Check (Approx (R1.P0, 0.2), "ρ=1: Pn=1/(K+1)=0.2");
         Check (Approx (R1.P_Block, 0.2), "ρ=1: PK=1/(K+1)");
         Check (Approx (R1.L, 2.0), "ρ=1: L=K/2=2");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. M/M/1/K → M/M/1 as K large");
   ---------------------------------------------------------------------
   declare
      Lam : constant Real := 1.0;
      Mu  : constant Real := 2.0;
      Inf : constant MM1_Result := Analyze_MM1 (Lam, Mu);
      K10 : constant MM1K_Result := Analyze_MM1K (Lam, Mu, 10);
      K40 : constant MM1K_Result := Analyze_MM1K (Lam, Mu, 40);
   begin
      Check (Approx (K40.L, Inf.L, 1.0E-6), "K=40 L ≈ MM1 L");
      Check (Approx (K40.Lq, Inf.Lq, 1.0E-6), "K=40 Lq ≈ MM1 Lq");
      Check (Approx (K40.P0, Inf.P0, 1.0E-6), "K=40 P0 ≈ MM1 P0");
      Check (K40.P_Block < K10.P_Block, "larger K => smaller P_Block");
      Check (K40.P_Block < 1.0E-9, "K=40 P_Block tiny for ρ=0.5");
      Check (abs (K10.L - Inf.L) > abs (K40.L - Inf.L),
             "error shrinks with K");
      Check (Approx (K40.W, Inf.W, 1.0E-5), "K=40 W ≈ MM1 W");
      begin
         declare
            Ign : Real := MM1K_Pn (Lam, Mu, 5, 6);
            pragma Unreferenced (Ign);
         begin
            Check (False, "N>K should raise");
         end;
      exception
         when Invalid_Argument =>
            Check (True, "N>K raises Invalid_Argument");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("13. Birth–death local balance");
   ---------------------------------------------------------------------
   declare
      Lam : constant Real := 1.0;
      Mu  : constant Real := 2.0;
   begin
      Check (MM1_Local_Balance_Holds (Lam, Mu, 1), "balance n=1");
      Check (MM1_Local_Balance_Holds (Lam, Mu, 2), "balance n=2");
      Check (MM1_Local_Balance_Holds (Lam, Mu, 5), "balance n=5");
      Check (MM1_Local_Balance_Holds (Lam, Mu, 10), "balance n=10");
      Check (not MM1_Local_Balance_Holds (3.0, 2.0, 1),
             "unstable => balance False");
      Check (Approx (Birth_Death_Pn_Product (Lam, Mu, 0), 1.0),
             "Pn/P0 product n=0 => 1");
      Check (Approx (Birth_Death_Pn_Product (Lam, Mu, 3), Power (0.5, 3)),
             "Pn/P0 = ρ^n");
      --  Explicit μ Pn = λ P_{n-1}
      declare
         N   : constant Positive := 4;
         Pn  : constant Real := MM1_Pn (Lam, Mu, N);
         Pn1 : constant Real := MM1_Pn (Lam, Mu, N - 1);
      begin
         Check (Approx (Mu * Pn, Lam * Pn1, 1.0E-10),
                "explicit μPn = λP(n-1)");
         Check (Approx (Pn / Pn1, Lam / Mu, 1.0E-10), "Pn/P(n-1)=ρ");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("14. M/M/∞ Poisson / infinite servers");
   ---------------------------------------------------------------------
   declare
      Lam : constant Real := 2.0;
      Mu  : constant Real := 4.0;
      Res : constant MM_Inf_Result := Analyze_MM_Inf (Lam, Mu);
      Sum_P : Real := 0.0;
   begin
      Check (Approx (Res.Rho, 0.5), "M/M/∞ ρ=0.5");
      Check (Approx (Res.L, 0.5), "L=λ/μ");
      Check (Approx (Res.W, 0.25), "W=1/μ");
      Check (Approx (MM_Inf_L (Lam, Mu), Res.L), "MM_Inf_L");
      Check (Approx (MM_Inf_W (Lam, Mu), Res.W), "MM_Inf_W");
      Check (Approx (Littles_L (Lam, Res.W), Res.L), "Little on M/M/∞");
      --  Poisson probs sum
      for N in 0 .. 30 loop
         Sum_P := Sum_P + MM_Inf_Pn (Lam, Mu, N);
      end loop;
      Check (Approx (Sum_P, 1.0, 1.0E-6), "Σ Poisson Pn ≈ 1");
      Check (Approx (MM_Inf_Pn (Lam, Mu, 0),
                     MM_Inf_Pn (1.0, 2.0, 0), 1.0E-6)
             or else Approx (MM_Inf_Pn (Lam, Mu, 0),
                             Real'(0.6065306597), 1.0E-5),
             "P0 = e^{-ρ} ≈ 0.6065");
      Check (MM_Inf_Pn (Lam, Mu, 0) > MM_Inf_Pn (Lam, Mu, 1),
             "mode at 0 when ρ<1");
   end;

   ---------------------------------------------------------------------
   Section ("15. Cross-model Little consistency / sanity");
   ---------------------------------------------------------------------
   declare
      Lam : constant Real := 1.5;
      Mu  : constant Real := 4.0;
      M1  : constant MM1_Result := Analyze_MM1 (Lam, Mu);
      Mc  : constant MMc_Result := Analyze_MMc (Lam, Mu, 3);
      Mk  : constant MM1K_Result := Analyze_MM1K (Lam, Mu, 20);
      Mi  : constant MM_Inf_Result := Analyze_MM_Inf (Lam, Mu);
   begin
      Check (Approx (M1.L, Lam * M1.W, 1.0E-9), "MM1 Little");
      Check (Approx (Mc.L, Lam * Mc.W, 1.0E-9), "MMc Little");
      Check (Approx (Mk.L, Mk.Lambda_Eff * Mk.W, 1.0E-9), "MM1K Little");
      Check (Approx (Mi.L, Lam * Mi.W, 1.0E-9), "MM∞ Little");
      Check (Mi.L < M1.L, "M/M/∞ L < M/M/1 L (same λ,μ)");
      Check (Mc.W < M1.W, "M/M/3 W < M/M/1 W");
      Check (Mk.L < M1.L or else Approx (Mk.L, M1.L, 1.0E-3),
             "finite K L ≤ infinite L");
      Check (Format_Kendall ("M", "M", 1) =
             Format_Kendall (M, M, 1), "string/enum Kendall agree");
      Check (Approx (Rho (Lam, Mu, 1), M1.Rho), "Rho helper vs MM1");
      Check (Approx (Rho (Lam, Mu, 3), Mc.Rho), "Rho helper vs MMc");
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
