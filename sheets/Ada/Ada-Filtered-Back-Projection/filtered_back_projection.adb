--  Filtered_Back_Projection body — discrete parallel-beam FBP with
--  spatial Ram-Lak convolution (educational Float).

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;

package body Filtered_Back_Projection
  with SPARK_Mode => Off
is

   use Ada.Numerics.Elementary_Functions;

   Pi : constant Float := Float (Ada.Numerics.Pi);

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Near_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Is_Valid_Image (Img : Image_2D) return Boolean is
   begin
      return Img.Valid and then Img.N >= 1;
   end Is_Valid_Image;

   function Is_Valid_Sinogram (S : Sinogram) return Boolean is
   begin
      return S.Valid
        and then S.N_Angles >= 1
        and then S.N_Bins >= 1;
   end Is_Valid_Sinogram;

   function Large_Enough_Image (Img : Image_2D) return Boolean is
   begin
      return Is_Valid_Image (Img) and then Img.N >= Min_N;
   end Large_Enough_Image;

   function Large_Enough_Sinogram (S : Sinogram) return Boolean is
   begin
      return Is_Valid_Sinogram (S)
        and then S.N_Angles >= Min_Angles
        and then S.N_Bins >= Min_Bins;
   end Large_Enough_Sinogram;

   function Get (Img : Image_2D; I, J : Axis_Index) return Float is
   begin
      return Img.Values (I, J);
   end Get;

   procedure Set
     (Img   : in out Image_2D;
      I, J  : Axis_Index;
      Value : Float)
   is
   begin
      Img.Values (I, J) := Value;
   end Set;

   function Get (S : Sinogram; A : Angle_Index; B : Bin_Index) return Float is
   begin
      return S.Values (A, B);
   end Get;

   procedure Set
     (S     : in out Sinogram;
      A     : Angle_Index;
      B     : Bin_Index;
      Value : Float)
   is
   begin
      S.Values (A, B) := Value;
   end Set;

   function Image_Sum (Img : Image_2D) return Float is
      Acc : Float := 0.0;
   begin
      if not Is_Valid_Image (Img) then
         return 0.0;
      end if;
      for I in 0 .. Img.N - 1 loop
         for J in 0 .. Img.N - 1 loop
            Acc := Acc + Img.Values (I, J);
         end loop;
      end loop;
      return Acc;
   end Image_Sum;

   function Sinogram_Angle_Sum
     (S : Sinogram; A : Angle_Index) return Float
   is
      Acc : Float := 0.0;
   begin
      if not Is_Valid_Sinogram (S) or else A >= S.N_Angles then
         return 0.0;
      end if;
      for B in 0 .. S.N_Bins - 1 loop
         Acc := Acc + S.Values (A, B);
      end loop;
      return Acc;
   end Sinogram_Angle_Sum;

   function Correlation (A, B : Image_2D) return Correlation_Result is
      R      : Correlation_Result;
      Mean_A : Float := 0.0;
      Mean_B : Float := 0.0;
      Num    : Float := 0.0;
      Den_A  : Float := 0.0;
      Den_B  : Float := 0.0;
      Count  : Float;
      DA, DB : Float;
   begin
      if not Is_Valid_Image (A) or else not Is_Valid_Image (B) then
         R.Stat := Ill_Started;
         return R;
      end if;
      if A.N /= B.N then
         R.Stat := Dimension_Error;
         return R;
      end if;
      if A.N < 2 then
         R.Stat := Too_Small;
         return R;
      end if;

      Count := Float (A.N * A.N);
      for I in 0 .. A.N - 1 loop
         for J in 0 .. A.N - 1 loop
            Mean_A := Mean_A + A.Values (I, J);
            Mean_B := Mean_B + B.Values (I, J);
         end loop;
      end loop;
      Mean_A := Mean_A / Count;
      Mean_B := Mean_B / Count;

      for I in 0 .. A.N - 1 loop
         for J in 0 .. A.N - 1 loop
            DA := A.Values (I, J) - Mean_A;
            DB := B.Values (I, J) - Mean_B;
            Num := Num + DA * DB;
            Den_A := Den_A + DA * DA;
            Den_B := Den_B + DB * DB;
         end loop;
      end loop;

      if Den_A <= 0.0 or else Den_B <= 0.0 then
         --  Constant fields: correlation undefined / treat as Ok with 0
         --  when both constant-equal, else 0.
         R.Value := 0.0;
         R.Stat := Ok;
         R.Success := True;
         return R;
      end if;

      R.Value := Num / Sqrt (Den_A * Den_B);
      R.Stat := Ok;
      R.Success := True;
      return R;
   end Correlation;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Make_Empty_Image (N : Axis_Size) return Image_2D is
      Img : Image_2D;
   begin
      Img.N := N;
      Img.Valid := True;
      --  Values already zero-initialized
      return Img;
   end Make_Empty_Image;

   function Make_Empty_Sinogram
     (N_Angles : Angle_Size; N_Bins : Bin_Size) return Sinogram
   is
      S : Sinogram;
   begin
      S.N_Angles := N_Angles;
      S.N_Bins := N_Bins;
      S.Valid := True;
      return S;
   end Make_Empty_Sinogram;

   function Make_Disk_Phantom
     (N : Axis_Size; Radius : Float) return Image_Result
   is
      R  : Image_Result;
      Cx : Float;
      Cy : Float;
      Dx : Float;
      Dy : Float;
   begin
      if N = 0 then
         R.Stat := Ill_Started;
         return R;
      end if;
      if Radius <= 0.0 then
         R.Stat := Ill_Started;
         return R;
      end if;
      if N < Min_N then
         R.Stat := Too_Small;
         return R;
      end if;

      R.Image := Make_Empty_Image (N);
      Cx := 0.5 * Float (N - 1);
      Cy := 0.5 * Float (N - 1);
      for I in 0 .. N - 1 loop
         for J in 0 .. N - 1 loop
            Dx := Float (I) - Cx;
            Dy := Float (J) - Cy;
            if Dx * Dx + Dy * Dy <= Radius * Radius then
               R.Image.Values (I, J) := 1.0;
            end if;
         end loop;
      end loop;
      R.Stat := Ok;
      R.Success := True;
      return R;
   end Make_Disk_Phantom;

   function Make_Shepp_Lite (N : Axis_Size) return Image_Result is
      R     : Image_Result;
      Outer : Image_Result;
      Rad   : Float;
      Cx    : Float;
      Cy    : Float;
      R1    : Float;
      R2    : Float;
      Ox1, Oy1, Ox2, Oy2 : Float;
      Dx, Dy : Float;
   begin
      if N = 0 then
         R.Stat := Ill_Started;
         return R;
      end if;
      if N < Min_N then
         R.Stat := Too_Small;
         return R;
      end if;

      Rad := Float (N) / 3.0;
      Outer := Make_Disk_Phantom (N, Rad);
      if not Outer.Success then
         return Outer;
      end if;
      R.Image := Outer.Image;

      --  Overlay two smaller offset disks (teaching contrast only).
      Cx := 0.5 * Float (N - 1);
      Cy := 0.5 * Float (N - 1);
      R1 := Float (N) / 8.0;
      R2 := Float (N) / 10.0;
      Ox1 := -Float (N) / 8.0;
      Oy1 := Float (N) / 10.0;
      Ox2 := Float (N) / 7.0;
      Oy2 := -Float (N) / 9.0;
      for I in 0 .. N - 1 loop
         for J in 0 .. N - 1 loop
            Dx := Float (I) - (Cx + Ox1);
            Dy := Float (J) - (Cy + Oy1);
            if Dx * Dx + Dy * Dy <= R1 * R1 then
               R.Image.Values (I, J) := 0.4;
            end if;
            Dx := Float (I) - (Cx + Ox2);
            Dy := Float (J) - (Cy + Oy2);
            if Dx * Dx + Dy * Dy <= R2 * R2 then
               R.Image.Values (I, J) := 0.7;
            end if;
         end loop;
      end loop;

      R.Stat := Ok;
      R.Success := True;
      return R;
   end Make_Shepp_Lite;

   ---------------------------------------------------------------------------
   -- Ram-Lak kernel
   ---------------------------------------------------------------------------

   function Ram_Lak_Kernel_Value (K : Integer) return Float is
      Kf : Float;
   begin
      if K = 0 then
         return 0.25;
      end if;
      if K mod 2 = 0 then
         return 0.0;
      end if;
      Kf := Float (abs (K));
      return -1.0 / (Pi * Pi * Kf * Kf);
   end Ram_Lak_Kernel_Value;

   ---------------------------------------------------------------------------
   -- Forward project
   ---------------------------------------------------------------------------

   function Forward_Project
     (Img      : Image_2D;
      N_Angles : Angle_Size;
      N_Bins   : Bin_Size) return Sinogram_Result
   is
      R     : Sinogram_Result;
      Cx    : Float;
      Cy    : Float;
      Half  : Float;
      Theta : Float;
      C, S  : Float;
      T     : Float;
      Acc   : Float;
      U     : Float;
      U_Max : Float;
      Du    : constant Float := 0.5;
      X, Y  : Float;
      Ix, Iy : Integer;
      Sample : Float;
   begin
      if not Is_Valid_Image (Img) then
         R.Stat := Ill_Started;
         return R;
      end if;
      if N_Angles = 0 or else N_Bins = 0 then
         R.Stat := Ill_Started;
         return R;
      end if;
      if Img.N < Min_N
        or else N_Angles < Min_Angles
        or else N_Bins < Min_Bins
      then
         R.Stat := Too_Small;
         return R;
      end if;

      R.Sino := Make_Empty_Sinogram (N_Angles, N_Bins);
      Cx := 0.5 * Float (Img.N - 1);
      Cy := 0.5 * Float (Img.N - 1);
      Half := 0.5 * Float (N_Bins - 1);
      U_Max := 0.75 * Float (Img.N);

      for A in 0 .. N_Angles - 1 loop
         Theta := Float (A) * Pi / Float (N_Angles);
         C := Cos (Theta);
         S := Sin (Theta);
         for B in 0 .. N_Bins - 1 loop
            T := Float (B) - Half;
            Acc := 0.0;
            U := -U_Max;
            while U <= U_Max + 1.0E-6 loop
               X := Cx + T * C - U * S;
               Y := Cy + T * S + U * C;
               Ix := Integer (Float'Rounding (X));
               Iy := Integer (Float'Rounding (Y));
               if Ix >= 0 and then Ix < Integer (Img.N)
                 and then Iy >= 0 and then Iy < Integer (Img.N)
               then
                  Sample :=
                    Img.Values (Axis_Index (Ix), Axis_Index (Iy));
                  Acc := Acc + Sample;
               end if;
               U := U + Du;
            end loop;
            R.Sino.Values (A, B) := Acc * Du;
         end loop;
      end loop;

      R.Stat := Ok;
      R.Success := True;
      return R;
   end Forward_Project;

   ---------------------------------------------------------------------------
   -- Filter (spatial Ram-Lak)
   ---------------------------------------------------------------------------

   function Filter_Ram_Lak (S : Sinogram) return Sinogram_Result is
      R    : Sinogram_Result;
      Acc  : Float;
      Half : Integer;
      J    : Integer;
      Hk   : Float;
   begin
      if not Is_Valid_Sinogram (S) then
         R.Stat := Ill_Started;
         return R;
      end if;
      if not Large_Enough_Sinogram (S) then
         R.Stat := Too_Small;
         return R;
      end if;

      R.Sino := Make_Empty_Sinogram (S.N_Angles, S.N_Bins);
      --  Kernel support: lags −(N_Bins−1) .. +(N_Bins−1)
      Half := Integer (S.N_Bins) - 1;

      for A in 0 .. S.N_Angles - 1 loop
         for B in 0 .. S.N_Bins - 1 loop
            Acc := 0.0;
            for K in -Half .. Half loop
               J := Integer (B) + K;
               if J >= 0 and then J < Integer (S.N_Bins) then
                  Hk := Ram_Lak_Kernel_Value (K);
                  Acc := Acc
                    + S.Values (A, Bin_Index (J)) * Hk;
               end if;
            end loop;
            R.Sino.Values (A, B) := Acc;
         end loop;
      end loop;

      R.Stat := Ok;
      R.Success := True;
      return R;
   end Filter_Ram_Lak;

   ---------------------------------------------------------------------------
   -- Back-project
   ---------------------------------------------------------------------------

   function Back_Project
     (S : Sinogram; N : Axis_Size) return Image_Result
   is
      R      : Image_Result;
      Cx     : Float;
      Cy     : Float;
      Half   : Float;
      Acc    : Float;
      Theta  : Float;
      C, Sn  : Float;
      T      : Float;
      Tf     : Float;
      I0, I1 : Integer;
      W      : Float;
      V0, V1 : Float;
      X, Y   : Float;
      Scale  : Float;
   begin
      if not Is_Valid_Sinogram (S) then
         R.Stat := Ill_Started;
         return R;
      end if;
      if N = 0 then
         R.Stat := Ill_Started;
         return R;
      end if;
      if N < Min_N or else not Large_Enough_Sinogram (S) then
         R.Stat := Too_Small;
         return R;
      end if;
      --  Detector span should cover the image extent (unit spacing).
      if Integer (S.N_Bins) < Integer (N) then
         R.Stat := Dimension_Error;
         return R;
      end if;

      R.Image := Make_Empty_Image (N);
      Cx := 0.5 * Float (N - 1);
      Cy := 0.5 * Float (N - 1);
      Half := 0.5 * Float (S.N_Bins - 1);
      Scale := Pi / Float (S.N_Angles);

      for I in 0 .. N - 1 loop
         for J in 0 .. N - 1 loop
            X := Float (I) - Cx;
            Y := Float (J) - Cy;
            Acc := 0.0;
            for A in 0 .. S.N_Angles - 1 loop
               Theta := Float (A) * Pi / Float (S.N_Angles);
               C := Cos (Theta);
               Sn := Sin (Theta);
               T := X * C + Y * Sn;
               Tf := T + Half;
               I0 := Integer (Float'Floor (Tf));
               I1 := I0 + 1;
               W := Tf - Float (I0);
               if I0 >= 0 and then I0 < Integer (S.N_Bins) then
                  V0 := S.Values (A, Bin_Index (I0));
               else
                  V0 := 0.0;
               end if;
               if I1 >= 0 and then I1 < Integer (S.N_Bins) then
                  V1 := S.Values (A, Bin_Index (I1));
               else
                  V1 := 0.0;
               end if;
               Acc := Acc + (1.0 - W) * V0 + W * V1;
            end loop;
            R.Image.Values (I, J) := Acc * Scale;
         end loop;
      end loop;

      R.Stat := Ok;
      R.Success := True;
      return R;
   end Back_Project;

   ---------------------------------------------------------------------------
   -- Full reconstruct
   ---------------------------------------------------------------------------

   function Reconstruct_FBP
     (Img      : Image_2D;
      N_Angles : Angle_Size;
      N_Bins   : Bin_Size) return Image_Result
   is
      R    : Image_Result;
      Fwd  : Sinogram_Result;
      Filt : Sinogram_Result;
   begin
      if not Is_Valid_Image (Img) then
         R.Stat := Ill_Started;
         return R;
      end if;
      if N_Angles = 0 or else N_Bins = 0 then
         R.Stat := Ill_Started;
         return R;
      end if;
      if Img.N < Min_N
        or else N_Angles < Min_Angles
        or else N_Bins < Min_Bins
      then
         R.Stat := Too_Small;
         return R;
      end if;
      if Integer (N_Bins) < Integer (Img.N) then
         R.Stat := Dimension_Error;
         return R;
      end if;

      Fwd := Forward_Project (Img, N_Angles, N_Bins);
      if not Fwd.Success then
         R.Stat := Fwd.Stat;
         return R;
      end if;

      Filt := Filter_Ram_Lak (Fwd.Sino);
      if not Filt.Success then
         R.Stat := Filt.Stat;
         return R;
      end if;

      return Back_Project (Filt.Sino, Img.N);
   end Reconstruct_FBP;

end Filtered_Back_Projection;
