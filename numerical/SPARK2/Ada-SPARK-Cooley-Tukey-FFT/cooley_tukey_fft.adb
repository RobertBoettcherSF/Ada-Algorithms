pragma Ada_2022;
with Interfaces;
package body Cooley_Tukey_FFT
  with SPARK_Mode => On
is
   use type Interfaces.Integer_64;

   C707 : constant := 724;  --  round (1024 * cos(pi/4))

   function Bit_Reverse (I : Index) return Index
     with Global => null
   is
      V : Natural := Natural (I);
      R : Natural := 0;
   begin
      for B in 1 .. 3 loop
         R := R * 2 + (V mod 2);
         V := V / 2;
      end loop;
      return Index (R);
   end Bit_Reverse;

   procedure Swap (X : in out Complex_Array; A, B : Index)
     with
       Global => null,
       Pre    => A < B
   is
      T : Complex;
   begin
      T := X (A);
      X (A) := X (B);
      X (B) := T;
   end Swap;

   procedure Bit_Reverse_Permute (X : in out Complex_Array)
     with Global => null
   is
      J : Index;
   begin
      for I in Index loop
         J := Bit_Reverse (I);
         if J > I then
            Swap (X, I, J);
         end if;
      end loop;
   end Bit_Reverse_Permute;

   function Clamp (V : Interfaces.Integer_64) return Sample
     with Global => null
   is
   begin
      if V < Interfaces.Integer_64 (Sample'First) then
         return Sample'First;
      elsif V > Interfaces.Integer_64 (Sample'Last) then
         return Sample'Last;
      else
         return Sample (V);
      end if;
   end Clamp;

   procedure Mul_Twiddle
     (Re, Im       : Sample;
      Tw_R, Tw_I   : Integer;
      Out_R, Out_I : out Sample)
     with
       Global => null,
       Pre    => Tw_R in -Scale .. Scale and then Tw_I in -Scale .. Scale
   is
      AR : constant Interfaces.Integer_64 := Interfaces.Integer_64 (Re);
      AI : constant Interfaces.Integer_64 := Interfaces.Integer_64 (Im);
      TR : constant Interfaces.Integer_64 := Interfaces.Integer_64 (Tw_R);
      TI : constant Interfaces.Integer_64 := Interfaces.Integer_64 (Tw_I);
   begin
      Out_R := Clamp ((AR * TR - AI * TI) / Interfaces.Integer_64 (Scale));
      Out_I := Clamp ((AR * TI + AI * TR) / Interfaces.Integer_64 (Scale));
   end Mul_Twiddle;

   procedure Butterfly
     (X          : in out Complex_Array;
      I, J       : Index;
      Tw_R, Tw_I : Integer)
     with
       Global => null,
       Pre    => I /= J
                 and then Tw_R in -Scale .. Scale
                 and then Tw_I in -Scale .. Scale
   is
      Tr, Ti : Sample;
      Ur, Ui : Sample;
   begin
      Mul_Twiddle (X (J).Re, X (J).Im, Tw_R, Tw_I, Tr, Ti);
      Ur := X (I).Re;
      Ui := X (I).Im;
      X (I).Re := Clamp (Interfaces.Integer_64 (Ur) + Interfaces.Integer_64 (Tr));
      X (I).Im := Clamp (Interfaces.Integer_64 (Ui) + Interfaces.Integer_64 (Ti));
      X (J).Re := Clamp (Interfaces.Integer_64 (Ur) - Interfaces.Integer_64 (Tr));
      X (J).Im := Clamp (Interfaces.Integer_64 (Ui) - Interfaces.Integer_64 (Ti));
   end Butterfly;

   procedure FFT (X : in out Complex_Array) is
   begin
      Bit_Reverse_Permute (X);

      --  Stage 1: len=2, W=1
      Butterfly (X, 0, 1, Scale, 0);
      Butterfly (X, 2, 3, Scale, 0);
      Butterfly (X, 4, 5, Scale, 0);
      Butterfly (X, 6, 7, Scale, 0);

      --  Stage 2: len=4, W^0=1, W^2=-i
      Butterfly (X, 0, 2, Scale, 0);
      Butterfly (X, 1, 3, 0, -Scale);
      Butterfly (X, 4, 6, Scale, 0);
      Butterfly (X, 5, 7, 0, -Scale);

      --  Stage 3: len=8, W^0..W^3
      Butterfly (X, 0, 4, Scale, 0);
      Butterfly (X, 1, 5, C707, -C707);
      Butterfly (X, 2, 6, 0, -Scale);
      Butterfly (X, 3, 7, -C707, -C707);
   end FFT;

end Cooley_Tukey_FFT;
