with Ada.Numerics.Discrete_Random;

package body Secret_Sharing is

   --  Instantiate random number generators for both field types.
   --  Note: Discrete_Random is used for demonstration of the algorithm variants.
   --  In a strict cryptographic environment, a CSPRNG would replace this.
   package GF_Random is new Ada.Numerics.Discrete_Random (GF_Element);
   package Word_Random is new Ada.Numerics.Discrete_Random (Data_Word);

   GF_Gen   : GF_Random.Generator;
   Word_Gen : Word_Random.Generator;

   -----------------------------------------------------------------------------
   --  Helper Subprograms
   -----------------------------------------------------------------------------

   --  Computes the modular inverse of a field element using Fermat's Little Theorem.
   --  Since Prime is prime, A^(Prime - 2) mod Prime == A^-1 mod Prime.
   function Inverse (A : GF_Element) return GF_Element is
      Result : GF_Element := 1;
      Base   : GF_Element := A;
      Exp    : Natural := 2_147_483_645; -- Prime - 2
   begin
      if A = 0 then
         raise Constraint_Error with "Inverse of zero is undefined in GF(P)";
      end if;

      --  Exponentiation by squaring
      while Exp > 0 loop
         if Exp mod 2 = 1 then
            Result := Result * Base;
         end if;
         Base := Base * Base;
         Exp := Exp / 2;
      end loop;

      return Result;
   end Inverse;

   -----------------------------------------------------------------------------
   --  Variant 1: Shamir's Secret Sharing Implementation
   -----------------------------------------------------------------------------

   function Split_Shamir
     (Secret    : GF_Element;
      N         : Share_ID;
      Threshold : Threshold_Type) return Shamir_Share_Array
   is
      T      : constant Positive := Positive (Threshold);
      Coeffs : array (1 .. T) of GF_Element;
      Shares : Shamir_Share_Array (1 .. Positive (N));
   begin
      --  The constant term (x^0) is the secret itself.
      Coeffs (1) := Secret;

      --  Generate random coefficients for the remaining polynomial terms (x^1 to x^(T-1)).
      for I in 2 .. T loop
         Coeffs (I) := GF_Random.Random (GF_Gen);
      end loop;

      --  Evaluate the polynomial for each share where X is the share ID (1 to N).
      for I in 1 .. Positive (N) loop
         declare
            X_Val : constant GF_Element := GF_Element (I);
            Y_Val : GF_Element := 0;
            X_Pow : GF_Element := 1;
         begin
            for J in 1 .. T loop
               Y_Val := Y_Val + Coeffs (J) * X_Pow;
               X_Pow := X_Pow * X_Val;
            end loop;
            Shares (I) := (X => X_Val, Y => Y_Val);
         end;
      end loop;

      return Shares;
   end Split_Shamir;

   function Reconstruct_Shamir
     (Shares    : Shamir_Share_Array;
      Threshold : Threshold_Type) return GF_Element
   is
      Secret : GF_Element := 0;
      T      : constant Positive := Positive (Threshold);
   begin
      --  Runtime guard ensuring enough shares are provided, supplementing the Precondition.
      if Shares'Length < T then
         raise Invalid_Share_Count with "Not enough shares to reconstruct the secret";
      end if;

      --  Use Lagrange interpolation at X = 0 to recover the constant term (Secret).
      for J in Shares'First .. Shares'First + T - 1 loop
         declare
            Num : GF_Element := 1;
            Den : GF_Element := 1;
            X_j : constant GF_Element := Shares (J).X;
         begin
            for M in Shares'First .. Shares'First + T - 1 loop
               if M /= J then
                  declare
                     X_m : constant GF_Element := Shares (M).X;
                  begin
                     if X_j = X_m then
                        raise Duplicate_Share_X with "Identical X coordinates detected";
                     end if;
                     --  In modular arithmetic, -X evaluates to (Prime - X) mod Prime.
                     Num := Num * (-X_m);
                     Den := Den * (X_j - X_m);
                  end;
               end if;
            end loop;
            --  Add the Lagrange basis polynomial evaluated at 0, scaled by Y_j.
            Secret := Secret + Shares (J).Y * Num * Inverse (Den);
         end;
      end loop;

      return Secret;
   end Reconstruct_Shamir;

   -----------------------------------------------------------------------------
   --  Variant 2: Trivial Additive/XOR Implementation
   -----------------------------------------------------------------------------

   function Split_XOR
     (Secret : Data_Word;
      N      : Share_ID) return XOR_Share_Array
   is
      Shares : XOR_Share_Array (1 .. Positive (N));
      Accum  : Data_Word := 0;
   begin
      --  Edge case: 1-out-of-1 trivial split.
      if N = 1 then
         Shares (1) := Secret;
         return Shares;
      end if;

      --  Generate N-1 random shares and accumulate their XOR sum.
      for I in 1 .. Positive (N) - 1 loop
         Shares (I) := Word_Random.Random (Word_Gen);
         Accum := Accum xor Shares (I);
      end loop;

      --  The final share is calculated such that XORing all shares yields the secret.
      Shares (Shares'Last) := Secret xor Accum;

      return Shares;
   end Split_XOR;

   function Reconstruct_XOR
     (Shares : XOR_Share_Array) return Data_Word
   is
      Secret : Data_Word := 0;
   begin
      for I in Shares'Range loop
         Secret := Secret xor Shares (I);
      end loop;
      return Secret;
   end Reconstruct_XOR;

begin
   --  Elaboration code to seed the random number generators.
   GF_Random.Reset (GF_Gen);
   Word_Random.Reset (Word_Gen);
end Secret_Sharing;
