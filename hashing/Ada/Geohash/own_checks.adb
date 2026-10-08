--  Own checks (see tests/SOURCES.txt). Assume Geohash is wrong or does
--  nothing; compare it with references that use a different method: cell
--  indices by integer arithmetic (the largest I with -180 + 360 * I / 2**K
--  <= Lon, checked with exact dyadic products), bits interleaved and packed
--  by hand, and boxes / neighbours computed from the indices instead of by
--  repeated halving. Seeded random points at every precision 1 .. 12, exact
--  cell corners, both poles and the date line.
pragma Ada_2022;
with Ada.Text_IO;
with Geohash; use Geohash;

procedure Own_Checks is
   Alphabet : constant String := "0123456789bcdefghjkmnpqrstuvwxyz";
   subtype Index is Long_Long_Integer;
   Seed : Long_Long_Integer := 20261008;
   Checked : Natural := 0;

   function Rand return Long_Long_Integer is   --  Park-Miller
   begin
      Seed := (Seed * 16807) mod 2147483647;
      return Seed;
   end Rand;

   function Lon_Bits (P : Precision_Type) return Natural is ((5 * P + 1) / 2);
   function Lat_Bits (P : Precision_Type) return Natural is (5 * P / 2);

   --  largest I in 0 .. 2**K - 1 with Lo + Span * I / 2**K <= V
   function Cell (V, Lo, Span : Real; K : Natural) return Index is
      N : constant Index := 2 ** K;
      I : Index := Index (Real'Floor ((V - Lo) / Span * Real (N)));
   begin
      I := Index'Max (0, Index'Min (N - 1, I));
      while I > 0 and then Lo + Span * Real (I) / Real (N) > V loop I := I - 1; end loop;
      while I < N - 1 and then Lo + Span * Real (I + 1) / Real (N) <= V loop I := I + 1; end loop;
      return I;
   end Cell;

   function Pack (ILon, ILat : Index; P : Precision_Type) return String is
      R : String (1 .. P);
      LB : Natural := Lon_Bits (P);
      AB : Natural := Lat_Bits (P);
      Bit_No : Natural := 0;
      V : Natural := 0;
   begin
      for C in 1 .. P loop
         V := 0;
         for J in 1 .. 5 loop
            V := 2 * V;
            if Bit_No mod 2 = 0 then
               LB := LB - 1;
               if (ILon / 2 ** LB) mod 2 = 1 then V := V + 1; end if;
            else
               AB := AB - 1;
               if (ILat / 2 ** AB) mod 2 = 1 then V := V + 1; end if;
            end if;
            Bit_No := Bit_No + 1;
         end loop;
         R (C) := Alphabet (V + 1);
      end loop;
      return R;
   end Pack;

   procedure Unpack (H : String; ILon, ILat : out Index) is
      Bit_No : Natural := 0;
   begin
      ILon := 0; ILat := 0;
      for Ch of H loop
         declare
            V : Natural := 0;
         begin
            for K in Alphabet'Range loop
               if Alphabet (K) = Ch then V := K - 1; end if;
            end loop;
            for J in reverse 0 .. 4 loop
               if Bit_No mod 2 = 0 then
                  ILon := 2 * ILon + Index ((V / 2 ** J) mod 2);
               else
                  ILat := 2 * ILat + Index ((V / 2 ** J) mod 2);
               end if;
               Bit_No := Bit_No + 1;
            end loop;
         end;
      end loop;
   end Unpack;

   procedure Fail (What : String; Lat, Lon : Real; Got, Want : String) is
   begin
      Ada.Text_IO.Put_Line ("FAIL own check: " & What & " at" & Lat'Image & Lon'Image
                            & " gave " & Got & ", reference " & Want);
      raise Program_Error;
   end Fail;

   procedure Check_Point (Lat, Lon : Real; P : Precision_Type) is
      ILon : constant Index := Cell (Lon, -180.0, 360.0, Lon_Bits (P));
      ILat : constant Index := Cell (Lat, -90.0, 180.0, Lat_Bits (P));
      Want : constant String := Pack (ILon, ILat, P);
      Got  : constant String := Encode (Lat, Lon, P);
      NLon : constant Real := 2.0 ** Lon_Bits (P);
      NLat : constant Real := 2.0 ** Lat_Bits (P);
      B    : Bounding_Box;
      D    : Decode_Result;
   begin
      if Got /= Want then
         Fail ("Encode (precision" & P'Image & ")", Lat, Lon, Got, Want);
      end if;
      B := Decode_BBox (Want);
      D := Decode (Want);
      if not (Near (B.Min_Lon, -180.0 + 360.0 * Real (ILon) / NLon) and then Near (B.Max_Lon, -180.0 + 360.0 * Real (ILon + 1) / NLon)
              and then Near (B.Min_Lat, -90.0 + 180.0 * Real (ILat) / NLat) and then Near (B.Max_Lat, -90.0 + 180.0 * Real (ILat + 1) / NLat))
        or else D.Box /= B
        or else not Near (D.Center_Lat, (B.Min_Lat + B.Max_Lat) / 2.0)
        or else not Near (D.Center_Lon, (B.Min_Lon + B.Max_Lon) / 2.0)
      then
         Fail ("Decode_BBox / Decode", Lat, Lon, Want, "cell from integer indices");
      end if;
      if not Contains (B, Lat, Lon)
        or else (ILat + 1 < Index (NLat) and then Contains (B, B.Max_Lat + 180.0 / NLat / 2.0, Lon))
        or else (ILat > 0 and then Contains (B, B.Min_Lat - 180.0 / NLat / 2.0, Lon))
      then
         Fail ("Contains", Lat, Lon, Want, "inside its own cell, outside the cells above and below");
      end if;
      --  the eight neighbours: latitude clamped, longitude wrapped
      declare
         Nb : constant Neighbor_Set := Neighbors (Want);
         function Expect (DLat, DLon : Integer) return String is
           (Pack ((ILon + Index (DLon)) mod Index (NLon),
                  Index'Max (0, Index'Min (Index (NLat) - 1, ILat + Index (DLat))), P));
      begin
         if Nb.Len /= P
           or else Nb.N (1 .. P) /= Expect (1, 0) or else Nb.NE (1 .. P) /= Expect (1, 1)
           or else Nb.E (1 .. P) /= Expect (0, 1) or else Nb.SE (1 .. P) /= Expect (-1, 1)
           or else Nb.S (1 .. P) /= Expect (-1, 0) or else Nb.SW (1 .. P) /= Expect (-1, -1)
           or else Nb.W (1 .. P) /= Expect (0, -1) or else Nb.NW (1 .. P) /= Expect (1, -1)
         then
            Fail ("Neighbors", Lat, Lon, Want, "index +- 1, latitude clamped, longitude wrapped");
         end if;
         for DLat in -1 .. 1 loop
            for DLon in -1 .. 1 loop
               if (DLat /= 0 or else DLon /= 0) and then Neighbor (Want, DLat, DLon) /= Expect (DLat, DLon) then
                  Fail ("Neighbor" & DLat'Image & DLon'Image, Lat, Lon, Neighbor (Want, DLat, DLon), Expect (DLat, DLon));
               end if;
            end loop;
         end loop;
      end;
      declare
         UL, UA : Index;
      begin
         Unpack (Want, UL, UA);
         pragma Assert (UL = ILon and then UA = ILat);   --  the reference packs and unpacks consistently
      end;
      Checked := Checked + 1;
   end Check_Point;

   function Rejects_Hash (H : String) return Boolean is
   begin
      return Decode (H).Center_Lat > 1000.0;   --  never: must raise
   exception
      when Invalid_Hash => return True;
   end Rejects_Hash;
