--  Lanczos_Resampling body — sinc-window kernel, 1-D / separable 2-D.

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;

package body Lanczos_Resampling
  with SPARK_Mode => Off
is

   use Ada.Numerics;
   use Ada.Numerics.Elementary_Functions;

   Pi_F : constant Float := Float (Pi);

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Near_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Sinc (X : Float) return Float is
   begin
      if abs (X) < 1.0E-8 then
         return 1.0;
      else
         return Sin (Pi_F * X) / (Pi_F * X);
      end if;
   end Sinc;

   function Kernel (A : A_Param; X : Float) return Float is
      Af : constant Float := Float (A);
   begin
      if abs (X) >= Af then
         return 0.0;
      elsif abs (X) < 1.0E-8 then
         return 1.0;
      else
         return Sinc (X) * Sinc (X / Af);
      end if;
   end Kernel;

   function Is_Valid_Signal (S : Signal_1D) return Boolean is
   begin
      return S.Valid and then S.N >= 1;
   end Is_Valid_Signal;

   function Is_Valid_Image (Img : Image_2D) return Boolean is
   begin
      return Img.Valid and then Img.Nx >= 1 and then Img.Ny >= 1;
   end Is_Valid_Image;

   function In_Domain (S : Signal_1D; X : Float) return Boolean is
   begin
      if not Is_Valid_Signal (S) then
         return False;
      end if;
      return X >= 0.0 and then X <= Float (S.N - 1);
   end In_Domain;

   function In_Domain (Img : Image_2D; X, Y : Float) return Boolean is
   begin
      if not Is_Valid_Image (Img) then
         return False;
      end if;
      return X >= 0.0 and then X <= Float (Img.Nx - 1)
        and then Y >= 0.0 and then Y <= Float (Img.Ny - 1);
   end In_Domain;

   function Get (S : Signal_1D; I : Signal_Index) return Float is
   begin
      return S.Values (I);
   end Get;

   procedure Set
     (S : in out Signal_1D; I : Signal_Index; Value : Float)
   is
   begin
      S.Values (I) := Value;
   end Set;

   function Get (Img : Image_2D; I, J : Image_Index) return Float is
   begin
      return Img.Values (I, J);
   end Get;

   procedure Set
     (Img : in out Image_2D; I, J : Image_Index; Value : Float)
   is
   begin
      Img.Values (I, J) := Value;
   end Set;

   --  Map an arbitrary integer index into 0 .. Last by successive
   --  reflection about the endpoints.
   function Reflect_Index (I, Last : Integer) return Integer is
      Idx : Integer := I;
   begin
      if Last <= 0 then
         return 0;
      end if;
      while Idx < 0 or else Idx > Last loop
         if Idx < 0 then
            Idx := -Idx;
         else
            Idx := 2 * Last - Idx;
         end if;
      end loop;
      return Idx;
   end Reflect_Index;

   function Clamp_Index (I, Last : Integer) return Integer is
   begin
      if I < 0 then
         return 0;
      elsif I > Last then
         return Last;
      else
         return I;
      end if;
   end Clamp_Index;

   function Fetch
     (S : Signal_1D; I : Integer; Edge : Edge_Mode) return Float
   is
      Last : constant Integer := Integer (S.N) - 1;
      Idx  : Integer;
   begin
      case Edge is
         when Zero =>
            if I < 0 or else I > Last then
               return 0.0;
            end if;
            return S.Values (Signal_Index (I));
         when Clamp =>
            Idx := Clamp_Index (I, Last);
            return S.Values (Signal_Index (Idx));
         when Reflect =>
            Idx := Reflect_Index (I, Last);
            return S.Values (Signal_Index (Idx));
      end case;
   end Fetch;

   function Fetch
     (Img  : Image_2D;
      I, J : Integer;
      Edge : Edge_Mode) return Float
   is
      Last_X : constant Integer := Integer (Img.Nx) - 1;
      Last_Y : constant Integer := Integer (Img.Ny) - 1;
      II, JJ : Integer;
   begin
      case Edge is
         when Zero =>
            if I < 0 or else I > Last_X
              or else J < 0 or else J > Last_Y
            then
               return 0.0;
            end if;
            return Img.Values (Image_Index (I), Image_Index (J));
         when Clamp =>
            II := Clamp_Index (I, Last_X);
            JJ := Clamp_Index (J, Last_Y);
            return Img.Values (Image_Index (II), Image_Index (JJ));
         when Reflect =>
            II := Reflect_Index (I, Last_X);
            JJ := Reflect_Index (J, Last_Y);
            return Img.Values (Image_Index (II), Image_Index (JJ));
      end case;
   end Fetch;

   ---------------------------------------------------------------------------
   -- Resampling
   ---------------------------------------------------------------------------

   function Resample_1D
     (S    : Signal_1D;
      X    : Float;
      A    : A_Param := 3;
      Edge : Edge_Mode := Clamp) return Eval_Result
   is
      R       : Eval_Result;
      Floor_X : Integer;
      Lo, Hi  : Integer;
      Acc     : Float := 0.0;
   begin
      if not S.Valid then
         R.Stat := Ill_Started;
         return R;
      end if;
      if S.N = 0 then
         R.Stat := Empty;
         return R;
      end if;

      Floor_X := Integer (Float'Floor (X));
      Lo := Floor_X - Integer (A) + 1;
      Hi := Floor_X + Integer (A);

      for I in Lo .. Hi loop
         Acc := Acc + Fetch (S, I, Edge) * Kernel (A, X - Float (I));
      end loop;

      R.Value := Acc;
      R.Stat := Ok;
      R.Success := True;
      return R;
   end Resample_1D;

   --  Nested 1-D: for each contributing row j, form a temporary horizontal
   --  line, resample at X, weight by L(Y−j).
   function Resample_2D
     (Img  : Image_2D;
      X, Y : Float;
      A    : A_Param := 3;
      Edge : Edge_Mode := Clamp) return Eval_Result
   is
      R       : Eval_Result;
      Floor_Y : Integer;
      Lo, Hi  : Integer;
      Acc     : Float := 0.0;
      Row_Sig : Signal_1D;
      Row_R   : Eval_Result;
      W       : Float;
   begin
      if not Img.Valid then
         R.Stat := Ill_Started;
         return R;
      end if;
      if Img.Nx = 0 or else Img.Ny = 0 then
         R.Stat := Empty;
         return R;
      end if;

      Row_Sig.N := Signal_Size (Img.Nx);
      Row_Sig.Valid := True;

      Floor_Y := Integer (Float'Floor (Y));
      Lo := Floor_Y - Integer (A) + 1;
      Hi := Floor_Y + Integer (A);

      for J in Lo .. Hi loop
         W := Kernel (A, Y - Float (J));
         if not Near (W, 0.0, 0.0) then
            for I in 0 .. Integer (Img.Nx) - 1 loop
               Row_Sig.Values (Signal_Index (I)) :=
                 Fetch (Img, I, J, Edge);
            end loop;
            Row_R := Resample_1D (Row_Sig, X, A, Edge);
            Acc := Acc + W * Row_R.Value;
         end if;
      end loop;

      R.Value := Acc;
      R.Stat := Ok;
      R.Success := True;
      return R;
   end Resample_2D;

   function Map_Coord
     (Out_Index : Natural; New_N, Old_N : Positive) return Float
     with Global => null
   is
   begin
      if New_N = 1 then
         return 0.0;
      end if;
      return Float (Out_Index) * Float (Old_N - 1) / Float (New_N - 1);
   end Map_Coord;

   function Resize_1D
     (S     : Signal_1D;
      New_N : Natural;
      A     : A_Param := 3;
      Edge  : Edge_Mode := Clamp) return Resize_1D_Result
   is
      R : Resize_1D_Result;
      E : Eval_Result;
      X : Float;
   begin
      if not S.Valid then
         R.Stat := Ill_Started;
         return R;
      end if;
      if S.N = 0 then
         R.Stat := Empty;
         return R;
      end if;
      if New_N = 0 then
         R.Stat := Bad_Parameter;
         return R;
      end if;
      if New_N > Max_Signal then
         R.Stat := Out_Of_Domain;
         return R;
      end if;

      R.Signal := Make_Empty_Signal (Signal_Size (New_N));
      for J in 0 .. Integer (New_N) - 1 loop
         X := Map_Coord (J, Positive (New_N), Positive (S.N));
         E := Resample_1D (S, X, A, Edge);
         R.Signal.Values (Signal_Index (J)) := E.Value;
      end loop;
      R.Stat := Ok;
      R.Success := True;
      return R;
   end Resize_1D;

   function Resize_2D
     (Img    : Image_2D;
      New_Nx : Natural;
      New_Ny : Natural;
      A      : A_Param := 3;
      Edge   : Edge_Mode := Clamp) return Resize_2D_Result
   is
      R       : Resize_2D_Result;
      Temp    : Image_2D;
      Row_Sig : Signal_1D;
      Col_Sig : Signal_1D;
      RR      : Resize_1D_Result;
   begin
      if not Img.Valid then
         R.Stat := Ill_Started;
         return R;
      end if;
      if Img.Nx = 0 or else Img.Ny = 0 then
         R.Stat := Empty;
         return R;
      end if;
      if New_Nx = 0 or else New_Ny = 0 then
         R.Stat := Bad_Parameter;
         return R;
      end if;
      if New_Nx > Max_Image or else New_Ny > Max_Image then
         R.Stat := Out_Of_Domain;
         return R;
      end if;

      Temp := Make_Empty_Image (Image_Size (New_Nx), Img.Ny);
      Row_Sig.N := Signal_Size (Img.Nx);
      Row_Sig.Valid := True;

      for J in 0 .. Integer (Img.Ny) - 1 loop
         for I in 0 .. Integer (Img.Nx) - 1 loop
            Row_Sig.Values (Signal_Index (I)) :=
              Img.Values (Image_Index (I), Image_Index (J));
         end loop;
         RR := Resize_1D (Row_Sig, New_Nx, A, Edge);
         for I in 0 .. Integer (New_Nx) - 1 loop
            Temp.Values (Image_Index (I), Image_Index (J)) :=
              RR.Signal.Values (Signal_Index (I));
         end loop;
      end loop;

      R.Image := Make_Empty_Image
        (Image_Size (New_Nx), Image_Size (New_Ny));
      Col_Sig.N := Signal_Size (Img.Ny);
      Col_Sig.Valid := True;

      for I in 0 .. Integer (New_Nx) - 1 loop
         for J in 0 .. Integer (Img.Ny) - 1 loop
            Col_Sig.Values (Signal_Index (J)) :=
              Temp.Values (Image_Index (I), Image_Index (J));
         end loop;
         RR := Resize_1D (Col_Sig, New_Ny, A, Edge);
         for J in 0 .. Integer (New_Ny) - 1 loop
            R.Image.Values (Image_Index (I), Image_Index (J)) :=
              RR.Signal.Values (Signal_Index (J));
         end loop;
      end loop;

      R.Stat := Ok;
      R.Success := True;
      return R;
   end Resize_2D;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Make_Empty_Signal (N : Signal_Size) return Signal_1D is
      S : Signal_1D;
   begin
      S.N := N;
      S.Values := [others => 0.0];
      S.Valid := True;
      return S;
   end Make_Empty_Signal;

   function Make_Empty_Image (Nx, Ny : Image_Size) return Image_2D is
      Img : Image_2D;
   begin
      Img.Nx := Nx;
      Img.Ny := Ny;
      Img.Values := [others => [others => 0.0]];
      Img.Valid := True;
      return Img;
   end Make_Empty_Image;

   function Make_Constant_1D
     (N : Signal_Size; C : Float) return Signal_1D
   is
      S : Signal_1D := Make_Empty_Signal (N);
   begin
      for I in 0 .. Integer (N) - 1 loop
         S.Values (Signal_Index (I)) := C;
      end loop;
      return S;
   end Make_Constant_1D;

   function Make_Ramp_1D
     (N : Signal_Size; Y0, Y1 : Float) return Signal_1D
   is
      S : Signal_1D := Make_Empty_Signal (N);
      T : Float;
   begin
      if N = 1 then
         S.Values (0) := Y0;
         return S;
      end if;
      for I in 0 .. Integer (N) - 1 loop
         T := Float (I) / Float (N - 1);
         S.Values (Signal_Index (I)) := (1.0 - T) * Y0 + T * Y1;
      end loop;
      return S;
   end Make_Ramp_1D;

   function Make_Impulse_1D
     (N : Signal_Size; Center : Signal_Index; Amplitude : Float := 1.0)
      return Signal_1D
   is
      S : Signal_1D := Make_Empty_Signal (N);
   begin
      S.Values (Center) := Amplitude;
      return S;
   end Make_Impulse_1D;

   function Make_Constant_2D
     (Nx, Ny : Image_Size; C : Float) return Image_2D
   is
      Img : Image_2D := Make_Empty_Image (Nx, Ny);
   begin
      for I in 0 .. Integer (Nx) - 1 loop
         for J in 0 .. Integer (Ny) - 1 loop
            Img.Values (Image_Index (I), Image_Index (J)) := C;
         end loop;
      end loop;
      return Img;
   end Make_Constant_2D;

   function Make_Ramp_2D
     (Nx, Ny : Image_Size) return Image_2D
   is
      Img : Image_2D := Make_Empty_Image (Nx, Ny);
   begin
      for I in 0 .. Integer (Nx) - 1 loop
         for J in 0 .. Integer (Ny) - 1 loop
            Img.Values (Image_Index (I), Image_Index (J)) :=
              Float (I) + 2.0 * Float (J);
         end loop;
      end loop;
      return Img;
   end Make_Ramp_2D;

   function Make_Checkerboard_2D
     (Nx, Ny : Image_Size; Lo, Hi : Float) return Image_2D
   is
      Img : Image_2D := Make_Empty_Image (Nx, Ny);
   begin
      for I in 0 .. Integer (Nx) - 1 loop
         for J in 0 .. Integer (Ny) - 1 loop
            if (I + J) mod 2 = 0 then
               Img.Values (Image_Index (I), Image_Index (J)) := Hi;
            else
               Img.Values (Image_Index (I), Image_Index (J)) := Lo;
            end if;
         end loop;
      end loop;
      return Img;
   end Make_Checkerboard_2D;

   function Make_Example_Impulse return Signal_1D is
   begin
      return Make_Impulse_1D (9, 4, 1.0);
   end Make_Example_Impulse;

   function Make_Example_Ramp return Signal_1D is
   begin
      return Make_Ramp_1D (8, 0.0, 7.0);
   end Make_Example_Ramp;

   function Make_Example_Checker return Image_2D is
   begin
      return Make_Checkerboard_2D (8, 8, 0.0, 1.0);
   end Make_Example_Checker;

end Lanczos_Resampling;
