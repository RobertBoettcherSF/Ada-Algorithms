--  Geohash — Ada 2023 educational package for Wikipedia "Geohash"
--  (Gustavo Niemeyer, 2008; public domain). Encodes latitude/longitude into a
--  short base32 string via interleaved lon/lat bits (Z-order / Morton curve).
--  Longer shared prefixes imply spatial proximity (converse not guaranteed).
--  Alphabet omits a, i, l, o. Related: Morton 1966 geodetic file sequencing.

pragma Ada_2022;

package Geohash
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   --  Digits 15 for stable binary-search midpoints on the globe.
   type Real is digits 15;

   subtype Latitude  is Real range -90.0 .. 90.0;
   subtype Longitude is Real range -180.0 .. 180.0;

   --  Number of base32 characters in the hash (each char = 5 interleaved bits).
   subtype Precision_Type is Positive range 1 .. 12;

   ---------------------------------------------------------------------------
   -- Exceptions / alphabet
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   Invalid_Hash     : exception;

   --  Standard Geohash base32 (32ghs): digits 0-9 and letters except a,i,l,o.
   Base32_Alphabet : constant String :=
     "0123456789bcdefghjkmnpqrstuvwxyz";

   ---------------------------------------------------------------------------
   -- Result records
   ---------------------------------------------------------------------------

   type Bounding_Box is record
      Min_Lat : Latitude  := -90.0;
      Max_Lat : Latitude  :=  90.0;
      Min_Lon : Longitude := -180.0;
      Max_Lon : Longitude :=  180.0;
   end record;

   type Decode_Result is record
      Center_Lat : Latitude  := 0.0;
      Center_Lon : Longitude := 0.0;
      Box        : Bounding_Box;
   end record;

   --  Eight adjacent cells at the same precision (N .. NW).
   --  Each string is left-justified in 1 .. Len (characters beyond Len unused).
   type Neighbor_Set is record
      Len : Precision_Type := 1;
      N   : String (1 .. 12) := [others => ' '];
      NE  : String (1 .. 12) := [others => ' '];
      E   : String (1 .. 12) := [others => ' '];
      SE  : String (1 .. 12) := [others => ' '];
      S   : String (1 .. 12) := [others => ' '];
      SW  : String (1 .. 12) := [others => ' '];
      W   : String (1 .. 12) := [others => ' '];
      NW  : String (1 .. 12) := [others => ' '];
   end record;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-9;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Clamp_Latitude (Lat : Real) return Latitude
     with Global => null;

   function Normalize_Longitude (Lon : Real) return Longitude
     with Global => null;
   --  Wrap into [-180, 180].

   function Is_Valid_Hash (Hash : String) return Boolean
     with Global => null;
   --  Non-empty, length in 1 .. 12, every character in Base32_Alphabet
   --  (case-sensitive lowercase).

   function Common_Prefix_Length (A, B : String) return Natural
     with Global => null;

   ---------------------------------------------------------------------------
   -- Encode / Decode
   ---------------------------------------------------------------------------

   function Encode
     (Latitude_Deg  : Real;
      Longitude_Deg : Real;
      Precision     : Precision_Type := 12) return String
     with Global => null;
   --  Clamp lat to [-90,90], normalize lon to [-180,180], then binary-partition
   --  with lon bit, lat bit, lon bit, ... packing 5 bits per base32 character.

   function Decode (Hash : String) return Decode_Result
     with Global => null;
   --  Raises Invalid_Hash if Hash is empty or contains illegal characters.
   --  Center is the midpoint of the decoded cell bounding box.

   function Decode_BBox (Hash : String) return Bounding_Box
     with Global => null;

   function Contains
     (Box           : Bounding_Box;
      Latitude_Deg  : Real;
      Longitude_Deg : Real) return Boolean
     with Global => null;
   --  True if the (clamped/normalized) point lies in [Min,Max] inclusive.

   ---------------------------------------------------------------------------
   -- Neighbors (8-adjacent cells at the same precision)
   ---------------------------------------------------------------------------

   function Neighbors (Hash : String) return Neighbor_Set
     with Global => null;
   --  Eight hashes of equal length: N, NE, E, SE, S, SW, W, NW.
   --  Latitude is clamped at the poles; longitude wraps at ±180°.
   --  Use Neighbors(Hash).N (1 .. Neighbors(Hash).Len), etc.

   function Neighbor
     (Hash      : String;
      Lat_Delta : Integer;
      Lon_Delta : Integer) return String
     with Global => null;
   --  Single adjacent cell: Lat_Delta in {-1,0,1}, Lon_Delta in {-1,0,1},
   --  not both zero. Raises Invalid_Argument otherwise.

end Geohash;
