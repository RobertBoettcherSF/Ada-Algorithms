with Ada.Numerics.Generic_Elementary_Functions;

package body BCJR is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   --  Helper: Maps Bit (0, 1) to BPSK symbol (-1.0, +1.0)
   function To_BPSK (B : Bit) return Real is
   begin
      if B = 1 then
         return 1.0;
      else
         return -1.0;
      end if;
   end To_BPSK;

   --  Helper: Jacobian Logarithm max*(X, Y)
   --  If Use_Log is true, returns Max(X,Y) + ln(1 + e^-|X-Y|)
   --  If Use_Log is false, returns Max(X,Y) (Max-Log-MAP approximation)
   function Max_Star (X, Y : Real; Use_Log : Boolean) return Real is
      Max_Val : constant Real := Real'Max (X, Y);
      Min_Val : constant Real := Real'Min (X, Y);
      Neg_Inf : constant Real := -1.0E15;
   begin
      if Max_Val <= Neg_Inf then
         return Neg_Inf;
      end if;
      
      if Use_Log then
         declare
            Diff : constant Real := Max_Val - Min_Val;
            Correction : Real := 0.0;
         begin
            --  Prevent math overflow; log(1 + e^-30) is effectively 0.
            if Diff < 30.0 then
               Correction := Math.Log (1.0 + Math.Exp (-Diff));
            end if;
            return Max_Val + Correction;
         end;
      else
         return Max_Val;
      end if;
   end Max_Star;

   --  Implementation of Log-MAP and Max-Log-MAP
   procedure Log_Domain_Decode
     (Trellis    : in  Trellis_Def;
      Sys_LLR    : in  Metric_Array;
      Parity_LLR : in  Metric_Array;
      Apriori    : in  Metric_Array;
      Ext_LLR    : out Metric_Array;
      Terminated : in  Boolean;
      Use_Log    : in  Boolean)
   is
      N : constant Natural := Sys_LLR'Length;
      type Alpha_Grid is array (0 .. N, Trellis'Range) of Real;
      type Beta_Grid  is array (0 .. N, Trellis'Range) of Real;

      Alpha : Alpha_Grid := [others => [others => -1.0E15]];
      Beta  : Beta_Grid  := [others => [others => -1.0E15]];
   begin
      --  1. Initialization
      Alpha (0, Trellis'First) := 0.0;
      if Terminated then
         Beta (N, Trellis'First) := 0.0;
      else
         for S in Trellis'Range loop
            Beta (N, S) := 0.0;
         end loop;
      end if;

      --  2. Forward Pass (Compute Alpha)
      for K in 1 .. N loop
         for S in Trellis'Range loop
            if Alpha (K - 1, S) > -1.0E14 then -- Optimization for reachable states
               for B in Bit loop
                  declare
                     Branch : constant Branch_Info := Trellis (S)(B);
                     Next_S : constant State_ID := Branch.Next_State;
                     U      : constant Real := To_BPSK (B);
                     P      : constant Real := To_BPSK (Branch.Output.Parity);
                     Gamma  : constant Real := 0.5 * (U * (Sys_LLR (K) + Apriori (K)) + P * Parity_LLR (K));
                  begin
                     Alpha (K, Next_S) := Max_Star (Alpha (K, Next_S), Alpha (K - 1, S) + Gamma, Use_Log);
                  end;
               end loop;
            end if;
         end loop;
      end loop;

      --  3. Backward Pass (Compute Beta)
      for K in reverse 1 .. N loop
         for S in Trellis'Range loop
            for B in Bit loop
               declare
                  Branch : constant Branch_Info := Trellis (S)(B);
                  Next_S : constant State_ID := Branch.Next_State;
                  U      : constant Real := To_BPSK (B);
                  P      : constant Real := To_BPSK (Branch.Output.Parity);
                  Gamma  : constant Real := 0.5 * (U * (Sys_LLR (K) + Apriori (K)) + P * Parity_LLR (K));
               begin
                  Beta (K - 1, S) := Max_Star (Beta (K - 1, S), Beta (K, Next_S) + Gamma, Use_Log);
               end;
            end loop;
         end loop;
      end loop;

      --  4. Extrinsic LLR Calculation
      for K in 1 .. N loop
         declare
            L_Pos, L_Neg : Real := -1.0E15;
         begin
            for S in Trellis'Range loop
               for B in Bit loop
                  declare
                     Branch : constant Branch_Info := Trellis (S)(B);
                     Next_S : constant State_ID := Branch.Next_State;
                     U      : constant Real := To_BPSK (B);
                     P      : constant Real := To_BPSK (Branch.Output.Parity);
                     Gamma  : constant Real := 0.5 * (U * (Sys_LLR (K) + Apriori (K)) + P * Parity_LLR (K));
                     Metric : constant Real := Alpha (K - 1, S) + Gamma + Beta (K, Next_S);
                  begin
                     if B = 1 then
                        L_Pos := Max_Star (L_Pos, Metric, Use_Log);
                     else
                        L_Neg := Max_Star (L_Neg, Metric, Use_Log);
                     end if;
                  end;
               end loop;
            end loop;
            --  Subtract Intrinsic and Apriori information to isolate Extrinsic information
            Ext_LLR (K) := (L_Pos - L_Neg) - Sys_LLR (K) - Apriori (K);
         end;
      end loop;
   end Log_Domain_Decode;

   --  Implementation of Standard MAP (Probability domain)
   procedure Standard_Decode
     (Trellis    : in  Trellis_Def;
      Sys_LLR    : in  Metric_Array;
      Parity_LLR : in  Metric_Array;
      Apriori    : in  Metric_Array;
      Ext_LLR    : out Metric_Array;
      Terminated : in  Boolean)
   is
      N : constant Natural := Sys_LLR'Length;
      type Alpha_Grid is array (0 .. N, Trellis'Range) of Real;
      type Beta_Grid  is array (0 .. N, Trellis'Range) of Real;

      Alpha : Alpha_Grid := [others => [others => 0.0]];
      Beta  : Beta_Grid  := [others => [others => 0.0]];
   begin
      --  1. Initialization
      Alpha (0, Trellis'First) := 1.0;
      if Terminated then
         Beta (N, Trellis'First) := 1.0;
      else
         for S in Trellis'Range loop
            Beta (N, S) := 1.0 / Real (Trellis'Length);
         end loop;
      end if;

      --  2. Forward Pass with Normalization
      for K in 1 .. N loop
         declare
            Sum : Real := 0.0;
         begin
            for S in Trellis'Range loop
               if Alpha (K - 1, S) > 0.0 then
                  for B in Bit loop
                     declare
                        Branch : constant Branch_Info := Trellis (S)(B);
                        U      : constant Real := To_BPSK (B);
                        P      : constant Real := To_BPSK (Branch.Output.Parity);
                        Gamma  : constant Real := Math.Exp (0.5 * (U * (Sys_LLR (K) + Apriori (K)) + P * Parity_LLR (K)));
                     begin
                        Alpha (K, Branch.Next_State) := Alpha (K, Branch.Next_State) + Alpha (K - 1, S) * Gamma;
                     end;
                  end loop;
               end if;
            end loop;
            
            --  Normalize to prevent arithmetic underflow
            for S in Trellis'Range loop Sum := Sum + Alpha (K, S); end loop;
            if Sum > 0.0 then
               for S in Trellis'Range loop Alpha (K, S) := Alpha (K, S) / Sum; end loop;
            end if;
         end;
      end loop;

      --  3. Backward Pass with Normalization
      for K in reverse 1 .. N loop
         declare
            Sum : Real := 0.0;
         begin
            for S in Trellis'Range loop
               for B in Bit loop
                  declare
                     Branch : constant Branch_Info := Trellis (S)(B);
                     U      : constant Real := To_BPSK (B);
                     P      : constant Real := To_BPSK (Branch.Output.Parity);
                     Gamma  : constant Real := Math.Exp (0.5 * (U * (Sys_LLR (K) + Apriori (K)) + P * Parity_LLR (K)));
                  begin
                     Beta (K - 1, S) := Beta (K - 1, S) + Beta (K, Branch.Next_State) * Gamma;
                  end;
               end loop;
            end loop;
            
            --  Normalize
            for S in Trellis'Range loop Sum := Sum + Beta (K - 1, S); end loop;
            if Sum > 0.0 then
               for S in Trellis'Range loop Beta (K - 1, S) := Beta (K - 1, S) / Sum; end loop;
            end if;
         end;
      end loop;

      --  4. Extrinsic LLR Calculation
      for K in 1 .. N loop
         declare
            P_Pos, P_Neg : Real := 0.0;
         begin
            for S in Trellis'Range loop
               for B in Bit loop
                  declare
                     Branch : constant Branch_Info := Trellis (S)(B);
                     U      : constant Real := To_BPSK (B);
                     P      : constant Real := To_BPSK (Branch.Output.Parity);
                     Gamma  : constant Real := Math.Exp (0.5 * (U * (Sys_LLR (K) + Apriori (K)) + P * Parity_LLR (K)));
                     Prob   : constant Real := Alpha (K - 1, S) * Gamma * Beta (K, Branch.Next_State);
                  begin
                     if B = 1 then
                        P_Pos := P_Pos + Prob;
                     else
                        P_Neg := P_Neg + Prob;
                     end if;
                  end;
               end loop;
            end loop;
            
            --  Clamp to avoid Log(0) exception
            P_Pos := Real'Max (P_Pos, 1.0E-30);
            P_Neg := Real'Max (P_Neg, 1.0E-30);
            
            Ext_LLR (K) := Math.Log (P_Pos / P_Neg) - Sys_LLR (K) - Apriori (K);
         end;
      end loop;
   end Standard_Decode;

   --  Main Decode entry point: dispatch to selected variant
   procedure Decode
     (Variant    : in  Algorithm_Variant;
      Trellis    : in  Trellis_Def;
      Sys_LLR    : in  Metric_Array;
      Parity_LLR : in  Metric_Array;
      Apriori    : in  Metric_Array;
      Ext_LLR    : out Metric_Array;
      Terminated : in  Boolean := True)
   is
   begin
      --  Manually check lengths to enforce correctness constraints
      --  even when pragma assertions (-gnata) are not enabled.
      if Sys_LLR'Length /= Parity_LLR'Length or else
         Sys_LLR'Length /= Apriori'Length or else
         Sys_LLR'Length /= Ext_LLR'Length
      then
         raise Constraint_Error with "Mismatched array lengths";
      end if;

      if Sys_LLR'Length = 0 then
         return;
      end if;

      case Variant is
         when Max_Log_MAP =>
            Log_Domain_Decode (Trellis, Sys_LLR, Parity_LLR, Apriori, Ext_LLR, Terminated, Use_Log => False);
         when Log_MAP =>
            Log_Domain_Decode (Trellis, Sys_LLR, Parity_LLR, Apriori, Ext_LLR, Terminated, Use_Log => True);
         when Standard =>
            Standard_Decode (Trellis, Sys_LLR, Parity_LLR, Apriori, Ext_LLR, Terminated);
      end case;
   end Decode;

end BCJR;
