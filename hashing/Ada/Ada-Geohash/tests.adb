--  Standalone test suite for Geohash (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Geohash; use Geohash;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Real; Tol : Real) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

begin
   Put_Line ("Geohash test suite");
   Put_Line ("==================");

   ---------------------------------------------------------------------
   Section ("1. Alphabet / Is_Valid_Hash / Near");
   ---------------------------------------------------------------------
   declare
   begin
      declare
         Valid_Solo : Natural := 0;
      begin
         for C of Base32_Alphabet loop
            if Is_Valid_Hash (String'(1 => C)) then
               Valid_Solo := Valid_Solo + 1;
            end if;
         end loop;
         Check (Valid_Solo = 32, "all 32 alphabet chars valid solo");
         Check (Base32_Alphabet'Length = Valid_Solo,
                "alphabet length equals valid solo count");
      end;
      Check (Is_Valid_Hash ("u4pruydqqvj"), "valid classic hash");
      Check (Is_Valid_Hash ("ezs42"), "valid ezs42");
      Check (Is_Valid_Hash ("0"), "valid single 0");
      Check (Is_Valid_Hash ("z"), "valid single z");
      Check (not Is_Valid_Hash (""), "empty rejected");
      Check (not Is_Valid_Hash ("a"), "letter a rejected");
      Check (not Is_Valid_Hash ("i"), "letter i rejected");
      Check (not Is_Valid_Hash ("l"), "letter l rejected");
      Check (not Is_Valid_Hash ("o"), "letter o rejected");
      Check (not Is_Valid_Hash ("A"), "uppercase A rejected");
      Check (not Is_Valid_Hash ("ezs4!"), "punctuation rejected");
      Check (not Is_Valid_Hash ("abcdefghijkl"),
             "12-char with a,i,l rejected");
      Check (Near (1.0, 1.0), "Near equal");
      Check (not Near (1.0, 2.0), "Near rejects far");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near with custom tol");
   end;

   ---------------------------------------------------------------------
   Section ("2. Classic Wikipedia examples");
   ---------------------------------------------------------------------
   declare
      H  : constant String := Encode (57.64911, 10.40744, 11);
      D  : Decode_Result;
      H5 : constant String := Encode (42.6, -5.6, 5);
   begin
      Check (H = "u4pruydqqvj", "Jutland p11 -> u4pruydqqvj");
      Check (Encode (57.64911, 10.40744, 1) = "u", "Jutland p1 -> u");
      Check (Encode (57.64911, 10.40744, 2) = "u4", "Jutland p2 -> u4");
      Check (Encode (57.64911, 10.40744, 3) = "u4p", "Jutland p3 -> u4p");
      Check (Encode (57.64911, 10.40744, 4) = "u4pr", "Jutland p4 -> u4pr");
      Check (Encode (57.64911, 10.40744, 5) = "u4pru", "Jutland p5 -> u4pru");
      Check (Encode (57.64911, 10.40744, 6) = "u4pruy", "Jutland p6");
      Check (Encode (57.64911, 10.40744, 7) = "u4pruyd", "Jutland p7");
      Check (Encode (57.64911, 10.40744, 8) = "u4pruydq", "Jutland p8");
      Check (Encode (57.64911, 10.40744, 9) = "u4pruydqq", "Jutland p9");
      Check (Encode (57.64911, 10.40744, 10) = "u4pruydqqv", "Jutland p10");
      Check (Encode (57.64911, 10.40744, 12) = "u4pruydqqvj8",
             "Jutland p12");

      D := Decode ("u4pruydqqvj");
      Check (Approx (D.Center_Lat, 57.64911, 1.0E-5),
             "decode u4pruydqqvj lat ~57.64911");
      Check (Approx (D.Center_Lon, 10.40744, 1.0E-5),
             "decode u4pruydqqvj lon ~10.40744");
      Check (Contains (D.Box, 57.64911, 10.40744),
             "bbox contains Jutland point");

      Check (H5 = "ezs42", "Spain-ish 42.6,-5.6 p5 -> ezs42");
      D := Decode ("ezs42");
      Check (Approx (D.Center_Lat, 42.605, 0.02), "ezs42 center lat");
      Check (Approx (D.Center_Lon, -5.603, 0.02), "ezs42 center lon");
      Check (Contains (D.Box, 42.6, -5.6), "ezs42 contains 42.6,-5.6");
   end;

   ---------------------------------------------------------------------
   Section ("3. Known city encode pairs");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Encode (37.7749, -122.4194, 8) = "9q8yyk8y",
             "San Francisco p8");
      Check (Encode (37.7749, -122.4194, 7) = "9q8yyk8",
             "San Francisco p7");
      Check (Encode (51.5074, -0.1278, 7) = "gcpvj0d", "London p7");
      Check (Encode (-33.8688, 151.2093, 8) = "r3gx2f77", "Sydney p8");
      Check (Encode (35.6895, 139.6917, 8) = "xn774c06", "Tokyo p8");
      Check (Encode (40.7128, -74.0060, 9) = "dr5regw3p", "NYC p9");
      Check (Encode (-22.9068, -43.1729, 8) = "75cm9tfq", "Rio p8");
      Check (Encode (0.0, 0.0, 1) = "s", "origin p1 -> s");
      Check (Encode (0.0, 0.0, 5) = "s0000", "origin p5 -> s0000");
   end;

   ---------------------------------------------------------------------
   Section ("4. Round-trip: center inside cell / re-encode");
   ---------------------------------------------------------------------
   declare
      Points : constant array (1 .. 8, 1 .. 2) of Real :=
        [[57.64911, 10.40744],
         [42.6, -5.6],
         [37.7749, -122.4194],
         [51.5074, -0.1278],
         [-33.8688, 151.2093],
         [35.6895, 139.6917],
         [40.7128, -74.0060],
         [-22.9068, -43.1729]];
   begin
      for I in 1 .. 8 loop
         declare
            H : constant String :=
              Encode (Points (I, 1), Points (I, 2), 8);
            D : constant Decode_Result := Decode (H);
         begin
            Check (Contains (D.Box, Points (I, 1), Points (I, 2)),
                   "round-trip contains point #" & Integer'Image (I));
            Check (Encode (D.Center_Lat, D.Center_Lon, 8) = H,
                   "center re-encodes same #" & Integer'Image (I));
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("5. Precision refinement (prefix property)");
   ---------------------------------------------------------------------
   declare
      Lat : constant Real := 57.64911;
      Lon : constant Real := 10.40744;
      Full : constant String := Encode (Lat, Lon, 12);
   begin
      Check (Full'Length = 12, "p12 length");
      for P in Precision_Type range 1 .. 11 loop
         declare
            Cur : constant String := Encode (Lat, Lon, P);
         begin
            Check (Cur'Length = P,
                   "length matches p" & Precision_Type'Image (P));
            Check (Full (1 .. P) = Cur,
                   "full hash starts with p" & Precision_Type'Image (P));
            if P > 1 then
               declare
                  Prev : constant String := Encode (Lat, Lon, P - 1);
               begin
                  Check (Common_Prefix_Length (Prev, Cur) = Prev'Length,
                         "extends prior p" & Precision_Type'Image (P));
               end;
            end if;
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("6. Common_Prefix_Length / nearby points");
   ---------------------------------------------------------------------
   declare
      A   : constant String := Encode (57.64911, 10.40744, 8);
      B   : constant String := Encode (57.64912, 10.40745, 8);
      C   : constant String := Encode (-33.0, 151.0, 8);
      Far : constant String := Encode (0.0, 0.0, 8);
   begin
      Check (Common_Prefix_Length (A, A) = 8, "identical prefix 8");
      Check (Common_Prefix_Length (A, B) >= 6, "nearby Jutland share >=6");
      Check (Common_Prefix_Length ("u4pr", "u4pruydq") = 4, "prefix 4");
      Check (Common_Prefix_Length ("abc", "axx") = 1, "prefix 1");
      Check (Common_Prefix_Length ("abc", "xyz") = 0, "prefix 0");
      Check (Common_Prefix_Length ("", "xyz") = 0, "empty prefix 0");
      Check (Common_Prefix_Length (A, C) < 3,
             "distant continents short prefix");
      Check (Common_Prefix_Length (A, Far) < 3, "Jutland vs origin short");
   end;

   ---------------------------------------------------------------------
   Section ("7. BBox shrinks with precision");
   ---------------------------------------------------------------------
   declare
      Lat    : constant Real := 48.8566;
      Lon    : constant Real := 2.3522;
      Prev_H : Real := 180.0;
      Prev_W : Real := 360.0;
   begin
      for P in Precision_Type loop
         declare
            H   : constant String := Encode (Lat, Lon, P);
            Box : constant Bounding_Box := Decode_BBox (H);
            Ht  : constant Real :=
              Real (Box.Max_Lat) - Real (Box.Min_Lat);
            Wd  : constant Real :=
              Real (Box.Max_Lon) - Real (Box.Min_Lon);
         begin
            Check (Contains (Box, Lat, Lon),
                   "Paris in bbox p" & Precision_Type'Image (P));
            Check (Ht <= Prev_H + 1.0E-12,
                   "lat span non-inc p" & Precision_Type'Image (P));
            Check (Wd <= Prev_W + 1.0E-12,
                   "lon span non-inc p" & Precision_Type'Image (P));
            Prev_H := Ht;
            Prev_W := Wd;
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("8. Neighbors");
   ---------------------------------------------------------------------
   declare
      H : constant String := Encode (57.64911, 10.40744, 6);
      N : Neighbor_Set;
      Distinct_From_Self : Natural := 0;
   begin
      N := Neighbors (H);
      Check (N.Len = 6, "neighbors Len = 6");
      Check (Neighbor (H, 1, 0)'Length = 6, "Neighbor N length");
      Check (Neighbor (H, 0, 1)'Length = 6, "Neighbor E length");
      Check (Neighbor (H, -1, 0)'Length = 6, "Neighbor S length");
      Check (Neighbor (H, 0, -1)'Length = 6, "Neighbor W length");

      Check (N.N (1 .. 6) = Neighbor (H, 1, 0), "N matches Neighbor");
      Check (N.E (1 .. 6) = Neighbor (H, 0, 1), "E matches Neighbor");
      Check (N.S (1 .. 6) = Neighbor (H, -1, 0), "S matches Neighbor");
      Check (N.W (1 .. 6) = Neighbor (H, 0, -1), "W matches Neighbor");
      Check (N.NE (1 .. 6) = Neighbor (H, 1, 1), "NE matches");
      Check (N.SE (1 .. 6) = Neighbor (H, -1, 1), "SE matches");
      Check (N.SW (1 .. 6) = Neighbor (H, -1, -1), "SW matches");
      Check (N.NW (1 .. 6) = Neighbor (H, 1, -1), "NW matches");

      if N.N (1 .. 6) /= H then
         Distinct_From_Self := Distinct_From_Self + 1;
      end if;
      if N.E (1 .. 6) /= H then
         Distinct_From_Self := Distinct_From_Self + 1;
      end if;
      if N.S (1 .. 6) /= H then
         Distinct_From_Self := Distinct_From_Self + 1;
      end if;
      if N.W (1 .. 6) /= H then
         Distinct_From_Self := Distinct_From_Self + 1;
      end if;
      Check (Distinct_From_Self = 4,
             "cardinal neighbors differ from self");

      Check (Neighbor (Neighbor (H, 0, 1), 0, -1) = H,
             "E then W recovers hash");
      Check (Neighbor (Neighbor (H, 1, 0), -1, 0) = H,
             "N then S recovers hash");

      Check (Is_Valid_Hash (N.N (1 .. 6)), "north neighbor valid");
      Check (Is_Valid_Hash (N.SW (1 .. 6)), "SW neighbor valid");
   end;

   ---------------------------------------------------------------------
   Section ("9. Poles / dateline / clamp / normalize");
   ---------------------------------------------------------------------
   declare
      Hp : String (1 .. 5);
      D  : Decode_Result;
   begin
      Check (Clamp_Latitude (100.0) = 90.0, "clamp lat >90");
      Check (Clamp_Latitude (-100.0) = -90.0, "clamp lat <-90");
      Check (Clamp_Latitude (45.0) = 45.0, "clamp lat identity");
      Check (Near (Normalize_Longitude (190.0), -170.0),
             "norm 190 -> -170");
      Check (Near (Normalize_Longitude (-190.0), 170.0),
             "norm -190 -> 170");
      Check (Near (Normalize_Longitude (0.0), 0.0), "norm 0");
      Check (Near (Normalize_Longitude (180.0), 180.0)
             or else Near (Normalize_Longitude (180.0), -180.0),
             "norm ±180 meridian");

      Hp := Encode (90.0, 0.0, 5);
      Check (Hp'Length = 5, "north pole hash length");
      Check (Is_Valid_Hash (Hp), "north pole hash valid");
      D := Decode (Hp);
      Check (D.Box.Max_Lat = 90.0 or else D.Center_Lat > 80.0,
             "north pole cell near +90");

      Hp := Encode (-90.0, 0.0, 5);
      Check (Is_Valid_Hash (Hp), "south pole hash valid");
      D := Decode (Hp);
      Check (D.Box.Min_Lat = -90.0 or else D.Center_Lat < -80.0,
             "south pole cell near -90");

      Check (Encode (0.0, 180.0, 5) = "xbpbp", "lon +180 p5");
      Check (Encode (0.0, -180.0, 5) = "80000", "lon -180 p5");
      Check (Encode (100.0, 0.0, 5) = Encode (90.0, 0.0, 5),
             "lat clamp encode same as 90");
      Check (Encode (0.0, 190.0, 5) = Encode (0.0, -170.0, 5),
             "lon wrap encode 190 ≡ -170");

      declare
         Edge : constant String := Encode (0.0, 179.9, 5);
         E_N  : constant String := Neighbor (Edge, 0, 1);
      begin
         Check (Is_Valid_Hash (E_N), "dateline east neighbor valid");
         Check (E_N'Length = 5, "dateline neighbor length");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Invalid decode / neighbor args");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            D : Decode_Result := Decode ("abc");
            pragma Unreferenced (D);
         begin
            null;
         end;
      exception
         when Invalid_Hash => Raised := True;
      end;
      Check (Raised, "Decode rejects 'abc'");

      Raised := False;
      begin
         declare
            B : Bounding_Box := Decode_BBox ("");
            pragma Unreferenced (B);
         begin
            null;
         end;
      exception
         when Invalid_Hash => Raised := True;
      end;
      Check (Raised, "Decode_BBox rejects empty");

      Raised := False;
      begin
         declare
            S : constant String := Neighbor ("u4pruy", 0, 0);
            pragma Unreferenced (S);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Neighbor (0,0) raises Invalid_Argument");

      Raised := False;
      begin
         declare
            S : constant String := Neighbor ("u4pruy", 2, 0);
            pragma Unreferenced (S);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Neighbor delta 2 raises Invalid_Argument");

      Raised := False;
      begin
         declare
            N : Neighbor_Set := Neighbors ("bad!");
            pragma Unreferenced (N);
         begin
            null;
         end;
      exception
         when Invalid_Hash => Raised := True;
      end;
      Check (Raised, "Neighbors rejects invalid hash");
   end;

   ---------------------------------------------------------------------
   Section ("11. Extra encode/decode spots");
   ---------------------------------------------------------------------
   declare
      Samples : constant array (1 .. 10, 1 .. 2) of Real :=
        [[1.0, 1.0],
         [-1.0, -1.0],
         [45.0, 45.0],
         [-45.0, 45.0],
         [45.0, -45.0],
         [-45.0, -45.0],
         [10.0, 170.0],
         [10.0, -170.0],
         [80.0, 0.0],
         [-80.0, 0.0]];
   begin
      for I in 1 .. 10 loop
         declare
            H : constant String :=
              Encode (Samples (I, 1), Samples (I, 2), 7);
            D : constant Decode_Result := Decode (H);
         begin
            Check (H'Length = 7,
                   "extra sample length #" & Integer'Image (I));
            Check (Contains (D.Box, Samples (I, 1), Samples (I, 2)),
                   "extra sample in bbox #" & Integer'Image (I));
         end;
      end loop;
   end;

   New_Line;
   Put_Line ("======================================");
   Put_Line ("Pass_Count =" & Natural'Image (Pass_Count));
   Put_Line ("Fail_Count =" & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("ALL TESTS PASSED");
   else
      Put_Line ("TESTS FAILED");
   end if;
end Tests;
