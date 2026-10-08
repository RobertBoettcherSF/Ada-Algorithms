package body Warped_LPC is

   procedure Standard_Autocorrelation (
      Input      : in  Real_Array;
      Order      : in  Positive;
      Auto_Corrs : out Real_Array)
   is
      N : constant Integer := Input'Length;
   begin
      -- Edge Case Validation
      if N = 0 then
         raise Invalid_Input;
      end if;

      if Auto_Corrs'Length /= Order + 1 then
         raise Invalid_Order;
      end if;

      for K in 0 .. Order loop
         Auto_Corrs (Auto_Corrs'First + K) := 0.0;
         -- Standard delay line accumulation
         for I in Input'First .. Input'Last - K loop
            Auto_Corrs (Auto_Corrs'First + K) :=
              Auto_Corrs (Auto_Corrs'First + K) + Input (I) * Input (I + K);
         end loop;
      end loop;
   end Standard_Autocorrelation;


   procedure Warped_Autocorrelation (
      Input      : in  Real_Array;
      Order      : in  Positive;
      Lambda     : in  Real;
      Auto_Corrs : out Real_Array)
   is
      N : constant Integer := Input'Length;
      -- V_Prev and V_Curr simulate the cascaded first-order all-pass filters
      V_Prev : Real_Array (0 .. Order) := (others => 0.0);
      V_Curr : Real_Array (0 .. Order) := (others => 0.0);
   begin
      if N = 0 then
         raise Invalid_Input;
      end if;

      if Auto_Corrs'Length /= Order + 1 then
         raise Invalid_Order;
      end if;

      for K in 0 .. Order loop
         Auto_Corrs (Auto_Corrs'First + K) := 0.0;
      end loop;

      -- Process each sample through the warped delay line
      for I in Input'Range loop
         V_Curr(0) := Input(I);

         for K in 1 .. Order loop
            -- First-order all-pass filter difference equation:
            -- v_k[n] = v_{k-1}[n-1] + lambda * (v_k[n-1] - v_{k-1}[n])
            V_Curr(K) := V_Prev(K - 1) + Lambda * (V_Prev(K) - V_Curr(K - 1));
         end loop;

         -- Accumulate warped autocorrelation: R(k) = sum(v_0[n] * v_k[n])
         for K in 0 .. Order loop
            Auto_Corrs (Auto_Corrs'First + K) :=
              Auto_Corrs (Auto_Corrs'First + K) + V_Curr(0) * V_Curr(K);
         end loop;

         V_Prev := V_Curr;
      end loop;
   end Warped_Autocorrelation;


   procedure Levinson_Durbin (
      Auto_Corrs : in  Real_Array;
      Order      : in  Positive;
      Coeffs     : out Real_Array;
      Error_Var  : out Real)
   is
      E : Real;
      K_Refl : Real;
      Old_Coeffs : Real_Array (1 .. Order) := (others => 0.0);
      New_Coeffs : Real_Array (1 .. Order) := (others => 0.0);
   begin
      if Auto_Corrs'Length /= Order + 1 then
         raise Invalid_Order;
      end if;
      
      if Coeffs'Length /= Order then
         raise Invalid_Order;
      end if;

      E := Auto_Corrs (Auto_Corrs'First);
      
      -- If the signal has zero energy, predictor coefficients remain zero
      if E = 0.0 then
         for I in 1 .. Order loop
            Coeffs (Coeffs'First + (I - 1)) := 0.0;
         end loop;
         Error_Var := 0.0;
         return;
      end if;

      -- Perform standard Levinson-Durbin Recursion
      for I in 1 .. Order loop
         K_Refl := Auto_Corrs (Auto_Corrs'First + I);
         
         for J in 1 .. I - 1 loop
            K_Refl := K_Refl - Old_Coeffs(J) * Auto_Corrs (Auto_Corrs'First + (I - J));
         end loop;
         
         -- Catch perfectly predictable decay to prevent divide-by-zero
         if E = 0.0 then
             exit; 
         end if;
         
         K_Refl := K_Refl / E;
         New_Coeffs(I) := K_Refl;
         
         for J in 1 .. I - 1 loop
            New_Coeffs(J) := Old_Coeffs(J) - K_Refl * Old_Coeffs(I - J);
         end loop;
         
         Old_Coeffs(1 .. I) := New_Coeffs(1 .. I);
         E := E * (1.0 - K_Refl * K_Refl);
      end loop;

      -- Remap to arbitrary caller indices
      for I in 1 .. Order loop
         Coeffs (Coeffs'First + (I - 1)) := Old_Coeffs(I);
      end loop;
      
      Error_Var := E;
   end Levinson_Durbin;

end Warped_LPC;
