with Ada.Text_IO; use Ada.Text_IO;
with Black_Scholes; use Black_Scholes;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   Tol : constant := 1.0E-4;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   procedure Check_Float (Label : String; Actual, Expected, Tolerance : Long_Float) is
      OK : constant Boolean := abs (Actual - Expected) <= Tolerance;
   begin
      Check (Label, OK);
      if not OK then
         Put_Line ("      Actual: " & Long_Float'Image (Actual) & " Expected: " & Long_Float'Image (Expected));
      end if;
   end Check_Float;

   -- Helper to invoke calls with default parameters nicely
   function CPrice (S, K : Long_Float; Q : Long_Float := 0.0) return Long_Float is
   begin
      return Long_Float (Call_Price (Positive_Money (S), Positive_Money (K), 1.0, 0.05, 0.2, Yield (Q)));
   end CPrice;

   function PPrice (S, K : Long_Float; Q : Long_Float := 0.0) return Long_Float is
   begin
      return Long_Float (Put_Price (Positive_Money (S), Positive_Money (K), 1.0, 0.05, 0.2, Yield (Q)));
   end PPrice;

begin
   -- TEST 1 — Call Option Price
   Put_Line ("TEST 1 — Call Option Price");
   Check_Float ("1.1 Call ATM (S=100, K=100)", CPrice (100.0, 100.0), 10.4506, Tol);
   Check_Float ("1.2 Call ITM (S=110, K=100)", CPrice (110.0, 100.0), 17.6630, Tol);
   Check_Float ("1.3 Call OTM (S=90,  K=100)", CPrice (90.0,  100.0), 5.0912,  Tol);

   -- TEST 2 — Put Option Price
   Put_Line ("TEST 2 — Put Option Price");
   Check_Float ("2.1 Put ATM (S=100, K=100)", PPrice (100.0, 100.0), 5.5735, Tol);
   Check_Float ("2.2 Put ITM (S=90,  K=100)", PPrice (90.0,  100.0), 10.2142, Tol);
   Check_Float ("2.3 Put OTM (S=110, K=100)", PPrice (110.0, 100.0), 2.7859, Tol);

   -- TEST 3 — Dividend Yield Impact (Merton Model Extension)
   Put_Line ("TEST 3 — Dividend Yield Impact (Q=0.03)");
   Check_Float ("3.1 Call with Yield Q=0.03", CPrice (100.0, 100.0, 0.03), 8.6525, Tol);
   Check_Float ("3.2 Put with Yield Q=0.03",  PPrice (100.0, 100.0, 0.03), 6.7309, Tol);
   Check_Float ("3.3 Modified Parity Diff", CPrice (100.0, 100.0, 0.03) - PPrice (100.0, 100.0, 0.03), 1.9216, Tol);

   -- TEST 4 — Call Delta
   Put_Line ("TEST 4 — Call Delta");
   declare
      D_ATM : constant Long_Float := Long_Float (Call_Delta (100.0, 100.0, 1.0, 0.05, 0.2));
      D_ITM : constant Long_Float := Long_Float (Call_Delta (110.0, 100.0, 1.0, 0.05, 0.2));
      D_OTM : constant Long_Float := Long_Float (Call_Delta (90.0,  100.0, 1.0, 0.05, 0.2));
   begin
      Check_Float ("4.1 Call Delta ATM", D_ATM, 0.6368, Tol);
      Check ("4.2 Call Delta ITM > ATM", D_ITM > D_ATM);
      Check ("4.3 Call Delta limits", D_OTM > 0.0 and then D_ITM < 1.0);
   end;

   -- TEST 5 — Put Delta
   Put_Line ("TEST 5 — Put Delta");
   declare
      D_ATM : constant Long_Float := Long_Float (Put_Delta (100.0, 100.0, 1.0, 0.05, 0.2));
      D_ITM : constant Long_Float := Long_Float (Put_Delta (90.0,  100.0, 1.0, 0.05, 0.2));
      D_OTM : constant Long_Float := Long_Float (Put_Delta (110.0, 100.0, 1.0, 0.05, 0.2));
   begin
      Check_Float ("5.1 Put Delta ATM", D_ATM, -0.3632, Tol);
      Check ("5.2 Put Delta ITM is more negative", D_ITM < D_ATM);
      Check ("5.3 Put Delta limits", D_OTM < 0.0 and then D_ITM > -1.0);
   end;

   -- TEST 6 — Gamma
   Put_Line ("TEST 6 — Gamma");
   declare
      G_Call : constant Long_Float := Long_Float (Gamma (100.0, 100.0, 1.0, 0.05, 0.2));
      G_Put  : constant Long_Float := Long_Float (Gamma (100.0, 100.0, 1.0, 0.05, 0.2));
      G_ITM  : constant Long_Float := Long_Float (Gamma (110.0, 100.0, 1.0, 0.05, 0.2));
   begin
      Check_Float ("6.1 Gamma Value", G_Call, 0.0188, Tol);
      Check_Float ("6.2 Gamma Call equals Put", G_Call, G_Put, 1.0E-9);
      Check ("6.3 Gamma peaks ATM", G_Call > G_ITM);
   end;

   -- TEST 7 — Vega
   Put_Line ("TEST 7 — Vega");
   declare
      V_Call : constant Long_Float := Long_Float (Vega (100.0, 100.0, 1.0, 0.05, 0.2));
      V_Put  : constant Long_Float := Long_Float (Vega (100.0, 100.0, 1.0, 0.05, 0.2));
      V_ITM  : constant Long_Float := Long_Float (Vega (110.0, 100.0, 1.0, 0.05, 0.2));
   begin
      Check_Float ("7.1 Vega Value", V_Call, 37.5240, Tol);
      Check_Float ("7.2 Vega Call equals Put", V_Call, V_Put, 1.0E-9);
      Check ("7.3 Vega is positive and drops away from ATM", V_Call > 0.0 and then V_Call > V_ITM);
   end;

   -- TEST 8 — Call Theta
   Put_Line ("TEST 8 — Call Theta");
   declare
      T_ATM : constant Long_Float := Long_Float (Call_Theta (100.0, 100.0, 1.0, 0.05, 0.2));
      T_ITM : constant Long_Float := Long_Float (Call_Theta (110.0, 100.0, 1.0, 0.05, 0.2));
      T_OTM : constant Long_Float := Long_Float (Call_Theta (90.0,  100.0, 1.0, 0.05, 0.2));
   begin
      Check_Float ("8.1 Call Theta ATM", T_ATM, -6.4140, Tol);
      Check ("8.2 Call Theta is negative", T_ATM < 0.0 and then T_ITM < 0.0);
      Check ("8.3 Call Theta differs from OTM", abs (T_ATM - T_OTM) > 0.5);
   end;

   -- TEST 9 — Put Theta
   Put_Line ("TEST 9 — Put Theta");
   declare
      TP_ATM : constant Long_Float := Long_Float (Put_Theta (100.0, 100.0, 1.0, 0.05, 0.2));
      TC_ATM : constant Long_Float := Long_Float (Call_Theta (100.0, 100.0, 1.0, 0.05, 0.2));
      TP_OTM : constant Long_Float := Long_Float (Put_Theta (110.0, 100.0, 1.0, 0.05, 0.2));
   begin
      Check_Float ("9.1 Put Theta ATM", TP_ATM, -1.6579, Tol);
      Check ("9.2 Put Theta generally > Call Theta", TP_ATM > TC_ATM);
      Check ("9.3 Put Theta is negative", TP_OTM < 0.0);
   end;

   -- TEST 10 — Rho
   Put_Line ("TEST 10 — Rho");
   declare
      R_Call : constant Long_Float := Long_Float (Call_Rho (100.0, 100.0, 1.0, 0.05, 0.2));
      R_Put  : constant Long_Float := Long_Float (Put_Rho  (100.0, 100.0, 1.0, 0.05, 0.2));
   begin
      Check_Float ("10.1 Call Rho Value", R_Call, 53.2325, Tol);
      Check_Float ("10.2 Put Rho Value", R_Put, -41.8905, Tol);
      Check ("10.3 Call Rho > 0, Put Rho < 0", R_Call > 0.0 and then R_Put < 0.0);
   end;

   -- TEST 11 — Put-Call Parity Relations
   Put_Line ("TEST 11 — Put-Call Parity");
   declare
      C1 : constant Long_Float := CPrice (100.0, 100.0);
      P1 : constant Long_Float := PPrice (100.0, 100.0);
      C2 : constant Long_Float := CPrice (110.0, 100.0);
      P2 : constant Long_Float := PPrice (110.0, 100.0);
      C3 : constant Long_Float := CPrice (90.0,  100.0);
      P3 : constant Long_Float := PPrice (90.0,  100.0);
   begin
      Check_Float ("11.1 Parity ATM", C1 - P1, 4.8771, Tol);
      Check_Float ("11.2 Parity ITM Call", C2 - P2, 14.8771, Tol);
      Check_Float ("11.3 Parity OTM Call", C3 - P3, -5.1229, Tol);
   end;

   -- TEST 12 — Expiration (Time to Maturity = 0)
   Put_Line ("TEST 12 — Expiration Values (T=0)");
   declare
      C_ITM : constant Long_Float := Long_Float (Call_Price (110.0, 100.0, 0.0, 0.05, 0.2));
      C_OTM : constant Long_Float := Long_Float (Call_Price (90.0,  100.0, 0.0, 0.05, 0.2));
      P_ITM : constant Long_Float := Long_Float (Put_Price  (90.0,  100.0, 0.0, 0.05, 0.2));
   begin
      Check_Float ("12.1 Call ITM at Expiration", C_ITM, 10.0, 1.0E-9);
      Check_Float ("12.2 Call OTM at Expiration", C_OTM, 0.0, 1.0E-9);
      Check_Float ("12.3 Put ITM at Expiration", P_ITM, 10.0, 1.0E-9);
   end;

   -- TEST 13 — Exception Handling at Expiration
   Put_Line ("TEST 13 — Exceptions (T=0)");
   declare
      Caught_Delta, Caught_Gamma, Caught_Vega : Boolean := False;
   begin
      begin
         if Long_Float (Call_Delta (100.0, 100.0, 0.0, 0.05, 0.2)) = 0.0 then null; end if;
      exception
         when Maturity_Expired => Caught_Delta := True;
      end;
      
      begin
         if Long_Float (Gamma (100.0, 100.0, 0.0, 0.05, 0.2)) = 0.0 then null; end if;
      exception
         when Maturity_Expired => Caught_Gamma := True;
      end;
      
      begin
         if Long_Float (Vega (100.0, 100.0, 0.0, 0.05, 0.2)) = 0.0 then null; end if;
      exception
         when Maturity_Expired => Caught_Vega := True;
      end;

      Check ("13.1 Delta at T=0 raises Maturity_Expired", Caught_Delta);
      Check ("13.2 Gamma at T=0 raises Maturity_Expired", Caught_Gamma);
      Check ("13.3 Vega at T=0 raises Maturity_Expired", Caught_Vega);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
