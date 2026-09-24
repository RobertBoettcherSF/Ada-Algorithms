--  Geohash body — Niemeyer base32 encode/decode with lon/lat bit interleave.

pragma Ada_2022;

package body Geohash
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Local helpers
   -------------------------------------------------------------------------

   function Char_Index (C : Character) return Integer is
   begin
      for I in Base32_Alphabet'Range loop
         if Base32_Alphabet (I) = C then
            return I - Base32_Alphabet'First;
         end if;
      end loop;
      return -1;
   end Char_Index;

   function Bit_On (Value : Natural; Mask : Natural) return Boolean is
   begin
      return (Value / Mask) rem 2 = 1;
   end Bit_On;

   function Clamp_Lon_Bound (X : Real) return Longitude is
   begin
      if X < -180.0 then
         return -180.0;
      elsif X > 180.0 then
         return 180.0;
      else
         return X;
      end if;
   end Clamp_Lon_Bound;

   -------------------------------------------------------------------------
   -- Near / Clamp / Normalize
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Clamp_Latitude (Lat : Real) return Latitude is
   begin
      if Lat < -90.0 then
         return -90.0;
      elsif Lat > 90.0 then
         return 90.0;
      else
         return Lat;
      end if;
   end Clamp_Latitude;

   function Normalize_Longitude (Lon : Real) return Longitude is
      X : Real := Lon;
   begin
      while X > 180.0 loop
         X := X - 360.0;
      end loop;
      while X < -180.0 loop
         X := X + 360.0;
      end loop;
      if X > 180.0 then
         X := -180.0;
      end if;
      return X;
   end Normalize_Longitude;

   -------------------------------------------------------------------------
   -- Validation / prefix
   -------------------------------------------------------------------------

   function Is_Valid_Hash (Hash : String) return Boolean is
   begin
      if Hash'Length = 0 or else Hash'Length > 12 then
         return False;
      end if;
      for C of Hash loop
         if Char_Index (C) < 0 then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid_Hash;

   function Common_Prefix_Length (A, B : String) return Natural is
      N     : constant Natural := Natural'Min (A'Length, B'Length);
      Count : Natural := 0;
   begin
      for I in 0 .. N - 1 loop
         if A (A'First + I) = B (B'First + I) then
            Count := Count + 1;
         else
            exit;
         end if;
      end loop;
      return Count;
   end Common_Prefix_Length;

   -------------------------------------------------------------------------
   -- Encode
   -------------------------------------------------------------------------

   function Encode
     (Latitude_Deg  : Real;
      Longitude_Deg : Real;
      Precision     : Precision_Type := 12) return String
   is
      Lat : constant Latitude  := Clamp_Latitude (Latitude_Deg);
      Lon : constant Longitude := Normalize_Longitude (Longitude_Deg);

      Lat_Min : Real := -90.0;
      Lat_Max : Real :=  90.0;
      Lon_Min : Real := -180.0;
      Lon_Max : Real :=  180.0;

      Result : String (1 .. Precision);
      Bit    : Natural;
      Ch     : Natural;
      Even   : Boolean := True;  --  True => next bit is longitude
      Mid    : Real;
   begin
      for Pos in 1 .. Precision loop
         Bit := 0;
         Ch  := 0;
         while Bit < 5 loop
            if Even then
               Mid := (Lon_Min + Lon_Max) / 2.0;
               if Lon >= Mid then
                  Ch := Ch * 2 + 1;
                  Lon_Min := Mid;
               else
                  Ch := Ch * 2;
                  Lon_Max := Mid;
               end if;
            else
               Mid := (Lat_Min + Lat_Max) / 2.0;
               if Lat >= Mid then
                  Ch := Ch * 2 + 1;
                  Lat_Min := Mid;
               else
                  Ch := Ch * 2;
                  Lat_Max := Mid;
               end if;
            end if;
            Even := not Even;
            Bit  := Bit + 1;
         end loop;
         Result (Pos) :=
           Base32_Alphabet (Base32_Alphabet'First + Ch);
      end loop;
      return Result;
   end Encode;

   -------------------------------------------------------------------------
   -- Decode
   -------------------------------------------------------------------------

   function Decode_BBox (Hash : String) return Bounding_Box is
      Lat_Min : Real := -90.0;
      Lat_Max : Real :=  90.0;
      Lon_Min : Real := -180.0;
      Lon_Max : Real :=  180.0;
      Even    : Boolean := True;
      Idx     : Integer;
      Mid     : Real;
      Mask    : Natural;
   begin
      if not Is_Valid_Hash (Hash) then
         raise Invalid_Hash;
      end if;

      for C of Hash loop
         Idx  := Char_Index (C);
         Mask := 16;
         for Unused in 1 .. 5 loop
            pragma Unreferenced (Unused);
            if Even then
               Mid := (Lon_Min + Lon_Max) / 2.0;
               if Bit_On (Natural (Idx), Mask) then
                  Lon_Min := Mid;
               else
                  Lon_Max := Mid;
               end if;
            else
               Mid := (Lat_Min + Lat_Max) / 2.0;
               if Bit_On (Natural (Idx), Mask) then
                  Lat_Min := Mid;
               else
                  Lat_Max := Mid;
               end if;
            end if;
            Even := not Even;
            Mask := Mask / 2;
         end loop;
      end loop;

      return
        (Min_Lat => Clamp_Latitude (Lat_Min),
         Max_Lat => Clamp_Latitude (Lat_Max),
         Min_Lon => Clamp_Lon_Bound (Lon_Min),
         Max_Lon => Clamp_Lon_Bound (Lon_Max));
   end Decode_BBox;

   function Decode (Hash : String) return Decode_Result is
      Box : constant Bounding_Box := Decode_BBox (Hash);
      CL  : constant Real :=
        (Real (Box.Min_Lat) + Real (Box.Max_Lat)) / 2.0;
      CO  : constant Real :=
        (Real (Box.Min_Lon) + Real (Box.Max_Lon)) / 2.0;
   begin
      return
        (Center_Lat => Clamp_Latitude (CL),
         Center_Lon => Clamp_Lon_Bound (CO),
         Box        => Box);
   end Decode;

   function Contains
     (Box           : Bounding_Box;
      Latitude_Deg  : Real;
      Longitude_Deg : Real) return Boolean
   is
      Lat : constant Latitude  := Clamp_Latitude (Latitude_Deg);
      Lon : constant Longitude := Normalize_Longitude (Longitude_Deg);
   begin
      return Lat >= Box.Min_Lat and then Lat <= Box.Max_Lat
        and then Lon >= Box.Min_Lon and then Lon <= Box.Max_Lon;
   end Contains;

   -------------------------------------------------------------------------
   -- Neighbors
   -------------------------------------------------------------------------

   function Neighbor
     (Hash      : String;
      Lat_Delta : Integer;
      Lon_Delta : Integer) return String
   is
      Box  : Bounding_Box;
      DLat : Real;
      DLon : Real;
      Lat  : Real;
      Lon  : Real;
      Prec : Precision_Type;
   begin
      if not Is_Valid_Hash (Hash) then
         raise Invalid_Hash;
      end if;
      if Lat_Delta not in -1 .. 1
        or else Lon_Delta not in -1 .. 1
        or else (Lat_Delta = 0 and then Lon_Delta = 0)
      then
         raise Invalid_Argument;
      end if;

      Prec := Hash'Length;
      Box  := Decode_BBox (Hash);
      DLat := Real (Box.Max_Lat) - Real (Box.Min_Lat);
      DLon := Real (Box.Max_Lon) - Real (Box.Min_Lon);

      Lat := (Real (Box.Min_Lat) + Real (Box.Max_Lat)) / 2.0
        + Real (Lat_Delta) * DLat;
      Lon := (Real (Box.Min_Lon) + Real (Box.Max_Lon)) / 2.0
        + Real (Lon_Delta) * DLon;

      Lat := Real (Clamp_Latitude (Lat));
      Lon := Real (Normalize_Longitude (Lon));

      return Encode (Lat, Lon, Prec);
   end Neighbor;

   function Neighbors (Hash : String) return Neighbor_Set is
      Result : Neighbor_Set;
      Prec   : Precision_Type;

      procedure Store (Target : in out String; Value : String) is
         F : constant Natural := Target'First;
      begin
         Target := [others => ' '];
         Target (F .. F + Value'Length - 1) := Value;
      end Store;
   begin
      if not Is_Valid_Hash (Hash) then
         raise Invalid_Hash;
      end if;
      Prec        := Hash'Length;
      Result.Len  := Prec;

      declare
         N_Str  : constant String := Neighbor (Hash,  1,  0);
         NE_Str : constant String := Neighbor (Hash,  1,  1);
         E_Str  : constant String := Neighbor (Hash,  0,  1);
         SE_Str : constant String := Neighbor (Hash, -1,  1);
         S_Str  : constant String := Neighbor (Hash, -1,  0);
         SW_Str : constant String := Neighbor (Hash, -1, -1);
         W_Str  : constant String := Neighbor (Hash,  0, -1);
         NW_Str : constant String := Neighbor (Hash,  1, -1);
      begin
         Store (Result.N,  N_Str);
         Store (Result.NE, NE_Str);
         Store (Result.E,  E_Str);
         Store (Result.SE, SE_Str);
         Store (Result.S,  S_Str);
         Store (Result.SW, SW_Str);
         Store (Result.W,  W_Str);
         Store (Result.NW, NW_Str);
      end;
      return Result;
   end Neighbors;

end Geohash;
