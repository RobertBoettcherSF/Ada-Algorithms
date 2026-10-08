-- wavelet_compression.adb
-- Implementation of the Wavelet Compression algorithms

package body Wavelet_Compression is

   -------------------------------------------------
   -- Lossy Compression (Floating Point) 1D
   -------------------------------------------------
   function Forward_Haar_1D (Input : Signal_1D) return Signal_1D is
      Result  : Signal_1D (Input'Range);
      Half    : constant Natural := Input'Length / 2;
      Out_Idx : constant Positive := Result'First;
   begin
      if Input'Length = 1 then
         return Input;
      end if;

      if Input'Length mod 2 /= 0 then
         raise Invalid_Dimensions with "Signal length must be a multiple of 2.";
      end if;

      for I in 0 .. Half - 1 loop
         -- Averages (Low-pass)
         Result (Out_Idx + I) := (Input (Input'First + 2*I) + Input (Input'First + 2*I + 1)) / 2.0;
         -- Differences/Details (High-pass)
         Result (Out_Idx + Half + I) := (Input (Input'First + 2*I) - Input (Input'First + 2*I + 1)) / 2.0;
      end loop;

      return Result;
   end Forward_Haar_1D;

   function Inverse_Haar_1D (Input : Signal_1D) return Signal_1D is
      Result  : Signal_1D (Input'Range);
      Half    : constant Natural := Input'Length / 2;
      Out_Idx : constant Positive := Result'First;
   begin
      if Input'Length = 1 then
         return Input;
      end if;

      if Input'Length mod 2 /= 0 then
         raise Invalid_Dimensions with "Signal length must be a multiple of 2.";
      end if;

      for I in 0 .. Half - 1 loop
         Result (Out_Idx + 2*I)     := Input (Input'First + I) + Input (Input'First + Half + I);
         Result (Out_Idx + 2*I + 1) := Input (Input'First + I) - Input (Input'First + Half + I);
      end loop;

      return Result;
   end Inverse_Haar_1D;

   -------------------------------------------------
   -- Lossy Compression (Floating Point) 2D
   -------------------------------------------------
   function Forward_Haar_2D (Input : Signal_2D) return Signal_2D is
      Rows   : constant Positive := Input'Length(1);
      Cols   : constant Positive := Input'Length(2);
      Temp   : Signal_2D (Input'Range(1), Input'Range(2));
      Result : Signal_2D (Input'Range(1), Input'Range(2));
      Row_1D : Signal_1D (1 .. Cols);
      Col_1D : Signal_1D (1 .. Rows);
   begin
      -- Process rows first
      for I in Input'Range(1) loop
         for J in Input'Range(2) loop
            Row_1D (1 + J - Input'First(2)) := Input (I, J);
         end loop;
         
         Row_1D := Forward_Haar_1D (Row_1D);
         
         for J in Input'Range(2) loop
            Temp (I, J) := Row_1D (1 + J - Input'First(2));
         end loop;
      end loop;

      -- Process columns next
      for J in Input'Range(2) loop
         for I in Input'Range(1) loop
            Col_1D (1 + I - Input'First(1)) := Temp (I, J);
         end loop;
         
         Col_1D := Forward_Haar_1D (Col_1D);
         
         for I in Input'Range(1) loop
            Result (I, J) := Col_1D (1 + I - Input'First(1));
         end loop;
      end loop;

      return Result;
   end Forward_Haar_2D;

   function Inverse_Haar_2D (Input : Signal_2D) return Signal_2D is
      Rows   : constant Positive := Input'Length(1);
      Cols   : constant Positive := Input'Length(2);
      Temp   : Signal_2D (Input'Range(1), Input'Range(2));
      Result : Signal_2D (Input'Range(1), Input'Range(2));
      Row_1D : Signal_1D (1 .. Cols);
      Col_1D : Signal_1D (1 .. Rows);
   begin
      -- Process columns first (inverse order)
      for J in Input'Range(2) loop
         for I in Input'Range(1) loop
            Col_1D (1 + I - Input'First(1)) := Input (I, J);
         end loop;
         
         Col_1D := Inverse_Haar_1D (Col_1D);
         
         for I in Input'Range(1) loop
            Temp (I, J) := Col_1D (1 + I - Input'First(1));
         end loop;
      end loop;

      -- Process rows
      for I in Input'Range(1) loop
         for J in Input'Range(2) loop
            Row_1D (1 + J - Input'First(2)) := Temp (I, J);
         end loop;
         
         Row_1D := Inverse_Haar_1D (Row_1D);
         
         for J in Input'Range(2) loop
            Result (I, J) := Row_1D (1 + J - Input'First(2));
         end loop;
      end loop;

      return Result;
   end Inverse_Haar_2D;

   -------------------------------------------------
   -- Quantization
   -------------------------------------------------
   function Quantize (Input : Signal_1D; Threshold : Float) return Signal_1D is
      Result : Signal_1D (Input'Range);
   begin
      for I in Input'Range loop
         if abs (Input (I)) < Threshold then
            Result (I) := 0.0;
         else
            Result (I) := Input (I);
         end if;
      end loop;
      return Result;
   end Quantize;

   -------------------------------------------------
   -- Lossless Compression (Integer Lifting Scheme) 1D
   -------------------------------------------------
   --  Floor division by 2 (toward -infinity). Ada "/" truncates toward zero,
   --  which is not the S-transform on a negative sum or detail.
   function Floor_Div_2 (N : Integer) return Integer is
   begin
      if N >= 0 then
         return N / 2;
      else
         return (N - 1) / 2;
      end if;
   end Floor_Div_2;

   function Forward_Haar_1D_Lossless (Input : Signal_1D_Int) return Signal_1D_Int is
      Result  : Signal_1D_Int (Input'Range);
      Half    : constant Natural := Input'Length / 2;
      Out_Idx : constant Positive := Result'First;
   begin
      if Input'Length = 1 then return Input; end if;
      if Input'Length mod 2 /= 0 then
         raise Invalid_Dimensions with "Signal length must be a multiple of 2.";
      end if;

      for I in 0 .. Half - 1 loop
         declare
            X : constant Integer := Input (Input'First + 2 * I);
            Y : constant Integer := Input (Input'First + 2 * I + 1);
         begin
            --  S-transform: s = floor((x+y)/2), d = y-x.
            Result (Out_Idx + I) := Floor_Div_2 (X + Y);
            Result (Out_Idx + Half + I) := Y - X;
         end;
      end loop;

      return Result;
   end Forward_Haar_1D_Lossless;

   function Inverse_Haar_1D_Lossless (Input : Signal_1D_Int) return Signal_1D_Int is
      Result  : Signal_1D_Int (Input'Range);
      Half    : constant Natural := Input'Length / 2;
      Out_Idx : constant Positive := Result'First;
      Avg, Diff : Integer;
   begin
      if Input'Length = 1 then return Input; end if;
      if Input'Length mod 2 /= 0 then
         raise Invalid_Dimensions with "Signal length must be a multiple of 2.";
      end if;

      for I in 0 .. Half - 1 loop
         Avg  := Input (Input'First + I);
         Diff := Input (Input'First + Half + I);

         --  x = s - floor(d/2), y = x + d.
         Result (Out_Idx + 2 * I) := Avg - Floor_Div_2 (Diff);
         Result (Out_Idx + 2 * I + 1) := Result (Out_Idx + 2 * I) + Diff;
      end loop;

      return Result;
   end Inverse_Haar_1D_Lossless;

end Wavelet_Compression;
