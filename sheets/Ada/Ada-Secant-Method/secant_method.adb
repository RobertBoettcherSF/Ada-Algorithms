package body Secant_Method is

   -- Epsilon for avoiding Division By Zero
   Machine_Epsilon : constant Real := 1.0E-14;

   --------------------------------------------------------
   -- Variant 1: Standard Secant Method
   --------------------------------------------------------
   function Standard_Secant
     (Func       : not null access function (X : Real) return Real;
      X0         : Real;
      X1         : Real;
      Tolerance  : Real := 1.0E-7;
      Max_Iter   : Positive := 100) return Root_Result 
   is
      X_Prev : Real := X0;
      X_Curr : Real := X1;
      F_Prev : Real := Func(X_Prev);
      F_Curr : Real := Func(X_Curr);
      X_Next : Real;
   begin
      for Iter in 1 .. Max_Iter loop
         -- Edge Case 1: Division by zero prevention (Flat slope)
         if abs (F_Curr - F_Prev) < Machine_Epsilon then
            return (X_Curr, F_Curr, Iter, Division_By_Zero);
         end if;

         -- Secant recurrence relation
         X_Next := X_Curr - F_Curr * (X_Curr - X_Prev) / (F_Curr - F_Prev);

         -- Check if tolerance is met (either step size or function value)
         if abs (X_Next - X_Curr) <= Tolerance or else abs (Func(X_Next)) <= Tolerance then
            return (X_Next, Func(X_Next), Iter, Success);
         end if;

         -- Prepare variables for the next iteration
         X_Prev := X_Curr;
         F_Prev := F_Curr;
         X_Curr := X_Next;
         F_Curr := Func(X_Curr);
      end loop;
      
      -- Edge Case 2: Maximum iterations exceeded
      return (X_Curr, F_Curr, Max_Iter, Max_Iterations_Reached);
   end Standard_Secant;

   --------------------------------------------------------
   -- Variant 2: False Position Method (Regula Falsi)
   --------------------------------------------------------
   function False_Position
     (Func       : not null access function (X : Real) return Real;
      X0         : Real;
      X1         : Real;
      Tolerance  : Real := 1.0E-7;
      Max_Iter   : Positive := 100) return Root_Result 
   is
      A    : Real := X0;
      B    : Real := X1;
      F_A  : Real := Func(A);
      F_B  : Real := Func(B);
      C    : Real := 0.0;
      F_C  : Real := 0.0;
   begin
      -- Edge Case 3: Invalid Initial Bracket
      if F_A * F_B > 0.0 then
         return (0.0, 0.0, 0, Invalid_Bracket);
      end if;

      for Iter in 1 .. Max_Iter loop
         -- Edge case 4: Division by zero prevention
         if abs (F_B - F_A) < Machine_Epsilon then
            return (B, F_B, Iter, Division_By_Zero);
         end if;

         -- False Position recurrence relation
         C := B - F_B * (B - A) / (F_B - F_A);
         F_C := Func(C);

         -- Check if tolerance is met
         if abs (F_C) <= Tolerance or else abs (B - A) <= Tolerance then
            return (C, F_C, Iter, Success);
         end if;

         -- Maintain the bracket: replace the point with the same sign
         if F_A * F_C < 0.0 then
            B   := C;
            F_B := F_C;
         else
            A   := C;
            F_A := F_C;
         end if;
      end loop;

      -- Edge Case 5: Maximum iterations exceeded
      return (C, F_C, Max_Iter, Max_Iterations_Reached);
   end False_Position;

end Secant_Method;
