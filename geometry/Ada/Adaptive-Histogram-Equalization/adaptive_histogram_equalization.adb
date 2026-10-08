-- adaptive_histogram_equalization.adb
-- Implementations of the AHE variants and helper functions.

package body Adaptive_Histogram_Equalization is

   type Histogram_Type is array (Pixel_Type) of Natural;
   type CDF_Type is array (Pixel_Type) of Pixel_Type;

   -- Helper 1: Computes the histogram for a specific sub-region of an image
   function Compute_Histogram (Input : Image_Type; R_Min, R_Max, C_Min, C_Max : Positive) return Histogram_Type is
      Hist : Histogram_Type := (others => 0);
   begin
      for R in R_Min .. R_Max loop
         for C in C_Min .. C_Max loop
            Hist(Input(R, C)) := Hist(Input(R, C)) + 1;
         end loop;
      end loop;
      return Hist;
   end Compute_Histogram;

   -- Helper 2: Computes the Cumulative Distribution Function (CDF) mapping
   -- Total_Pixels changed to Natural to safely allow zero-checks without compiler warnings
   function Compute_CDF (Hist : Histogram_Type; Total_Pixels : Natural) return CDF_Type is
      CDF : CDF_Type := (others => 0);
      Sum : Natural := 0;
   begin
      if Total_Pixels = 0 then 
         return CDF; 
      end if;
      
      for I in Pixel_Type loop
         Sum := Sum + Hist(I);
         -- Scale the CDF output strictly to the pixel range (0-255)
         CDF(I) := Pixel_Type(Float(Sum) * 255.0 / Float(Total_Pixels));
      end loop;
      return CDF;
   end Compute_CDF;

   -- Helper 3: Clips the histogram for CLAHE and redistributes excess pixels evenly
   procedure Clip_Histogram (Hist : in out Histogram_Type; Clip_Limit : Natural) is
      Excess    : Natural := 0;
      Bin_Incr  : Natural;
      Remainder : Natural;
      Step      : Natural;
   begin
      if Clip_Limit = 0 then
         return; 
      end if;

      -- Calculate total excess over the clip limit
      for I in Pixel_Type loop
         if Hist(I) > Clip_Limit then
            Excess := Excess + (Hist(I) - Clip_Limit);
            Hist(I) := Clip_Limit;
         end if;
      end loop;

      -- Redistribute excess pixels across all bins uniformly
      if Excess > 0 then
         Bin_Incr  := Excess / 256;
         Remainder := Excess mod 256;
         
         for I in Pixel_Type loop
            Hist(I) := Hist(I) + Bin_Incr;
         end loop;
         
         if Remainder > 0 then
            Step := 256 / Remainder;
            for I in 0 .. Remainder - 1 loop
               Hist(Pixel_Type(I * Step)) := Hist(Pixel_Type(I * Step)) + 1;
            end loop;
         end if;
      end if;
   end Clip_Histogram;

   -- 1. Standard Global Histogram Equalization
   procedure Global_HE (Input : in Image_Type; Output : out Image_Type) is
      Hist  : Histogram_Type;
      CDF   : CDF_Type;
      Total : Natural;
   begin
      if Input'Length(1) = 0 or Input'Length(2) = 0 then
         raise Invalid_Image;
      end if;
      if Input'Length(1) /= Output'Length(1) or Input'Length(2) /= Output'Length(2) then
         raise Invalid_Image;
      end if;

      Total := Input'Length(1) * Input'Length(2);
      Hist  := Compute_Histogram (Input, Input'First(1), Input'Last(1), Input'First(2), Input'Last(2));
      CDF   := Compute_CDF (Hist, Total);

      for R in Input'Range(1) loop
         for C in Input'Range(2) loop
            Output(R, C) := CDF(Input(R, C));
         end loop;
      end loop;
   end Global_HE;

   -- 2. Sliding Window AHE
   procedure Sliding_Window_AHE (Input : in Image_Type; Output : out Image_Type; Window_Size : in Positive) is
      Half_Win : constant Natural := Window_Size / 2;
   begin
      if Input'Length(1) = 0 or Input'Length(2) = 0 then raise Invalid_Image; end if;
      if Input'Length(1) /= Output'Length(1) or Input'Length(2) /= Output'Length(2) then raise Invalid_Image; end if;
      if Window_Size mod 2 = 0 then raise Invalid_Window; end if;

      for R in Input'Range(1) loop
         for C in Input'Range(2) loop
            declare
               -- Establish bounds carefully to handle image edges
               R_Min : constant Positive := Integer'Max (Input'First(1), R - Half_Win);
               R_Max : constant Positive := Integer'Min (Input'Last(1),  R + Half_Win);
               C_Min : constant Positive := Integer'Max (Input'First(2), C - Half_Win);
               C_Max : constant Positive := Integer'Min (Input'Last(2),  C + Half_Win);
               
               Hist  : constant Histogram_Type := Compute_Histogram (Input, R_Min, R_Max, C_Min, C_Max);
               Total : constant Positive := (R_Max - R_Min + 1) * (C_Max - C_Min + 1);
               CDF   : constant CDF_Type := Compute_CDF (Hist, Total);
            begin
               Output(R, C) := CDF(Input(R, C));
            end;
         end loop;
      end loop;
   end Sliding_Window_AHE;

   -- 3. Sliding Window CLAHE
   procedure Sliding_Window_CLAHE (Input : in Image_Type; Output : out Image_Type; Window_Size : in Positive; Clip_Limit : in Natural) is
      Half_Win : constant Natural := Window_Size / 2;
   begin
      if Input'Length(1) = 0 or Input'Length(2) = 0 then raise Invalid_Image; end if;
      if Input'Length(1) /= Output'Length(1) or Input'Length(2) /= Output'Length(2) then raise Invalid_Image; end if;
      if Window_Size mod 2 = 0 then raise Invalid_Window; end if;

      for R in Input'Range(1) loop
         for C in Input'Range(2) loop
            declare
               R_Min : constant Positive := Integer'Max (Input'First(1), R - Half_Win);
               R_Max : constant Positive := Integer'Min (Input'Last(1),  R + Half_Win);
               C_Min : constant Positive := Integer'Max (Input'First(2), C - Half_Win);
               C_Max : constant Positive := Integer'Min (Input'Last(2),  C + Half_Win);
               
               Hist  : Histogram_Type := Compute_Histogram (Input, R_Min, R_Max, C_Min, C_Max);
               Total : constant Positive := (R_Max - R_Min + 1) * (C_Max - C_Min + 1);
            begin
               Clip_Histogram(Hist, Clip_Limit);
               declare
                  CDF : constant CDF_Type := Compute_CDF (Hist, Total);
               begin
                  Output(R, C) := CDF(Input(R, C));
               end;
            end;
         end loop;
      end loop;
   end Sliding_Window_CLAHE;

   -- 4. Block-Based CLAHE (Tiled Approach)
   procedure Block_Based_CLAHE (Input : in Image_Type; Output : out Image_Type; Grid_Rows : in Positive; Grid_Cols : in Positive; Clip_Limit : in Natural) is
      type CDF_Grid is array (1 .. Grid_Rows, 1 .. Grid_Cols) of CDF_Type;
      CDFs : CDF_Grid;
   begin
      if Input'Length(1) = 0 or Input'Length(2) = 0 then raise Invalid_Image; end if;
      if Input'Length(1) /= Output'Length(1) or Input'Length(2) /= Output'Length(2) then raise Invalid_Image; end if;
      if Grid_Rows > Input'Length(1) or Grid_Cols > Input'Length(2) then raise Invalid_Grid; end if;

      -- Step A: Compute clipped CDF for every grid tile strictly bounded by integers
      for GR in 1 .. Grid_Rows loop
         for GC in 1 .. Grid_Cols loop
            declare
               R_Min : constant Positive := Input'First(1) + ((GR - 1) * Input'Length(1)) / Grid_Rows;
               R_Max : constant Positive := Input'First(1) + (GR * Input'Length(1)) / Grid_Rows - 1;
               C_Min : constant Positive := Input'First(2) + ((GC - 1) * Input'Length(2)) / Grid_Cols;
               C_Max : constant Positive := Input'First(2) + (GC * Input'Length(2)) / Grid_Cols - 1;
               
               Hist  : Histogram_Type := Compute_Histogram (Input, R_Min, R_Max, C_Min, C_Max);
               Total : constant Positive := (R_Max - R_Min + 1) * (C_Max - C_Min + 1);
            begin
               Clip_Histogram(Hist, Clip_Limit);
               CDFs(GR, GC) := Compute_CDF(Hist, Total);
            end;
         end loop;
      end loop;

      -- Step B: Apply mapping via Block Nearest Neighbor
      for R in Input'Range(1) loop
         for C in Input'Range(2) loop
            declare
               R_Off : constant Natural := R - Input'First(1);
               C_Off : constant Natural := C - Input'First(2);
               GR : Positive := (R_Off * Grid_Rows) / Input'Length(1) + 1;
               GC : Positive := (C_Off * Grid_Cols) / Input'Length(2) + 1;
            begin
               if GR > Grid_Rows then GR := Grid_Rows; end if;
               if GC > Grid_Cols then GC := Grid_Cols; end if;
               Output(R, C) := CDFs(GR, GC)(Input(R, C));
            end;
         end loop;
      end loop;
   end Block_Based_CLAHE;

end Adaptive_Histogram_Equalization;
