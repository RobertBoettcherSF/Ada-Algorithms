--  ===========================================================================
--  Package Body: Hidden_Linear_Function
--  Description: Implementation of Hidden Linear Function problem algorithms.
--  ===========================================================================

package body Hidden_Linear_Function is

   -------------------------
   -- Is_Upper_Triangular --
   -------------------------
   function Is_Upper_Triangular (A : Matrix) return Boolean is
      Rows : constant Integer := A'Length (1);
      Cols : constant Integer := A'Length (2);
   begin
      if Rows /= Cols then
         return False;
      end if;

      for I in A'Range (1) loop
         for J in A'Range (2) loop
            if I > J and then A (I, J) /= 0 then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Upper_Triangular;

   ----------------------
   -- Is_Valid_Problem --
   ----------------------
   function Is_Valid_Problem (A : Matrix; b : Bit_Vector) return Boolean is
      N : constant Integer := A'Length (1);
   begin
      if A'Length (2) /= N then
         return False;
      end if;
      if b'Length /= N then
         return False;
      end if;
      if not Is_Upper_Triangular (A) then
         return False;
      end if;
      return True;
   end Is_Valid_Problem;

   -----------------------------
   -- Evaluate_Quadratic_Form --
   -----------------------------
   function Evaluate_Quadratic_Form 
     (A : Matrix; 
      b : Bit_Vector; 
      x : Bit_Vector) return Mod_4 
   is
      N : constant Positive := A'Length (1);
      Quad_Sum : Integer := 0;
      Linear_Sum : Integer := 0;
      Base_Idx_1 : constant Integer := A'First (1) - 1;
      Base_Idx_2 : constant Integer := A'First (2) - 1;
      Vec_Base   : constant Integer := x'First - 1;
      B_Base     : constant Integer := b'First - 1;
   begin
      -- Compute x^T A x over Z
      for I in 1 .. N loop
         for J in I .. N loop
            if A (Base_Idx_1 + I, Base_Idx_2 + J) = 1 then
               declare
                  Xi : constant Integer := Integer (x (Vec_Base + I));
                  Xj : constant Integer := Integer (x (Vec_Base + J));
               begin
                  Quad_Sum := Quad_Sum + Xi * Xj;
               end;
            end if;
         end loop;
      end loop;

      -- Compute b^T x over Z
      for I in 1 .. N loop
         if b (B_Base + I) = 1 then
            declare
               Xi : constant Integer := Integer (x (Vec_Base + I));
            begin
               Linear_Sum := Linear_Sum + Xi;
            end;
         end if;
      end loop;

      declare
         Q_Val : constant Integer := (2 * Quad_Sum + Linear_Sum) mod 4;
      begin
         return Mod_4 (Q_Val);
      end;
   end Evaluate_Quadratic_Form;

   -----------------------
   -- Is_In_Subspace_Lq --
   -----------------------
   function Is_In_Subspace_Lq 
     (A : Matrix; 
      b : Bit_Vector; 
      x : Bit_Vector) return Boolean 
   is
      N : constant Positive := A'Length (1);
      Total_Combos : constant Natural := 2 ** N;
      Vec_Base : constant Integer := x'First - 1;
   begin
      -- Check linearity condition: q(x xor y) = (q(x) + q(y)) mod 4 for all y
      for Mask in 0 .. Total_Combos - 1 loop
         declare
            Y : Bit_Vector (1 .. N);
            X_Xor_Y : Bit_Vector (1 .. N);
            Temp_Mask : Natural := Mask;
         begin
            for I in 1 .. N loop
               declare
                  Bit_Val : constant Bit := Bit (Temp_Mask mod 2);
                  Xi : constant Bit := x (Vec_Base + I);
               begin
                  Y (I) := Bit_Val;
                  if (Xi = 1 and then Bit_Val = 0) or else (Xi = 0 and then Bit_Val = 1) then
                     X_Xor_Y (I) := 1;
                  else
                     X_Xor_Y (I) := 0;
                  end if;
                  Temp_Mask := Temp_Mask / 2;
               end;
            end loop;

            declare
               Q_X      : constant Mod_4 := Evaluate_Quadratic_Form (A, b, x);
               Q_Y      : constant Mod_4 := Evaluate_Quadratic_Form (A, b, Y);
               Q_X_Y    : constant Mod_4 := Evaluate_Quadratic_Form (A, b, X_Xor_Y);
               Expected : constant Integer := (Integer (Q_X) + Integer (Q_Y)) mod 4;
            begin
               if Integer (Q_X_Y) /= Expected then
                  return False;
               end if;
            end;
         end;
      end loop;

      return True;
   end Is_In_Subspace_Lq;

   --------------------------
   -- Verify_Hidden_Vector --
   --------------------------
   function Verify_Hidden_Vector 
     (A : Matrix; 
      b : Bit_Vector; 
      z : Bit_Vector) return Boolean 
   is
      N : constant Positive := A'Length (1);
      Total_Combos : constant Natural := 2 ** N;
      Z_Base : constant Integer := z'First - 1;
   begin
      -- Check q(x) = 2 * (z^T x) mod 4 for all x in L_q
      for Mask in 0 .. Total_Combos - 1 loop
         declare
            X : Bit_Vector (1 .. N);
            Temp_Mask : Natural := Mask;
         begin
            for I in 1 .. N loop
               X (I) := Bit (Temp_Mask mod 2);
               Temp_Mask := Temp_Mask / 2;
            end loop;

            if Is_In_Subspace_Lq (A, b, X) then
               declare
                  Q_X : constant Mod_4 := Evaluate_Quadratic_Form (A, b, X);
                  Dot_Product : Integer := 0;
               begin
                  for I in 1 .. N loop
                     if z (Z_Base + I) = 1 and then X (I) = 1 then
                        Dot_Product := Dot_Product + 1;
                     end if;
                  end loop;

                  declare
                     Expected : constant Integer := (2 * Dot_Product) mod 4;
                  begin
                     if Integer (Q_X) /= Expected then
                        return False;
                     end if;
                  end;
               end;
            end if;
         end;
      end loop;

      return True;
   end Verify_Hidden_Vector;

   ------------------------
   -- Find_Hidden_Vector --
   ------------------------
   function Find_Hidden_Vector 
     (A : Matrix; 
      b : Bit_Vector) return Bit_Vector 
   is
      N : constant Positive := A'Length (1);
      Total_Z_Combos : constant Natural := 2 ** N;
   begin
      -- Search over all possible z vectors in F_2^n
      for Mask in 0 .. Total_Z_Combos - 1 loop
         declare
            Z : Bit_Vector (1 .. N);
            Temp_Mask : Natural := Mask;
         begin
            for I in 1 .. N loop
               Z (I) := Bit (Temp_Mask mod 2);
               Temp_Mask := Temp_Mask / 2;
            end loop;

            if Verify_Hidden_Vector (A, b, Z) then
               return Z;
            end if;
         end;
      end loop;

      raise No_Solution;
   end Find_Hidden_Vector;

end Hidden_Linear_Function;
