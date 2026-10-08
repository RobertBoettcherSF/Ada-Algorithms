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
   --  Floor division by 2, toward -infinity. Ada "/" truncates toward zero.
   --  Even negatives are already on a multiple of 2, so "/" matches floor.
   --  An odd negative is one below that. (N - 1) is not used: it overflows
   --  when N is Long_Integer'First.
   function Floor_Div_2 (N : Long_Integer) return Long_Integer is
   begin
      if N >= 0 or else N mod 2 = 0 then
         return N / 2;
      else
         return N / 2 - 1;
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
            X : constant Long_Integer := Input (Input'First + 2 * I);
            Y : constant Long_Integer := Input (Input'First + 2 * I + 1);
            --  Lifting: d = y - x, s = x + floor(d/2). Same value as
            --  floor((x+y)/2) when the sum fits, and x+y is never formed.
            D : constant Long_Integer := Y - X;
         begin
            Result (Out_Idx + I) := X + Floor_Div_2 (D);
            Result (Out_Idx + Half + I) := D;
         end;
      end loop;

      return Result;
   end Forward_Haar_1D_Lossless;

   function Inverse_Haar_1D_Lossless (Input : Signal_1D_Int) return Signal_1D_Int is
      Result  : Signal_1D_Int (Input'Range);
      Half    : constant Natural := Input'Length / 2;
      Out_Idx : constant Positive := Result'First;
      Avg, Diff : Long_Integer;
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

   --  Transform or invert the prefix of length Width. Width is even.
   procedure Lift_Prefix (Buf : in out Signal_1D_Int; Width : Positive; Forward : Boolean) is
      Half : constant Natural := Width / 2;
      Tmp  : Signal_1D_Int (1 .. Width);
   begin
      if Forward then
         for I in 0 .. Half - 1 loop
            declare
               X : constant Long_Integer := Buf (Buf'First + 2 * I);
               Y : constant Long_Integer := Buf (Buf'First + 2 * I + 1);
               D : constant Long_Integer := Y - X;
            begin
               Tmp (1 + I) := X + Floor_Div_2 (D);
               Tmp (1 + Half + I) := D;
            end;
         end loop;
      else
         for I in 0 .. Half - 1 loop
            declare
               S : constant Long_Integer := Buf (Buf'First + I);
               D : constant Long_Integer := Buf (Buf'First + Half + I);
               A : constant Long_Integer := S - Floor_Div_2 (D);
            begin
               Tmp (1 + 2 * I) := A;
               Tmp (1 + 2 * I + 1) := A + D;
            end;
         end loop;
      end if;
      for I in 0 .. Width - 1 loop
         Buf (Buf'First + I) := Tmp (1 + I);
      end loop;
   end Lift_Prefix;

   function Lowpass_Width (Length : Natural; Levels : Natural) return Natural is
      Width : Natural := Length;
   begin
      for L in 1 .. Levels loop
         if Width < 2 or else Width mod 2 /= 0 then
            raise Invalid_Dimensions with
              "Signal length must be divisible by 2**Levels.";
         end if;
         Width := Width / 2;
      end loop;
      return Width;
   end Lowpass_Width;

   function Forward_Haar_Levels
     (Input : Signal_1D_Int; Levels : Natural) return Signal_1D_Int
   is
      Result : Signal_1D_Int (Input'Range) := Input;
      Width  : Natural := Input'Length;
   begin
      if Levels = 0 or else Input'Length <= 1 then
         return Result;
      end if;
      for L in 1 .. Levels loop
         if Width < 2 or else Width mod 2 /= 0 then
            raise Invalid_Dimensions with
              "Signal length must be divisible by 2**Levels.";
         end if;
         Lift_Prefix (Result, Width, Forward => True);
         Width := Width / 2;
      end loop;
      return Result;
   end Forward_Haar_Levels;

   function Inverse_Haar_Levels
     (Input : Signal_1D_Int; Levels : Natural) return Signal_1D_Int
   is
      Result : Signal_1D_Int (Input'Range) := Input;
      Width  : Natural;
   begin
      if Levels = 0 or else Input'Length <= 1 then
         return Result;
      end if;
      Width := Lowpass_Width (Input'Length, Levels);
      while Width < Input'Length loop
         Width := Width * 2;
         Lift_Prefix (Result, Width, Forward => False);
      end loop;
      return Result;
   end Inverse_Haar_Levels;

end Wavelet_Compression;
