package body Blind_Deconvolution is

   -- Helper: Prevent division by zero
   Epsilon : constant Real := 1.0e-12;

   -----------------------------------------------------------------------------
   -- Helpers
   -----------------------------------------------------------------------------

   -- Normalizes an array so its sum equals 1.0 (maintains energy conservation)
   procedure Normalize (S : in out Signal_Array) is
      Sum : Real := 0.0;
   begin
      if S'Length = 0 then raise Invalid_Input; end if;

      for I in S'Range loop
         Sum := Sum + S(I);
      end loop;

      if Sum <= Epsilon then
         -- If array is zeroed out, distribute evenly to avoid NaN
         for I in S'Range loop
            S(I) := 1.0 / Real(S'Length);
         end loop;
      else
         for I in S'Range loop
            S(I) := S(I) / Sum;
         end loop;
      end if;
   end Normalize;

   -- Reverses the array (used for cross-correlation via convolution)
   function Reverse_Array (S : Signal_Array) return Signal_Array is
      Result : Signal_Array(S'Range);
      Max_Idx : constant Integer := S'Last;
      Min_Idx : constant Integer := S'First;
   begin
      for I in S'Range loop
         Result(I) := S(Max_Idx - (I - Min_Idx));
      end loop;
      return Result;
   end Reverse_Array;

   -- Internal targeted convolution: restricts output length to avoid Constraint_Errors
   -- during gradient updates where Kernel and Signal sizes differ.
   function Convolve_Target (X, H : Signal_Array; Target_First, Target_Last : Integer) return Signal_Array is
      Result : Signal_Array(Target_First .. Target_Last) := (others => 0.0);
      H_Len  : constant Integer := H'Length;
      Half_H : constant Integer := H_Len / 2;
   begin
      if X'Length = 0 or H'Length = 0 then
         raise Invalid_Input;
      end if;

      for I in Result'Range loop
         declare
            Sum : Real := 0.0;
         begin
            for J in H'Range loop
               declare
                  -- Calculate centered offset for the kernel
                  Offset : Integer := J - H'First - Half_H;
                  X_Idx  : Integer := I - Offset;
               begin
                  if X_Idx >= X'First and X_Idx <= X'Last then
                     Sum := Sum + X(X_Idx) * H(J);
                  end if;
               end;
            end loop;
            Result(I) := Sum;
         end;
      end loop;
      return Result;
   end Convolve_Target;

   -- Performs 1D Convolution, returning "same" length as X
   function Convolve (X, H : Signal_Array) return Signal_Array is
   begin
      return Convolve_Target(X, H, X'First, X'Last);
   end Convolve;

   -----------------------------------------------------------------------------
   -- Variant 1: Richardson-Lucy Blind Deconvolution
   -----------------------------------------------------------------------------
   procedure Richardson_Lucy_Blind (
      Observed   : in Signal_Array;
      Iterations : in Positive;
      Signal     : in out Signal_Array;
      PSF        : in out Signal_Array
   ) is
      Estimated_Obs : Signal_Array(Observed'Range);
      Ratio         : Signal_Array(Observed'Range);
      PSF_Rev       : Signal_Array(PSF'Range);
      Sig_Rev       : Signal_Array(Signal'Range);
      Correction_S  : Signal_Array(Signal'Range);
      Correction_P  : Signal_Array(PSF'Range);
   begin
      if Observed'Length /= Signal'Length then
         raise Dimension_Mismatch;
      end if;

      for Iter in 1 .. Iterations loop
         -- 1. Forward projection (Convolution of current Signal and PSF)
         Estimated_Obs := Convolve_Target(Signal, PSF, Observed'First, Observed'Last);

         -- 2. Calculate error ratio (Observed / Estimated)
         for I in Ratio'Range loop
            Ratio(I) := Observed(I) / (Estimated_Obs(I) + Epsilon);
         end loop;

         -- 3. Update Signal (keeping PSF constant)
         PSF_Rev := Reverse_Array(PSF);
         Correction_S := Convolve_Target(Ratio, PSF_Rev, Signal'First, Signal'Last);
         for I in Signal'Range loop
            Signal(I) := Signal(I) * Correction_S(I);
            if Signal(I) < 0.0 then Signal(I) := 0.0; end if; -- Positivity constraint
         end loop;

         -- 4. Update PSF (keeping Signal constant)
         Sig_Rev := Reverse_Array(Signal);
         Correction_P := Convolve_Target(Ratio, Sig_Rev, PSF'First, PSF'Last);
         for I in PSF'Range loop
            PSF(I) := PSF(I) * Correction_P(I);
            if PSF(I) < 0.0 then PSF(I) := 0.0; end if;
         end loop;

         -- 5. Normalize PSF to preserve energy
         Normalize(PSF);
      end loop;
   end Richardson_Lucy_Blind;

   -----------------------------------------------------------------------------
   -- Variant 2: Alternating Minimization
   -----------------------------------------------------------------------------
   procedure Alternating_Minimization_Blind (
      Observed   : in Signal_Array;
      Iterations : in Positive;
      Signal     : in out Signal_Array;
      PSF        : in out Signal_Array;
      Alpha      : in Real := 0.01
   ) is
      Residual : Signal_Array(Observed'Range);
      Grad_S   : Signal_Array(Signal'Range);
      Grad_P   : Signal_Array(PSF'Range);
      PSF_Rev  : Signal_Array(PSF'Range);
      Sig_Rev  : Signal_Array(Signal'Range);
   begin
      if Observed'Length /= Signal'Length then
         raise Dimension_Mismatch;
      end if;

      for Iter in 1 .. Iterations loop
         -- Compute Residual: Observed - (Signal * PSF)
         Residual := Convolve_Target(Signal, PSF, Observed'First, Observed'Last);
         for I in Residual'Range loop
            Residual(I) := Observed(I) - Residual(I);
         end loop;

         -- Gradient w.r.t Signal: -Residual * reversed(PSF)
         PSF_Rev := Reverse_Array(PSF);
         Grad_S := Convolve_Target(Residual, PSF_Rev, Signal'First, Signal'Last);
         for I in Signal'Range loop
            Signal(I) := Signal(I) + Alpha * Grad_S(I);
            if Signal(I) < 0.0 then Signal(I) := 0.0; end if; 
         end loop;

         -- Gradient w.r.t PSF: -Residual * reversed(Signal)
         Sig_Rev := Reverse_Array(Signal);
         Grad_P := Convolve_Target(Residual, Sig_Rev, PSF'First, PSF'Last);
         for I in PSF'Range loop
            PSF(I) := PSF(I) + Alpha * Grad_P(I);
            if PSF(I) < 0.0 then PSF(I) := 0.0; end if;
         end loop;
         Normalize(PSF);
      end loop;
   end Alternating_Minimization_Blind;

   -----------------------------------------------------------------------------
   -- Variant 3: Wiener Proxy Deconvolution
   -----------------------------------------------------------------------------
   function Wiener_Proxy_Deconvolution (
      Observed : in Signal_Array;
      PSF      : in Signal_Array;
      SNR      : in Real
   ) return Signal_Array is
      Result : Signal_Array(Observed'Range) := (others => 0.0);
      Noise_Factor : constant Real := 1.0 / (SNR + Epsilon);
      PSF_Rev : Signal_Array := Reverse_Array(PSF);
      -- Simplified time-domain deconvolution via regularized correlation
      Cross_Corr : Signal_Array := Convolve_Target(Observed, PSF_Rev, Observed'First, Observed'Last);
   begin
      if Observed'Length = 0 then raise Invalid_Input; end if;

      -- Apply scaling proxy for spectral Wiener mapping in time-domain
      for I in Result'Range loop
         Result(I) := Cross_Corr(I) / (1.0 + Noise_Factor);
      end loop;
      return Result;
   end Wiener_Proxy_Deconvolution;

end Blind_Deconvolution;
