with Ada.Numerics.Discrete_Random;

package body Shamirs_Secret_Sharing is

   package Random_Field is new Ada.Numerics.Discrete_Random (Field_Element);
   Gen : Random_Field.Generator;

   ----------------------------------------------------------------------------
   --  Finite Field Variant
   ----------------------------------------------------------------------------

   function Modular_Inverse (Value : Field_Element) return Field_Element is
      Result : Field_Element := 1;
      Base   : Field_Element := Value;
      Exp    : Natural := Natural (Prime - 2);
   begin
      --  Fermat's Little Theorem: a^(p-2) = a^-1 (mod p)
      while Exp > 0 loop
         if Exp mod 2 = 1 then
            Result := Result * Base;
         end if;
         Base := Base * Base;
         Exp  := Exp / 2;
      end loop;
      return Result;
   end Modular_Inverse;

   function Evaluate_Polynomial
     (Secret       : Field_Element;
      Coefficients : Coefficient_Array;
      X            : Field_Element) return Field_Element
   is
      Result : Field_Element := 0;
   begin
      if Coefficients'Length = 0 then
         return Secret;
      end if;

      --  Horner's method for polynomial evaluation
      Result := Coefficients (Coefficients'Last);
      for I in reverse Coefficients'First .. Coefficients'Last - 1 loop
         Result := Result * X + Coefficients (I);
      end loop;
      
      return Result * X + Secret;
   end Evaluate_Polynomial;

   function Split_Secret_Deterministic
     (Secret       : Field_Element;
      Coefficients : Coefficient_Array;
      Total_Shares : Positive) return Share_Array
   is
      Result : Share_Array (1 .. Total_Shares);
   begin
      if Total_Shares > 255 then
         raise Threshold_Error with "Max total shares is 255";
      end if;

      for I in 1 .. Total_Shares loop
         Result (I).Id    := Share_Identifier (I);
         Result (I).Value := Evaluate_Polynomial 
           (Secret, Coefficients, Field_Element (I));
      end loop;
      return Result;
   end Split_Secret_Deterministic;

   function Split_Secret
     (Secret       : Field_Element;
      Threshold    : Positive;
      Total_Shares : Positive) return Share_Array
   is
   begin
      if Threshold > Total_Shares then
         raise Threshold_Error with "Threshold exceeds Total_Shares";
      end if;

      if Threshold = 1 then
         declare
            Empty_Coeffs : constant Coefficient_Array (1 .. 0) := [];
         begin
            return Split_Secret_Deterministic (Secret, Empty_Coeffs, Total_Shares);
         end;
      else
         declare
            Coeffs : Coefficient_Array (1 .. Threshold - 1);
         begin
            for I in Coeffs'Range loop
               Coeffs (I) := Random_Field.Random (Gen);
            end loop;
            return Split_Secret_Deterministic (Secret, Coeffs, Total_Shares);
         end;
      end if;
   end Split_Secret;

   function Reconstruct_Secret
     (Shares    : Share_Array;
      Threshold : Positive) return Field_Element
   is
      Sum      : Field_Element := 0;
      Num, Den : Field_Element;
      Xi, Xj   : Field_Element;
   begin
      if Shares'Length < Threshold then
         raise Threshold_Error with "Insufficient shares provided";
      end if;

      for I in Shares'First .. Shares'First + Threshold - 1 loop
         Xi  := Field_Element (Shares (I).Id);
         Num := 1;
         Den := 1;

         for J in Shares'First .. Shares'First + Threshold - 1 loop
            if I /= J then
               Xj := Field_Element (Shares (J).Id);
               
               if Xi = Xj then
                   raise Invalid_Share_Error with "Duplicate share ID detected";
               end if;

               --  Lagrange basis polynomial numerator at x = 0
               --  (0 - Xj) = -Xj. In mod P, -Xj wraps around cleanly.
               Num := Num * (-Xj);
               --  Denominator: (Xi - Xj)
               Den := Den * (Xi - Xj);
            end if;
         end loop;
         
         Sum := Sum + Shares (I).Value * Num * Modular_Inverse (Den);
      end loop;

      return Sum;
   end Reconstruct_Secret;


   ----------------------------------------------------------------------------
   --  Integer Arithmetic Variant
   ----------------------------------------------------------------------------

   function Split_Secret_Integer
     (Secret       : Integer;
      Coefficients : Integer_Coefficient_Array;
      Total_Shares : Positive) return Integer_Share_Array
   is
      Result   : Integer_Share_Array (1 .. Total_Shares);
      Poly_Val : Integer;
      X_Val    : Integer;
   begin
      for I in 1 .. Total_Shares loop
         X_Val    := I;
         Poly_Val := Secret;
         
         if Coefficients'Length > 0 then
            Poly_Val := Coefficients (Coefficients'Last);
            for J in reverse Coefficients'First .. Coefficients'Last - 1 loop
               Poly_Val := Poly_Val * X_Val + Coefficients (J);
            end loop;
            Poly_Val := Poly_Val * X_Val + Secret;
         end if;
         
         Result (I) := (Id => I, Value => Poly_Val);
      end loop;
      return Result;
   end Split_Secret_Integer;

   function Reconstruct_Secret_Integer
     (Shares    : Integer_Share_Array;
      Threshold : Positive) return Integer
   is
      Sum      : Long_Float := 0.0;
      Num, Den : Long_Float;
   begin
      if Shares'Length < Threshold then
         raise Threshold_Error with "Insufficient integer shares";
      end if;

      for I in Shares'First .. Shares'First + Threshold - 1 loop
         Num := 1.0;
         Den := 1.0;
         for J in Shares'First .. Shares'First + Threshold - 1 loop
            if I /= J then
               if Shares (I).Id = Shares (J).Id then
                  raise Invalid_Share_Error with "Duplicate ID in integer shares";
               end if;
               
               Num := Num * Long_Float (-Shares (J).Id);
               Den := Den * Long_Float (Shares (I).Id - Shares (J).Id);
            end if;
         end loop;
         
         Sum := Sum + Long_Float (Shares (I).Value) * Num / Den;
      end loop;
      
      return Integer (Long_Float'Rounding (Sum));
   end Reconstruct_Secret_Integer;

begin
   --  Initialize random generator state at package load
   Random_Field.Reset (Gen);
end Shamirs_Secret_Sharing;
