-- celp.adb
-- Implementation of the CELP encoder/decoder and variants.

with Ada.Numerics.Float_Random;
with Ada.Numerics.Elementary_Functions;

package body CELP is

   use Ada.Numerics;
   
   -- Internal state for Low-Delay backward adaptation
   LD_Previous_LPC : LPC_Coeffs := (others => 0.0);

   ------------------------------------------------------------------
   -- Helper: Mean Squared Error (MSE) calculation
   ------------------------------------------------------------------
   function Compute_MSE (Frame_A, Frame_B : Signal_Frame) return Float is
      Sum : Float := 0.0;
      Diff : Float;
   begin
      for I in Frame_Index loop
         Diff := Frame_A (I) - Frame_B (I);
         Sum := Sum + (Diff * Diff);
      end loop;
      return Sum / Float (Frame_Size);
   end Compute_MSE;

   ------------------------------------------------------------------
   -- Helper: LPC Synthesis Filter (All-pole filter 1 / A(z))
   ------------------------------------------------------------------
   function Apply_LPC_Synthesis (Excitation : Signal_Frame; LPC : LPC_Coeffs) return Signal_Frame is
      Output : Signal_Frame := (others => 0.0);
      Acc    : Float;
   begin
      for I in Frame_Index loop
         Acc := Excitation (I);
         for J in 1 .. LPC_Order loop
            if Integer(I) - J >= 1 then
               Acc := Acc + LPC (J) * Output (Frame_Index (Integer(I) - J));
            end if;
         end loop;
         Output (I) := Acc;
      end loop;
      return Output;
   end Apply_LPC_Synthesis;

   ------------------------------------------------------------------
   -- Variant-Specific Fixed Codebook Generation
   ------------------------------------------------------------------
   function Generate_Fixed_Codebook (Index : Integer; Variant : CELP_Variant) return Signal_Frame is
      Code_Vector : Signal_Frame := (others => 0.0);
      Seed        : Float_Random.Generator;
      Pos         : Integer;
   begin
      if Index < 1 or Index > 256 then
         raise CELP_Configuration_Error with "Index out of bounds";
      end if;

      case Variant is
         when Standard_CELP =>
            -- Gaussian random noise based on index seed
            Float_Random.Reset (Seed, Integer(Index));
            for I in Frame_Index loop
               Code_Vector (I) := Float_Random.Random (Seed) * 2.0 - 1.0;
            end loop;

         when ACELP =>
            -- Algebraic CELP: Sparse representation (few non-zero pulses)
            -- Simulating interlaced pulse grids based on index
            Pos := (Index mod Frame_Size) + 1;
            Code_Vector (Frame_Index (Pos)) := 1.0;
            Pos := ((Index * 3) mod Frame_Size) + 1;
            Code_Vector (Frame_Index (Pos)) := -1.0;

         when VSELP =>
            -- Vector Sum: combination of basis vectors
            for I in Frame_Index loop
               Code_Vector (I) := Float(Index mod 2) * 0.5 + Float((Index/2) mod 2) * 0.25;
            end loop;

         when LD_CELP =>
            -- Low Delay uses very short excitation blocks (conceptually smaller, simulated here)
            for I in Frame_Index loop
               Code_Vector (I) := (if Integer(I) <= 5 then 0.5 else 0.0);
            end loop;
            
         when PSI_CELP =>
            -- Pitch Synchronous: Pulses are placed repetitively at pitch periods
            Pos := (Index mod 10) + 1;
            while Pos <= Frame_Size loop
               Code_Vector (Frame_Index(Pos)) := 1.0;
               Pos := Pos + 10; -- Simulated fixed pitch spacing
            end loop;
      end case;
      
      return Code_Vector;
   end Generate_Fixed_Codebook;

   ------------------------------------------------------------------
   -- Main Encoder (Analysis-by-Synthesis Loop)
   ------------------------------------------------------------------
   procedure Encode (Input : in Signal_Frame; Params : out Encoded_Parameters; Variant : in CELP_Variant := Standard_CELP) is
      Best_MSE    : Float := Float'Last;
      Current_MSE : Float;
      Synth       : Signal_Frame;
      Excitation  : Signal_Frame;
   begin
      Params.Variant := Variant;
      
      -- 1. LPC Analysis (Simplified for simulation: pseudo-autocorrelation)
      if Variant = LD_CELP then
         -- LD-CELP is backward-adaptive; relies on previous frame
         Params.LPC := LD_Previous_LPC; 
      else
         for I in 1 .. LPC_Order loop
            Params.LPC (I) := 0.1 / Float (I); -- Dummy stable coefficients
         end loop;
      end if;

      -- 2. Pitch/Adaptive Codebook Search (Simplified to fixed delay)
      Params.Pitch_Delay := 40;
      Params.Pitch_Gain  := 0.7;

      -- 3. Fixed Codebook Search (AbS loop simulation)
      -- Iterating through all possible indices to minimize error
      for Idx in 1 .. 256 loop
         Excitation := Generate_Fixed_Codebook (Idx, Variant);
         
         -- Simulate perceptual weighting and synthesis
         Synth := Apply_LPC_Synthesis (Excitation, Params.LPC);
         Current_MSE := Compute_MSE (Input, Synth);
         
         if Current_MSE < Best_MSE then
            Best_MSE := Current_MSE;
            Params.Fixed_Index := Idx;
            -- Optimal gain calculation (simplified)
            Params.Fixed_Gain := 1.0; 
         end if;
      end loop;

      -- Handle zero input edge case
      if Compute_MSE(Input, (others => 0.0)) < 0.0001 then
         Params.Pitch_Gain := 0.0;
         Params.Fixed_Gain := 0.0;
      end if;

      -- Update backward adaptive state
      if Variant = LD_CELP then
         LD_Previous_LPC := Params.LPC;
      end if;
      
   end Encode;

   ------------------------------------------------------------------
   -- Main Decoder
   ------------------------------------------------------------------
   procedure Decode (Params : in Encoded_Parameters; Output : out Signal_Frame) is
      Fixed_Excit : Signal_Frame;
      Total_Excit : Signal_Frame;
   begin
      if Params.Pitch_Delay < 0 or Params.Pitch_Delay > 147 then
         raise CELP_Configuration_Error with "Invalid Pitch Delay in decoder";
      end if;

      -- 1. Extract innovation from Fixed Codebook
      Fixed_Excit := Generate_Fixed_Codebook (Params.Fixed_Index, Params.Variant);
      
      -- 2. Generate total excitation (Adaptive + Fixed)
      for I in Frame_Index loop
         Total_Excit (I) := (Fixed_Excit (I) * Params.Fixed_Gain);
      end loop;

      -- 3. Synthesize speech using LPC filter
      Output := Apply_LPC_Synthesis (Total_Excit, Params.LPC);
      
   end Decode;

end CELP;
