package body Raders_FFT is

   function Is_Prime (N : Natural) return Boolean is
      I : Natural := 3;
   begin
      if N <= 1 then return False; end if;
      if N = 2 then return True; end if;
      if N mod 2 = 0 then return False; end if;
      
      -- Use safe integer arithmetic instead of fractional exponents (N ** 0.5)
      while I <= N / I loop
         if N mod I = 0 then
            return False;
         end if;
         I := I + 2;
      end loop;
      return True;
   end Is_Prime;

   function Mod_Exp (Base, Exp, M : Natural) return Natural is
      Result : Natural := 1;
      B : Natural := Base mod M;
      E : Natural := Exp;
   begin
      while E > 0 loop
         if E mod 2 = 1 then
            Result := (Result * B) mod M;
         end if;
         B := (B * B) mod M;
         E := E / 2;
      end loop;
      return Result;
   end Mod_Exp;

   function Mod_Inverse (A, M : Natural) return Natural is
   begin
      -- Using Fermat's Little Theorem since M is guaranteed to be prime
      return Mod_Exp (A, M - 2, M);
   end Mod_Inverse;

   function Primitive_Root (N : Natural) return Natural is
      Is_Primitive : Boolean;
   begin
      if N = 2 then return 1; end if;
      for G in 2 .. N - 1 loop
         Is_Primitive := True;
         for K in 1 .. N - 2 loop
            if Mod_Exp (G, K, N) = 1 then
               Is_Primitive := False;
               exit;
            end if;
         end loop;
         if Is_Primitive then return G; end if;
      end loop;
      return 0;
   end Primitive_Root;

   function Next_Power_Of_2 (N : Natural) return Natural is
      P : Natural := 1;
   begin
      while P < N loop
         P := P * 2;
      end loop;
      return P;
   end Next_Power_Of_2;

   -- Internal Radix-2 FFT used for Fast Cyclic Convolution Variant
   procedure FFT_Radix2 (A : in out Complex_Array; Inverse : Boolean := False) is
      N : constant Natural := A'Length;
      J : Natural := 0;
      Temp, W, W_Factor, U, V : Complex;
      M_Val, Step, Half_Step : Natural;
      Angle : Real;
      Pi : constant Real := Real (Ada.Numerics.Pi);
   begin
      -- Bit-reversal permutation
      for I in 0 .. N - 1 loop
         if I < J then
            Temp := A(A'First + I);
            A(A'First + I) := A(A'First + J);
            A(A'First + J) := Temp;
         end if;
         M_Val := N / 2;
         while M_Val >= 1 and then J >= M_Val loop
            J := J - M_Val;
            M_Val := M_Val / 2;
         end loop;
         J := J + M_Val;
      end loop;

      -- Cooley-Tukey Butterflies
      Step := 2;
      while Step <= N loop
         Half_Step := Step / 2;
         Angle := -2.0 * Pi / Real (Step);
         if Inverse then Angle := -Angle; end if;
         
         W_Factor := Compose_From_Polar (1.0, Angle);
         for I in 0 .. (N / Step) - 1 loop
            W := (1.0, 0.0);
            for K in 0 .. Half_Step - 1 loop
               declare
                  Idx1 : constant Natural := A'First + I * Step + K;
                  Idx2 : constant Natural := Idx1 + Half_Step;
               begin
                  U := A(Idx1);
                  V := A(Idx2) * W;
                  A(Idx1) := U + V;
                  A(Idx2) := U - V;
               end;
               W := W * W_Factor;
            end loop;
         end loop;
         Step := Step * 2;
      end loop;

      if Inverse then
         for I in A'Range loop
            A(I) := A(I) / Real (N);
         end loop;
      end if;
   end FFT_Radix2;

   procedure Rader_DFT_Direct (Input : in Complex_Array; Output : out Complex_Array) is
      N : constant Natural := Input'Length;
      G, G_Inv : Natural;
      Sum : Complex := (0.0, 0.0);
   begin
      if Input'Length /= Output'Length then raise Invalid_Input_Error; end if;
      if not Is_Prime (N) then raise Non_Prime_Length_Error; end if;

      for I in Input'Range loop
         Sum := Sum + Input(I);
      end loop;
      Output(Output'First) := Sum;
      
      -- Edge case N=2 directly
      if N = 2 then
         Output(Output'First + 1) := Input(Input'First) - Input(Input'First + 1);
         return;
      end if;

      G := Primitive_Root (N);
      G_Inv := Mod_Inverse (G, N);

      declare
         L : constant Natural := N - 1;
         A, B, C : Complex_Array (0 .. L - 1);
         Angle : Real;
         Pi : constant Real := Real (Ada.Numerics.Pi);
      begin
         for Q in 0 .. L - 1 loop
            A(Q) := Input(Input'First + Mod_Exp (G, Q, N));
            Angle := -2.0 * Pi * Real (Mod_Exp (G_Inv, Q, N)) / Real (N);
            B(Q) := Compose_From_Polar (1.0, Angle);
         end loop;

         for P in 0 .. L - 1 loop
            C(P) := (0.0, 0.0);
            for Q in 0 .. L - 1 loop
               C(P) := C(P) + A(Q) * B((P - Q) mod L);
            end loop;
         end loop;

         for P in 0 .. L - 1 loop
            Output(Output'First + Mod_Exp (G_Inv, P, N)) := Input(Input'First) + C(P);
         end loop;
      end;
   end Rader_DFT_Direct;

   procedure Rader_DFT_Fast (Input : in Complex_Array; Output : out Complex_Array) is
      N : constant Natural := Input'Length;
      G, G_Inv : Natural;
      Sum : Complex := (0.0, 0.0);
   begin
      if Input'Length /= Output'Length then raise Invalid_Input_Error; end if;
      if not Is_Prime (N) then raise Non_Prime_Length_Error; end if;

      for I in Input'Range loop
         Sum := Sum + Input(I);
      end loop;
      Output(Output'First) := Sum;
      
      if N = 2 then
         Output(Output'First + 1) := Input(Input'First) - Input(Input'First + 1);
         return;
      end if;

      G := Primitive_Root (N);
      G_Inv := Mod_Inverse (G, N);

      declare
         L : constant Natural := N - 1;
         A, B : Complex_Array (0 .. L - 1);
         Angle : Real;
         Pi : constant Real := Real (Ada.Numerics.Pi);
         M : constant Natural := Next_Power_Of_2 (2 * L - 1);
         A_Pad : Complex_Array (0 .. M - 1) := (others => (0.0, 0.0));
         B_Pad : Complex_Array (0 .. M - 1) := (others => (0.0, 0.0));
      begin
         for Q in 0 .. L - 1 loop
            A(Q) := Input(Input'First + Mod_Exp (G, Q, N));
            Angle := -2.0 * Pi * Real (Mod_Exp (G_Inv, Q, N)) / Real (N);
            B(Q) := Compose_From_Polar (1.0, Angle);
         end loop;

         for I in 0 .. L - 1 loop A_Pad(I) := A(I); end loop;
         for I in 0 .. 2 * L - 2 loop B_Pad(I) := B((I + 1) mod L); end loop;

         FFT_Radix2 (A_Pad, False);
         FFT_Radix2 (B_Pad, False);

         for I in 0 .. M - 1 loop
            A_Pad(I) := A_Pad(I) * B_Pad(I);
         end loop;

         FFT_Radix2 (A_Pad, True);

         for P in 0 .. L - 1 loop
            Output(Output'First + Mod_Exp (G_Inv, P, N)) := Input(Input'First) + A_Pad(L - 1 + P);
         end loop;
      end;
   end Rader_DFT_Fast;

end Raders_FFT;
