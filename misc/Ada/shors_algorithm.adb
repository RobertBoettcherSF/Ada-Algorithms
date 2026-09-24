--------------------------------------------------------------------------------
-- Package Body: Shors_Algorithm
--------------------------------------------------------------------------------

package body Shors_Algorithm is

   -- Internal helper for square root approximation in trial division fallback
   function Sqrt_Approx (Val : Long_Long_Integer) return Long_Long_Integer is
      Low  : Long_Long_Integer := 0;
      High : Long_Long_Integer := Val;
      Mid  : Long_Long_Integer;
   begin
      if Val <= 1 then
         return Val;
      end if;
      while Low <= High loop
         Mid := (Low + High) / 2;
         if Mid * Mid = Val then
            return Mid;
         elsif Mid * Mid < Val then
            Low := Mid + 1;
         else
            High := Mid - 1;
         end if;
      end loop;
      return High;
   end Sqrt_Approx;

   ---------
   -- GCD --
   ---------
   function GCD (A, B : Number) return Number is
      X    : Long_Long_Integer := Long_Long_Integer (A);
      Y    : Long_Long_Integer := Long_Long_Integer (B);
      Temp : Long_Long_Integer;
   begin
      while Y /= 0 loop
         Temp := Y;
         Y := X mod Y;
         X := Temp;
      end loop;
      return Number (X);
   end GCD;

   ---------------
   -- Power_Mod --
   ---------------
   function Power_Mod (Base : Number; Exp : Exponent; Modulus_Val : Number) return Number is
      Result : Long_Long_Integer := 1;
      B      : Long_Long_Integer := Long_Long_Integer (Base);
      E      : Long_Long_Integer := Long_Long_Integer (Exp);
      M      : constant Long_Long_Integer := Long_Long_Integer (Modulus_Val);
   begin
      if M = 1 then
         return 0;
      end if;
      B := B mod M;
      while E > 0 loop
         if E mod 2 = 1 then
            Result := (Result * B) mod M;
         end if;
         B := (B * B) mod M;
         E := E / 2;
      end loop;
      return Number (Result);
   end Power_Mod;

   -----------------
   -- Find_Period --
   -----------------
   function Find_Period (A : Number; N : Number) return Period_Result is
      Current : Number := A mod N;
      R       : Period_Result := 1;
   begin
      if GCD (A, N) /= 1 then
         raise Order_Not_Found;
      end if;

      -- Order r must be <= N in multiplicative group Z_N*
      while Current /= 1 loop
         if R >= Period_Result (N) then
            raise Order_Not_Found;
         end if;
         R := R + 1;
         Current := Power_Mod (A, Exponent (R), N);
      end loop;
      return R;
   end Find_Period;

   --------------------
   -- Factor_Integer --
   --------------------
   function Factor_Integer (N : Number) return Factor_Pair is
   begin
      if N <= 3 then
         raise Invalid_Argument;
      end if;

      -- Even number quick check
      if N mod 2 = 0 then
         return (Factor_1 => 2, Factor_2 => N / 2);
      end if;

      -- Iterate through candidate bases a for Shor's order-finding reduction
      for A_Cand in 2 .. N - 1 loop
         declare
            G : constant Number := GCD (A_Cand, N);
         begin
            if G > 1 then
               return (Factor_1 => G, Factor_2 => N / G);
            end if;

            declare
               R : Period_Result;
            begin
               R := Find_Period (A_Cand, N);
               
               -- If period r is even, check non-trivial square roots of unity
               if R mod 2 = 0 then
                  declare
                     Half_R : constant Exponent := Exponent (R / 2);
                     X      : constant Number := Power_Mod (A_Cand, Half_R, N);
                  begin
                     if X /= 1 and X /= N - 1 then
                        declare
                           G1 : constant Number := GCD (X - 1, N);
                           G2 : constant Number := GCD (X + 1, N);
                        begin
                           if G1 > 1 and G1 < N then
                              return (Factor_1 => G1, Factor_2 => N / G1);
                           elsif G2 > 1 and G2 < N then
                              return (Factor_1 => G2, Factor_2 => N / G2);
                           end if;
                        end;
                     end if;
                  end;
               end if;
            exception
               when Order_Not_Found =>
                  null; -- Try next base a
            end;
         end;
      end loop;

      -- Fallback trial division for edge composite numbers where specific bases fail
      for I in 2 .. Number (Sqrt_Approx (Long_Long_Integer (N))) loop
         if N mod I = 0 then
            return (Factor_1 => I, Factor_2 => N / I);
         end if;
      end loop;

      raise Factorization_Failed;
   end Factor_Integer;

   ------------------------------
   -- Solve_Discrete_Logarithm --
   ------------------------------
   function Solve_Discrete_Logarithm (G : Number; H : Number; P : Number) return Exponent is
   begin
      if P <= 2 or G = 0 or G >= P or H = 0 or H >= P then
         raise Invalid_Argument;
      end if;

      -- Exhaustive search over Z_p* exponent space [0, p-2] (Shor's discrete log domain)
      for X in 0 .. Exponent (P - 2) loop
         if Power_Mod (G, X, P) = H then
            return X;
         end if;
      end loop;

      raise Discrete_Log_Failed;
   end Solve_Discrete_Logarithm;

end Shors_Algorithm;