begin
   for P in Precision_Type loop
      for R in 1 .. 400 loop
         declare
            Lat : constant Real := Real (Rand mod 18_000_001 - 9_000_000) / 100_000.0;
            Lon : constant Real := Real (Rand mod 36_000_001 - 18_000_000) / 100_000.0;
         begin
            Check_Point (Lat, Lon, P);
         end;
      end loop;
      --  exact cell corners (dyadic, so the reference is exact), poles, date line
      for K in 0 .. 16 loop
         Check_Point (-90.0 + 180.0 * Real (K) / 16.0, -180.0 + 360.0 * Real (K) / 16.0, P);
         Check_Point (-90.0 + 180.0 * Real (K) / 16.0, 180.0 - 360.0 * Real (K) / 16.0, P);
      end loop;
   end loop;
   --  helpers
   for I in -400 .. 400 loop
      declare
         V : constant Real := Real (I) * 1.25;
         N : constant Real := Normalize_Longitude (V);
         C : constant Real := Clamp_Latitude (V);
      begin
         if C /= Real'Max (-90.0, Real'Min (90.0, V)) then
            Fail ("Clamp_Latitude", V, 0.0, C'Image, "");
         end if;
         if abs (V - 180.0 * Real'Rounding (V / 180.0)) > 1.0E-9   --  not on an odd multiple of 180: unique answer
           and then (N < -180.0 or else N > 180.0
                     or else abs ((N - V) / 360.0 - Real'Rounding ((N - V) / 360.0)) > 1.0E-12)
         then
            Fail ("Normalize_Longitude", 0.0, V, N'Image, "V + 360 * k in [-180, 180]");
         end if;
      end;
   end loop;
   if not Near (12.5, 12.5, 0.0) or else Near (12.5, 12.5 + 1.0E-6) or else not Near (12.5, 12.5 + 1.0E-10) then
      Fail ("Near (equal values with zero tolerance; 1e-9 default)", 0.0, 0.0, "", "");
   end if;
   if Common_Prefix_Length ("u4pruy", "u4pzzz") /= 3 or else Common_Prefix_Length ("", "abc") /= 0
     or else Common_Prefix_Length ("abc", "abc") /= 3 or else Common_Prefix_Length ("abcd", "abc") /= 3
     or else Common_Prefix_Length ("x", "y") /= 0
   then
      Fail ("Common_Prefix_Length", 0.0, 0.0, "", "");
   end if;
   for Ch in Character'Val (32) .. Character'Val (126) loop
      declare
         Legal : Boolean := False;
      begin
         for A of Alphabet loop Legal := Legal or else A = Ch; end loop;
         if Is_Valid_Hash ([Ch]) /= Legal or else Is_Valid_Hash ("u4" & Ch) /= Legal
           or else (not Legal and then not Rejects_Hash ("u4" & Ch))
         then
            Fail ("Is_Valid_Hash / Decode rejects " & Ch'Image, 0.0, 0.0, "", "");
         end if;
      end;
   end loop;
   if Is_Valid_Hash ("") or else Is_Valid_Hash ("0123456789bcd") or else not Is_Valid_Hash ("0123456789bc")
     or else not Rejects_Hash ("")
   then
      Fail ("Is_Valid_Hash lengths", 0.0, 0.0, "", "1 .. 12");
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Checked'Image
                         & " points x precision (integer cell indices, hand packing)");
end Own_Checks;
