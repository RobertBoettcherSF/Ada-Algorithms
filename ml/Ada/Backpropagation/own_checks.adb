pragma Ada_2022;
--  Own tests for Backpropagation (see tests/SOURCES.txt).
--  Forward and Backward against an own Long_Float forward pass and central finite differences of
--  E = 1/2 * sum (A2 - Target)**2 (the loss whose derivative Backward documents; Compute_Loss is the mean,
--  so Backward = N_Outputs / 2 * gradient of Compute_Loss, also checked).
with Ada.Environment_Variables;
with Ada.Numerics.Generic_Elementary_Functions;
with Ada.Text_IO; use Ada.Text_IO;
with Backpropagation; use Backpropagation;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := Long_Long_Integer (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & Long_Long_Integer'Image (S) & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed : Long_Long_Integer := AA_Seed (20261008);
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   package LM is new Ada.Numerics.Generic_Elementary_Functions (Long_Float);
   function Act (X : Long_Float; A : Activation_Function) return Long_Float is
     (case A is when Sigmoid => 1.0 / (1.0 + LM.Exp (-X)), when ReLU => Long_Float'Max (X, 0.0),
                when Tanh => LM.Tanh (X), when Linear => X);
   function R return Real is (Real (Next (-1000, 1000)) / 1000.0);
   function Close (A, B : Long_Float) return Boolean is (abs (A - B) <= 2.0E-3 + 2.0E-2 * abs (B));
begin
   for Run in 1 .. 400 loop
      declare
         NI : constant Positive := Next (1, 3);
         NH : constant Positive := Next (1, 4);
         NO : constant Positive := Next (1, 3);
         AF : constant Activation_Function := Activation_Function'Val (Next (0, 3));
         Net : Neural_Network (NI, NH, NO);
         St  : Network_State (NI, NH, NO);
         G   : Network_Gradients (NI, NH, NO);
         X   : Vector (1 .. NI);
         T   : Vector (1 .. NO);
         Kink : Boolean := False;
         W1 : array (1 .. NH, 1 .. NI) of Long_Float;
         B1 : array (1 .. NH) of Long_Float;
         W2 : array (1 .. NO, 1 .. NH) of Long_Float;
         B2 : array (1 .. NO) of Long_Float;
         Which : Natural := 0;   --  parameter number being perturbed, 0 = none
         Dlt   : Long_Float := 0.0;
         --  parameter numbers: B1 (J), W1 (J, K), B2 (I), W2 (I, J) in that order
         function Pb1 (J : Positive) return Long_Float is (B1 (J) + (if Which = J then Dlt else 0.0));
         function Pw1 (J, K : Positive) return Long_Float is
           (W1 (J, K) + (if Which = NH + (J - 1) * NI + K then Dlt else 0.0));
         function Pb2 (I : Positive) return Long_Float is
           (B2 (I) + (if Which = NH + NH * NI + I then Dlt else 0.0));
         function Pw2 (I, J : Positive) return Long_Float is
           (W2 (I, J) + (if Which = NH + NH * NI + NO + (I - 1) * NH + J then Dlt else 0.0));
         function E return Long_Float is   --  own forward pass, half sum of squares
            H : array (1 .. NH) of Long_Float;
            Z, S : Long_Float := 0.0;
         begin
            for J in 1 .. NH loop
               Z := Pb1 (J);
               for K in 1 .. NI loop Z := Z + Pw1 (J, K) * Long_Float (X (K)); end loop;
               if AF = ReLU and then abs Z < 0.05 then Kink := True; end if;
               H (J) := Act (Z, AF);
            end loop;
            for I in 1 .. NO loop
               Z := Pb2 (I);
               for J in 1 .. NH loop Z := Z + Pw2 (I, J) * H (J); end loop;
               if AF = ReLU and then abs Z < 0.05 then Kink := True; end if;
               S := S + (Act (Z, AF) - Long_Float (T (I)))**2;
            end loop;
            return S / 2.0;
         end E;
         function D (N : Positive) return Long_Float is   --  central difference in parameter N
            Up, Down : Long_Float;
         begin
            Which := N;
            Dlt := 1.0E-3; Up := E;
            Dlt := -1.0E-3; Down := E;
            Which := 0;
            return (Up - Down) / 2.0E-3;
         end D;
         Ok : Boolean := True;
      begin
         Net.Act := AF;
         for J in 1 .. NH loop
            Net.B1 (J) := R; B1 (J) := Long_Float (Net.B1 (J));
            for K in 1 .. NI loop Net.W1 (J, K) := R; W1 (J, K) := Long_Float (Net.W1 (J, K)); end loop;
         end loop;
         for I in 1 .. NO loop
            Net.B2 (I) := R; B2 (I) := Long_Float (Net.B2 (I));
            for J in 1 .. NH loop Net.W2 (I, J) := R; W2 (I, J) := Long_Float (Net.W2 (I, J)); end loop;
            T (I) := R;
         end loop;
         for K in 1 .. NI loop X (K) := R; end loop;
         Forward (Net, X, St);
         Backward (Net, St, T, G);
         declare
            Half_SSE : constant Long_Float := E;
         begin
            Ok := Close (Long_Float (Compute_Loss (St.A2, T)), 2.0 * Half_SSE / Long_Float (NO));   --  Forward + mean loss
         end;
         for J in 1 .. NH loop
            Ok := Ok and then Close (Long_Float (G.DB1 (J)), D (J));
            for K in 1 .. NI loop Ok := Ok and then Close (Long_Float (G.DW1 (J, K)), D (NH + (J - 1) * NI + K)); end loop;
         end loop;
         for I in 1 .. NO loop
            Ok := Ok and then Close (Long_Float (G.DB2 (I)), D (NH + NH * NI + I));
            for J in 1 .. NH loop Ok := Ok and then Close (Long_Float (G.DW2 (I, J)), D (NH + NH * NI + NO + (I - 1) * NH + J)); end loop;
         end loop;
         if not Kink then   --  ReLU near its kink has no derivative; such runs are skipped
            Report (Ok, "run" & Integer'Image (Run) & " " & AF'Image);
         end if;
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
