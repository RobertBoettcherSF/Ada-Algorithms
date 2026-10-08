--  ==========================================================================
--  Package Body: Hidden_Subgroup_Problem
--  Description: Implementation of Abelian Hidden Subgroup Problem algorithms.
--  ==========================================================================

package body Hidden_Subgroup_Problem is

   ---------------------------------------------------------------------------
   -- Greatest Common Divisor (Euclidean Algorithm)
   ---------------------------------------------------------------------------
   function Greatest_Common_Divisor
     (A, B : Group_Element) return Group_Element is
      X : Group_Element := A;
      Y : Group_Element := B;
      Temp : Group_Element;
   begin
      while Y /= 0 loop
         Temp := Y;
         Y := X mod Y;
         X := Temp;
      end loop;
      return X;
   end Greatest_Common_Divisor;

   ---------------------------------------------------------------------------
   -- Simon post-processing over GF(2)
   ---------------------------------------------------------------------------
   -- Helper: bitwise dot product mod 2
   function Dot_Product (A, B : Bit_Mask) return Natural is
      Val : Bit_Mask := A and B;
      Count : Natural := 0;
   begin
      while Val > 0 loop
         if (Val mod 2) = 1 then
            Count := Count + 1;
         end if;
         Val := Val / 2;
      end loop;
      return Count mod 2;
   end Dot_Product;

   -- Reduced row echelon form over GF(2), one row per pivot column:
   -- Pivot (C) is the row whose leading (highest) bit is C, or 0 when column
   -- C has no pivot. After the back-substitution no pivot row has a bit set
   -- in another row's pivot column.
   type Pivot_Rows is array (Natural range <>) of Bit_Mask;

   procedure Gaussian_Elimination (Bits : Positive; Eqs : Bit_Mask_Array; Pivot : out Pivot_Rows) is
      Full : constant Bit_Mask := Bit_Mask (2 ** Bits - 1);
      Row  : Bit_Mask;
   begin
      Pivot := [others => 0];
      -- forward elimination: reduce each equation by the pivots found so far;
      -- what is left either opens a new pivot column or vanishes (dependent)
      for E of Eqs loop
         Row := E and Full;
         for C in reverse 0 .. Bits - 1 loop
            if (Row and Bit_Mask (2 ** C)) /= 0 then
               if Pivot (C) = 0 then
                  Pivot (C) := Row;
                  exit;
               end if;
               Row := Row xor Pivot (C);
            end if;
         end loop;
      end loop;
      -- back-substitution: lower pivot rows are already reduced, so clearing
      -- bit D of row C with row D cannot set another pivot bit
      for C in 1 .. Bits - 1 loop
         if Pivot (C) /= 0 then
            for D in reverse 0 .. C - 1 loop
               if Pivot (D) /= 0 and then (Pivot (C) and Bit_Mask (2 ** D)) /= 0 then
                  Pivot (C) := Pivot (C) xor Pivot (D);
               end if;
            end loop;
         end if;
      end loop;
   end Gaussian_Elimination;

   -- Null space of the reduced system: one basis vector per free column F,
   -- with bit F set and, for each pivot column C, bit C equal to bit F of
   -- row C (row C reads x_C + sum over free F of row_C(F) x_F = 0).
   function Simon_Null_Vector (Bits : Positive; Eqs : Bit_Mask_Array) return Bit_Mask is
      Pivot    : Pivot_Rows (0 .. Bits - 1);
      Free     : Natural := 0;
      Free_Col : Natural := 0;
      S        : Bit_Mask;
   begin
      Gaussian_Elimination (Bits, Eqs, Pivot);
      for C in Pivot'Range loop
         if Pivot (C) = 0 then
            Free := Free + 1;
            Free_Col := C;
         end if;
      end loop;
      if Free = 0 then
         raise Subgroup_Not_Found;      -- full rank: only s = 0
      elsif Free > 1 then
         raise Invalid_Oracle;          -- null space has 2**Free - 1 non-zero vectors
      end if;
      S := Bit_Mask (2 ** Free_Col);
      for C in Pivot'Range loop
         if Pivot (C) /= 0 and then (Pivot (C) and Bit_Mask (2 ** Free_Col)) /= 0 then
            S := S or Bit_Mask (2 ** C);
         end if;
      end loop;
      return S;
   end Simon_Null_Vector;

   -- Quantum step of Simon's algorithm, simulated exactly: after querying f
   -- on the uniform superposition, measuring the output register (value z)
   -- and applying H^n, outcome y has probability
   --    sum over z of ( sum over x with f (x) = z of (-1)**(x . y) )**2 / 4**n.
   -- The equations are every y with non-zero probability (for a Simon oracle
   -- exactly s-perp). f is queried once per x in 0 .. 2**n - 1.
   function Simon_Sample_Equations
     (N_Bits : Positive;
      Oracle : Simon_Oracle_Function) return Bit_Mask_Array is
      Size   : constant Positive := 2 ** N_Bits;
      F      : array (0 .. Size - 1) of Bit_Mask;
      Amp    : array (Bit_Mask) of Integer;
      Result : Bit_Mask_Array (1 .. Size);
      Count  : Natural := 0;
   begin
      for X in F'Range loop
         F (X) := Oracle (Bit_Mask (X));
      end loop;
      for Y in 0 .. Size - 1 loop
         Amp := [others => 0];
         for X in F'Range loop
            if Dot_Product (Bit_Mask (X), Bit_Mask (Y)) = 0 then
               Amp (F (X)) := Amp (F (X)) + 1;
            else
               Amp (F (X)) := Amp (F (X)) - 1;
            end if;
         end loop;
         if (for some A of Amp => A /= 0) then
            Count := Count + 1;
            Result (Count) := Bit_Mask (Y);
         end if;
      end loop;
      return Result (1 .. Count);
   end Simon_Sample_Equations;

   ---------------------------------------------------------------------------
   -- Variant 1: Simon's Problem Solver
   ---------------------------------------------------------------------------
   function Solve_Simons_Problem
     (N_Bits : Positive;
      Oracle : Simon_Oracle_Function) return Bit_Mask is
      
      -- quantum sampling (simulated), then the GF(2) null space; no search
      -- for colliding pairs
      Eqs : constant Bit_Mask_Array := Simon_Sample_Equations (N_Bits, Oracle);
   begin
      return Simon_Null_Vector (N_Bits, Eqs);
   end Solve_Simons_Problem;

   ---------------------------------------------------------------------------
   -- Variant 2: Period Finding (Order Finding)
   ---------------------------------------------------------------------------
   function Solve_Period_Finding
     (N       : Group_Element;
      Oracle : Oracle_Function) return Period_Type is
   begin
      -- Check if oracle is constant (trivial/degenerate)
      declare
         Base_Val     : constant Group_Element := Oracle(0);
         All_Constant : Boolean := True;
      begin
         for X in 1 .. Group_Element(N - 1) loop
            if Oracle(X) /= Base_Val then
               All_Constant := False;
               exit;
            end if;
         end loop;
         if All_Constant then
            raise Invalid_Oracle;
         end if;
      end;

      --  r = N always works on Z_N (x + N = x), so a one-to-one oracle has
      --  period N (hidden subgroup {0}) rather than no period.
      for R in 1 .. Period_Type(N) loop
         declare
            Is_Periodic : Boolean := True;
         begin
            for X in 0 .. Group_Element(N - 1) loop
               declare
                  Shifted : constant Group_Element := (X + Group_Element(R)) mod N;
               begin
                  if Oracle(X) /= Oracle(Shifted) then
                     Is_Periodic := False;
                     exit;
                  end if;
               end;
            end loop;

            if Is_Periodic then
               return R;
            end if;
         end;
      end loop;

      raise Subgroup_Not_Found;
   exception
      when Subgroup_Not_Found | Invalid_Oracle =>
         raise;
      when others =>
         raise Invalid_Oracle;
   end Solve_Period_Finding;

   ---------------------------------------------------------------------------
   -- Variant 3: General Abelian Hidden Subgroup Problem (HSP)
   ---------------------------------------------------------------------------
   function Solve_Abelian_HSP
     (N       : Group_Element;
      Oracle : Oracle_Function) return Element_Array is
      
      --  The hidden subgroup of a period-r oracle on Z_N is H = {0, r, 2r, ...},
      --  generated by r (r = N for a one-to-one oracle, generator 0, H = {0}).
      --  N / r generates the annihilator of H in the dual group, not H.
      Period : constant Period_Type := Solve_Period_Finding (N, Oracle);
   begin
      return [1 => Group_Element (Period) mod N];
   end Solve_Abelian_HSP;

   ---------------------------------------------------------------------------
   -- Variant 4: Hidden Subgroup Verification
   ---------------------------------------------------------------------------
   function Verify_Hidden_Subgroup
     (N          : Group_Element;
      Subgroup   : Element_Array;
      Oracle     : Oracle_Function) return Boolean is
   begin
      if Subgroup'Length = 0 then
         return False;
      end if;

      for X in 0 .. Group_Element(N - 1) loop
         declare
            Base_Val : constant Group_Element := Oracle(X);
         begin
            for I in Subgroup'Range loop
               declare
                  Shifted : constant Group_Element := (X + Subgroup(I)) mod N;
               begin
                  if Oracle(Shifted) /= Base_Val then
                     return False;
                  end if;
               end;
            end loop;
         end;
      end loop;

      return True;
   end Verify_Hidden_Subgroup;

   ---------------------------------------------------------------------------
   -- Helper Functions / Dual Group Character Evaluation
   ---------------------------------------------------------------------------
   function Evaluate_Character_Orthogonality
     (N        : Group_Element;
      G_Char   : Group_Element;
      Subgroup : Element_Array) return Boolean is
   begin
      for I in Subgroup'Range loop
         if ((G_Char * Subgroup(I)) mod N) /= 0 then
            return False;
         end if;
      end loop;
      return True;
   end Evaluate_Character_Orthogonality;

   ---------------------------------------------------------------------------
   -- Test Oracles Implementation
   ---------------------------------------------------------------------------
   function Simon_Oracle_Sample_1 (X : Bit_Mask) return Bit_Mask is
   begin
      return Bit_Mask'Min(X, X xor 3);
   end Simon_Oracle_Sample_1;

   function Simon_Oracle_Sample_2 (X : Bit_Mask) return Bit_Mask is
   begin
      return Bit_Mask'Min(X, X xor 5);
   end Simon_Oracle_Sample_2;

   function Period_Oracle_Sample_3 (X : Group_Element) return Group_Element is
   begin
      return X mod 3;
   end Period_Oracle_Sample_3;

   function Period_Oracle_Sample_4 (X : Group_Element) return Group_Element is
   begin
      return X mod 4;
   end Period_Oracle_Sample_4;

   function Constant_Oracle (X : Group_Element) return Group_Element is
   begin
      pragma Unreferenced (X);
      return 42;
   end Constant_Oracle;

end Hidden_Subgroup_Problem;
