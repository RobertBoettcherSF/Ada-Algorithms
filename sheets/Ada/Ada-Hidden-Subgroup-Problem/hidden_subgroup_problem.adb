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
   -- Variant 1: Simon's Problem Solver
   ---------------------------------------------------------------------------
   function Solve_Simons_Problem
     (N_Bits : Positive;
      Oracle : Simon_Oracle_Function) return Bit_Mask is
      
      Max_Equations : constant := 16;
      Equations     : Bit_Mask_Array (1 .. Max_Equations) := [others => 0];
      Eq_Count      : Natural := 0;
      
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

      -- Gaussian elimination over GF(2) to find non-zero kernel element s
      function Gaussian_Elimination (Eqs : Bit_Mask_Array; Bits : Positive) return Bit_Mask is
         Matrix : Bit_Mask_Array (1 .. Eqs'Length) := [others => 0];
         M_Len  : Natural := 0;
         Mask   : Bit_Mask;
      begin
         for I in Eqs'Range loop
            if Eqs(I) /= 0 then
               M_Len := M_Len + 1;
               Matrix(M_Len) := Eqs(I);
            end if;
         end loop;

         if M_Len = 0 then
            raise Subgroup_Not_Found;
         end if;

         -- Forward elimination
         for Col_Idx in reverse 0 .. Bits - 1 loop
            Mask := Bit_Mask(2 ** Col_Idx);
            for Row_Idx in 1 .. M_Len loop
               if (Matrix(Row_Idx) and Mask) /= 0 then
                  for Other_Row in 1 .. M_Len loop
                     if Other_Row /= Row_Idx and then (Matrix(Other_Row) and Mask) /= 0 then
                        Matrix(Other_Row) := Matrix(Other_Row) xor Matrix(Row_Idx);
                     end if;
                  end loop;
                  exit;
               end if;
            end loop;
         end loop;

         -- Search for non-zero vector s in solution set
         for Candidate in 1 .. Bit_Mask(2 ** Bits - 1) loop
            declare
               Valid : Boolean := True;
            begin
               for I in 1 .. M_Len loop
                  if Dot_Product(Matrix(I), Candidate) /= 0 then
                     Valid := False;
                     exit;
                  end if;
               end loop;
               if Valid then
                  return Candidate;
               end if;
            end;
         end loop;

         raise Subgroup_Not_Found;
      end Gaussian_Elimination;

   begin
      -- Check direct collisions with zero (loop starts at 1, so I > 0 always)
      for I in 1 .. Bit_Mask(2 ** N_Bits - 1) loop
         declare
            Y1 : constant Bit_Mask := Oracle(I);
            Y2 : constant Bit_Mask := Oracle(0);
         begin
            if Y1 = Y2 then
               return I;
            end if;
         end;
      end loop;

      -- Collect equations for multi-bit Simon's problem
      for I in 1 .. Bit_Mask(2 ** N_Bits - 1) loop
         declare
            X1 : constant Bit_Mask := I;
            Y1 : constant Bit_Mask := Oracle(X1);
         begin
            for J in 1 .. Bit_Mask(2 ** N_Bits - 1) loop
               if J /= X1 and then Oracle(J) = Y1 then
                  Eq_Count := Eq_Count + 1;
                  if Eq_Count <= Max_Equations then
                     Equations(Eq_Count) := X1 xor J;
                  end if;
                  exit;
               end if;
            end loop;
         end;
      end loop;

      if Eq_Count > 0 then
         declare
            Sub_Slice : constant Bit_Mask_Array := Equations(1 .. Integer'Min(Eq_Count, Max_Equations));
         begin
            return Gaussian_Elimination(Sub_Slice, N_Bits);
         end;
      end if;

      raise Subgroup_Not_Found;
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

      for R in 1 .. Period_Type(N - 1) loop
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
      
      Period : Period_Type;
      Gen    : Group_Element;
   begin
      Period := Solve_Period_Finding(N, Oracle);
      
      if Period = 0 then
         raise Subgroup_Not_Found;
      end if;

      Gen := N / Group_Element(Period);

      return [1 => Gen];
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
