pragma Ada_2022;
package body Cooley_Tukey_FFT
  with SPARK_Mode => On
is
   C707 : constant := 724;  --  round (1024 * cos(pi/4))

   --  per-component magnitude bound after each stage (see the spec)
   M0 : constant := Input_Bound;           --  212
   M1 : constant := 2 * M0;                --  424
   M2 : constant := 2 * M1;                --  848
   M3 : constant := M2 + (C707 * 2 * M2) / Scale;   --  2047

   function Bit_Reverse (I : Index) return Index
     with Global => null
   is
      V : Natural := Natural (I);
      R : Natural := 0;
   begin
      for B in 1 .. 3 loop
         pragma Loop_Invariant (V <= 2 ** (3 - B + 1) - 1 and then R <= 2 ** (B - 1) - 1);
         R := R * 2 + (V mod 2);
         V := V / 2;
      end loop;
      return Index (R);
   end Bit_Reverse;

   procedure Swap (X : in out Complex_Array; A, B : Index)
     with
       Global => null,
       Pre    => A < B,
       Post   => X (A) = X'Old (B) and then X (B) = X'Old (A)
                 and then (for all K in Index => (if K /= A and K /= B then X (K) = X'Old (K)))
   is
      T : Complex;
   begin
      T := X (A);
      X (A) := X (B);
      X (B) := T;
   end Swap;

   procedure Bit_Reverse_Permute (X : in out Complex_Array; M : Natural)
     with
       Global => null,
       Pre    => Within (X, M),
       Post   => Within (X, M)
   is
      J : Index;
   begin
      for I in Index loop
         pragma Loop_Invariant (Within (X, M));
         J := Bit_Reverse (I);
         if J > I then
            Swap (X, I, J);
         end if;
      end loop;
   end Bit_Reverse_Permute;

   function Small (C : Complex; M : Natural) return Boolean is
     (abs C.Re <= M and then abs C.Im <= M)
   with Ghost;

   --  X (I), X (J) := X (I) + T, X (I) - T with T = X (J) * W for the four twiddles in use;
   --  every product is an integer multiple of Scale for W = 1 and W = -i, so those are exact
   type Twiddle is (W0, W1, W2, W3);   --  exp (-i pi k / 4), k = 0 .. 3

   procedure Butterfly (X : in out Complex_Array; I, J : Index; W : Twiddle; M : Natural)
     with
       Global => null,
       Pre    => I /= J and then M <= M2 and then Small (X (I), M) and then Small (X (J), M),
       Post   => Small (X (I), (if W in W0 | W2 then 2 * M else M + (C707 * 2 * M) / Scale))
                 and then Small (X (J), (if W in W0 | W2 then 2 * M else M + (C707 * 2 * M) / Scale))
                 and then (for all K in Index => (if K /= I and K /= J then X (K) = X'Old (K)))
   is
      Ar : constant Integer := X (J).Re;
      Ai : constant Integer := X (J).Im;
      Ur : constant Integer := X (I).Re;
      Ui : constant Integer := X (I).Im;
      Tr, Ti : Integer;
   begin
      case W is
         when W0 =>                       --  1
            Tr := Ar;
            Ti := Ai;
         when W1 =>                       --  (724 - 724 i) / 1024
            Tr := (C707 * (Ar + Ai)) / Scale;
            Ti := (C707 * (Ai - Ar)) / Scale;
         when W2 =>                       --  -i
            Tr := Ai;
            Ti := -Ar;
         when W3 =>                       --  (-724 - 724 i) / 1024
            Tr := (C707 * (Ai - Ar)) / Scale;
            Ti := (-C707 * (Ar + Ai)) / Scale;
      end case;
      pragma Assert (abs Tr <= (if W in W0 | W2 then M else (C707 * 2 * M) / Scale));
      pragma Assert (abs Ti <= (if W in W0 | W2 then M else (C707 * 2 * M) / Scale));
      X (I) := (Re => Ur + Tr, Im => Ui + Ti);
      X (J) := (Re => Ur - Tr, Im => Ui - Ti);
   end Butterfly;

   procedure FFT (Input : Input_Array; Output : out Complex_Array) is
      X : Complex_Array := [for K in Index => (Re => Input (K).Re, Im => Input (K).Im)];
   begin
      Bit_Reverse_Permute (X, M0);

      --  Stage 1: len=2, W=1
      Butterfly (X, 0, 1, W0, M0);
      Butterfly (X, 2, 3, W0, M0);
      Butterfly (X, 4, 5, W0, M0);
      Butterfly (X, 6, 7, W0, M0);
      pragma Assert (Within (X, M1));

      --  Stage 2: len=4, W^0=1, W^2=-i
      Butterfly (X, 0, 2, W0, M1);
      Butterfly (X, 1, 3, W2, M1);
      Butterfly (X, 4, 6, W0, M1);
      Butterfly (X, 5, 7, W2, M1);
      pragma Assert (Within (X, M2));

      --  Stage 3: len=8, W^0..W^3
      Butterfly (X, 0, 4, W0, M2);
      Butterfly (X, 1, 5, W1, M2);
      Butterfly (X, 2, 6, W2, M2);
      Butterfly (X, 3, 7, W3, M2);
      pragma Assert (Within (X, M3));

      Output := X;
   end FFT;

end Cooley_Tukey_FFT;
