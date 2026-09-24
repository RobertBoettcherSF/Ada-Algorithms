-- karplus_strong.adb
-- Implementation of the Karplus-Strong string synthesis variants.

with Ada.Numerics.Float_Random;
with Ada.Exceptions;

package body Karplus_Strong is

   use Ada.Numerics.Float_Random;

   Rand_Gen    : Generator;
   Initialized : Boolean := False;

   -- Helper: Initialize Random Generator
   procedure Init_Gen is
   begin
      if not Initialized then
         Reset (Rand_Gen);
         Initialized := True;
      end if;
   end Init_Gen;

   -- Helper: Validate Frequency limits (Nyquist theorem & zero bounds)
   procedure Validate_Inputs (Sample_Rate, Frequency, Decay : Sample_Type) is
   begin
      if Frequency <= 0.0 or else Frequency >= (Sample_Rate / 2.0) then
         raise Invalid_Frequency with "Frequency must be between 0 and Nyquist limit.";
      end if;
      if Decay < 0.0 or else Decay > 1.0 then
         raise Invalid_Parameter with "Decay factor must be between 0.0 and 1.0.";
      end if;
   end Validate_Inputs;


   -- 1. Standard Plucked String
   procedure Plucked_String (
      Output       : in out Sample_Array;
      Sample_Rate  : in Sample_Type;
      Frequency    : in Sample_Type;
      Decay_Factor : in Sample_Type := 0.996
   ) is
   begin
      if Output'Length = 0 then return; end if;
      
      -- Validate inputs BEFORE calculating delay line length
      Validate_Inputs (Sample_Rate, Frequency, Decay_Factor);
      Init_Gen;

      -- Nested block to safely allocate sized array after validation
      declare
         Exact_Delay : constant Sample_Type := (Sample_Rate / Frequency) - 0.5;
         Delay_Len   : constant Positive := Positive (Sample_Type'Rounding (Exact_Delay));
         
         Delay_Line  : Sample_Array (1 .. Delay_Len);
         Read_Idx    : Positive := 1;
         Prev_Sample : Sample_Type := 0.0;
         New_Sample  : Sample_Type;
      begin
         -- Step 1: Excitation (fill delay line with white noise)
         for I in Delay_Line'Range loop
            Delay_Line (I) := Sample_Type (Random (Rand_Gen) * 2.0 - 1.0);
         end loop;

         -- Step 2: Feedback loop with low-pass filter
         for I in Output'Range loop
            Output (I) := Delay_Line (Read_Idx);
            
            -- Apply standard 2-point averaging filter with decay
            New_Sample := Decay_Factor * 0.5 * (Delay_Line (Read_Idx) + Prev_Sample);
            Prev_Sample := Delay_Line (Read_Idx);
            
            -- Feedback into delay line
            Delay_Line (Read_Idx) := New_Sample;
            
            -- Advance circular buffer
            Read_Idx := (Read_Idx mod Delay_Len) + 1;
         end loop;
      end;
   end Plucked_String;


   -- 2. Drum Sound Variant
   procedure Drum_Sound (
      Output       : in out Sample_Array;
      Sample_Rate  : in Sample_Type;
      Frequency    : in Sample_Type;
      Blend_Factor : in Sample_Type := 0.5;
      Decay_Factor : in Sample_Type := 0.996
   ) is
   begin
      if Output'Length = 0 then return; end if;
      
      -- Validate inputs BEFORE calculating delay line length
      Validate_Inputs (Sample_Rate, Frequency, Decay_Factor);
      if Blend_Factor < 0.0 or else Blend_Factor > 1.0 then
         raise Invalid_Parameter with "Blend factor must be between 0.0 and 1.0.";
      end if;
      Init_Gen;

      declare
         Exact_Delay : constant Sample_Type := (Sample_Rate / Frequency) - 0.5;
         Delay_Len   : constant Positive := Positive (Sample_Type'Rounding (Exact_Delay));
         
         Delay_Line  : Sample_Array (1 .. Delay_Len);
         Read_Idx    : Positive := 1;
         Prev_Sample : Sample_Type := 0.0;
         New_Sample  : Sample_Type;
      begin
         -- Excitation phase
         for I in Delay_Line'Range loop
            Delay_Line (I) := Sample_Type (Random (Rand_Gen) * 2.0 - 1.0);
         end loop;

         -- Synthesis loop
         for I in Output'Range loop
            Output (I) := Delay_Line (Read_Idx);
            
            New_Sample := Decay_Factor * 0.5 * (Delay_Line (Read_Idx) + Prev_Sample);
            Prev_Sample := Delay_Line (Read_Idx);
            
            -- Randomly flip sign based on Blend_Factor to create inharmonicity
            if Sample_Type (Random (Rand_Gen)) < Blend_Factor then
               New_Sample := -New_Sample;
            end if;
            
            Delay_Line (Read_Idx) := New_Sample;
            Read_Idx := (Read_Idx mod Delay_Len) + 1;
         end loop;
      end;
   end Drum_Sound;


   -- 3. Jaffe-Smith Tuned String (Fractional Delay)
   procedure Tuned_String (
      Output       : in out Sample_Array;
      Sample_Rate  : in Sample_Type;
      Frequency    : in Sample_Type;
      Decay_Factor : in Sample_Type := 0.996
   ) is
   begin
      if Output'Length = 0 then return; end if;
      
      -- Validate inputs BEFORE calculating delay line length
      Validate_Inputs (Sample_Rate, Frequency, Decay_Factor);
      Init_Gen;

      declare
         -- Calculate precise floating point delay
         Total_Delay : constant Sample_Type := (Sample_Rate / Frequency) - 0.5;
         
         -- N is the integer portion, d is the fractional portion
         Delay_Len   : constant Positive := Positive (Sample_Type'Floor (Total_Delay));
         Frac_Delay  : constant Sample_Type := Total_Delay - Sample_Type (Delay_Len);
         
         -- All-pass filter coefficient (C = (1-d)/(1+d))
         C : constant Sample_Type := (1.0 - Frac_Delay) / (1.0 + Frac_Delay);
         
         Delay_Line  : Sample_Array (1 .. Delay_Len);
         Read_Idx    : Positive := 1;
         
         Prev_LPF    : Sample_Type := 0.0; -- Previous low-pass filter state
         Prev_AP_In  : Sample_Type := 0.0; -- Previous all-pass input
         Prev_AP_Out : Sample_Type := 0.0; -- Previous all-pass output
         
         LPF_Out     : Sample_Type;
         AP_Out      : Sample_Type;
      begin
         for I in Delay_Line'Range loop
            Delay_Line (I) := Sample_Type (Random (Rand_Gen) * 2.0 - 1.0);
         end loop;

         for I in Output'Range loop
            -- 1. Output is taken from the All-Pass filter state
            Output (I) := Prev_AP_Out;
            
            -- 2. Basic Low-Pass Filter
            LPF_Out := Decay_Factor * 0.5 * (Delay_Line (Read_Idx) + Prev_LPF);
            Prev_LPF := Delay_Line (Read_Idx);
            
            -- 3. All-Pass Filter for Fractional Delay
            -- Difference equation: y[n] = C * x[n] + x[n-1] - C * y[n-1]
            AP_Out := C * LPF_Out + Prev_AP_In - C * Prev_AP_Out;
            
            -- Update All-Pass states
            Prev_AP_In := LPF_Out;
            Prev_AP_Out := AP_Out;
            
            -- 4. Feedback into integer delay line
            Delay_Line (Read_Idx) := AP_Out;
            Read_Idx := (Read_Idx mod Delay_Len) + 1;
         end loop;
      end;
   end Tuned_String;

end Karplus_Strong;
