package body Peterson_Gorenstein_Zierler is

   type Matrix is array (Index_Type range <>, Index_Type range <>) of GF_Element;

   function Inverse (A : GF_Element) return GF_Element is
      Result : GF_Element := 1;
   begin
      -- Fermat's Little Theorem: A^(p-2) mod p = A^-1 mod p
      for I in 1 .. Prime_Modulo - 2 loop
         Result := Result * A;
      end loop;
      return Result;
   end Inverse;

   function Evaluate (Poly : Polynomial; X : GF_Element) return GF_Element is
      Result : GF_Element := 0;
      X_Pow  : GF_Element := 1;
   begin
      for I in 0 .. Poly'Length - 1 loop
         Result := Result + Poly (Index_Type (I)) * X_Pow;
         X_Pow := X_Pow * X;
      end loop;
      return Result;
   end Evaluate;

   function Derivative (Poly : Polynomial) return Polynomial is
      Degree : constant Natural := Natural (Poly'Length) - 1;
   begin
      if Degree = 0 then
         return [0 => 0];
      end if;

      declare
         Deriv : Polynomial (0 .. Index_Type (Degree - 1));
      begin
         for I in 1 .. Index_Type (Degree) loop
            -- Coefficient of x^(I-1) is I * original coefficient of x^I
            Deriv (I - 1) := Poly (I) * GF_Element (I mod Prime_Modulo);
         end loop;
         return Deriv;
      end;
   end Derivative;

   -- Internal Helper: Gaussian Elimination to solve AX = B
   function Solve_Linear_System (A : Matrix; B : Polynomial) return Polynomial is
      N   : constant Index_Type := B'Length;
      Mat : Matrix (1 .. N, 1 .. N);
      Vec : Polynomial (1 .. N);
   begin
      if N = 0 then
         return Vec (1 .. 0);
      end if;

      -- Standardize to 1-based indexing for calculations
      for I in 1 .. N loop
         for J in 1 .. N loop
            Mat (I, J) := A (A'First (1) + I - 1, A'First (2) + J - 1);
         end loop;
         Vec (I) := B (B'First + I - 1);
      end loop;

      for I in 1 .. N loop
         -- 1. Find Pivot
         declare
            Pivot_Row : Index_Type := I;
            Temp_Elem : GF_Element;
         begin
            while Pivot_Row <= N and then Mat (Pivot_Row, I) = 0 loop
               Pivot_Row := Pivot_Row + 1;
            end loop;

            if Pivot_Row > N then
               raise Matrix_Singular_Error;
            end if;

            if Pivot_Row /= I then
               for J in 1 .. N loop
                  Temp_Elem         := Mat (I, J);
                  Mat (I, J)        := Mat (Pivot_Row, J);
                  Mat (Pivot_Row, J) := Temp_Elem;
               end loop;
               Temp_Elem       := Vec (I);
               Vec (I)         := Vec (Pivot_Row);
               Vec (Pivot_Row) := Temp_Elem;
            end if;
         end;

         -- 2. Normalize Pivot Row
         declare
            Inv : constant GF_Element := Inverse (Mat (I, I));
         begin
            for J in 1 .. N loop
               Mat (I, J) := Mat (I, J) * Inv;
            end loop;
            Vec (I) := Vec (I) * Inv;
         end;

         -- 3. Eliminate other rows
         for R in 1 .. N loop
            if R /= I and then Mat (R, I) /= 0 then
               declare
                  Factor : constant GF_Element := Mat (R, I);
               begin
                  for J in 1 .. N loop
                     Mat (R, J) := Mat (R, J) - Factor * Mat (I, J);
                  end loop;
                  Vec (R) := Vec (R) - Factor * Vec (I);
               end;
            end if;
         end loop;
      end loop;

      return Vec;
   end Solve_Linear_System;

   function Compute_Locator_Static (Syndromes : Polynomial; Expected_Errors : Positive) return Polynomial is
      N             : constant Index_Type := Index_Type (Expected_Errors);
      A             : Matrix (1 .. N, 1 .. N);
      B             : Polynomial (1 .. N);
      Lambda_Coeffs : Polynomial (1 .. N);
      Lambda        : Polynomial (0 .. N);
      Syn_Base      : constant Index_Type := Syndromes'First;
   begin
      -- Build the syndrome matrix: S_i+j-2
      for I in 1 .. N loop
         for J in 1 .. N loop
            A (I, J) := Syndromes (Syn_Base + I + J - 2);
         end loop;
         -- Avoid unary minus ambiguity on modular types by utilizing binary subtraction from 0
         B (I) := 0 - Syndromes (Syn_Base + I + N - 1);
      end loop;

      Lambda_Coeffs := Solve_Linear_System (A, B);

      Lambda (0) := 1;
      for J in 1 .. N loop
         Lambda (N - J + 1) := Lambda_Coeffs (J);
      end loop;

      return Lambda;
   end Compute_Locator_Static;

   function Compute_Locator_Dynamic (Syndromes : Polynomial; Max_Errors : Positive) return Polynomial is
      Actual_Errors : Natural := Max_Errors;
   begin
      while Actual_Errors > 0 loop
         begin
            return Compute_Locator_Static (Syndromes, Actual_Errors);
         exception
            when Matrix_Singular_Error =>
               Actual_Errors := Actual_Errors - 1;
         end;
      end loop;
      
      -- If loop falls through to 0 errors, the locator is exactly 1 (no roots)
      return [0 => 1];
   end Compute_Locator_Dynamic;

   function Chien_Search (Locator : Polynomial) return Polynomial is
      Degree     : constant Natural := Natural (Locator'Length) - 1;
      Roots      : Polynomial (1 .. Index_Type (Degree));
      Root_Count : Index_Type := 0;
   begin
      if Degree = 0 then
         return Roots (1 .. 0);
      end if;

      for X in GF_Element range 1 .. GF_Element'Last loop
         if Evaluate (Locator, X) = 0 then
            Root_Count := Root_Count + 1;
            if Root_Count > Index_Type (Degree) then
               raise No_Roots_Error with "Found more roots than locator polynomial degree";
            end if;
            Roots (Root_Count) := X;
         end if;
      end loop;

      if Root_Count /= Index_Type (Degree) then
         raise No_Roots_Error with "Found fewer roots than locator polynomial degree";
      end if;

      return Roots (1 .. Root_Count);
   end Chien_Search;

   function Compute_Evaluator (Syndromes : Polynomial; Locator : Polynomial) return Polynomial is
      Degree   : constant Natural := Natural (Locator'Length) - 1;
      Omega    : Polynomial (0 .. Index_Type (Degree) - 1) := [others => 0];
      Syn_Base : constant Index_Type := Syndromes'First;
   begin
      if Degree = 0 then
         return [0 => 0];
      end if;

      for I in 0 .. Index_Type (Degree) - 1 loop
         for J in 0 .. I loop
            Omega (I) := Omega (I) + Syndromes (Syn_Base + J) * Locator (Locator'First + (I - J));
         end loop;
      end loop;
      
      return Omega;
   end Compute_Evaluator;

   function Calculate_Error_Values_Forney (Locator   : Polynomial; 
                                           Evaluator : Polynomial; 
                                           Roots     : Polynomial) return Polynomial 
   is
      N      : constant Index_Type := Roots'Length;
      Values : Polynomial (1 .. N);
      Deriv  : constant Polynomial := Derivative (Locator);
   begin
      for I in 1 .. N loop
         declare
            Root : constant GF_Element := Roots (Roots'First + I - 1);
            Num  : constant GF_Element := Evaluate (Evaluator, Root);
            Den  : constant GF_Element := Evaluate (Deriv, Root);
         begin
            if Den = 0 then
               raise Program_Error with "Derivative evaluated to zero (repeated roots)";
            end if;
            -- Y_k = - Omega(Root) / Lambda'(Root)
            Values (I) := (0 - Num) * Inverse (Den);
         end;
      end loop;
      return Values;
   end Calculate_Error_Values_Forney;

   function Calculate_Error_Values_Linear (Roots     : Polynomial; 
                                           Syndromes : Polynomial) return Polynomial 
   is
      N    : constant Index_Type := Roots'Length;
      A    : Matrix (1 .. N, 1 .. N);
      B    : Polynomial (1 .. N);
      Locs : Polynomial (1 .. N);
   begin
      if N = 0 then
         return B (1 .. 0);
      end if;

      for I in 1 .. N loop
         Locs (I) := Inverse (Roots (Roots'First + I - 1));
      end loop;

      for I in 1 .. N loop
         for J in 1 .. N loop
            -- Matrix components: X_j ^ i
            declare
               Val : GF_Element := 1;
            begin
               for P in 1 .. I loop
                  Val := Val * Locs (J);
               end loop;
               A (I, J) := Val;
            end;
         end loop;
         B (I) := Syndromes (Syndromes'First + I - 1);
      end loop;

      return Solve_Linear_System (A, B);
   end Calculate_Error_Values_Linear;

end Peterson_Gorenstein_Zierler;
