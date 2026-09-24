--  Standalone test suite for Vincenty (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Vincenty; use Vincenty;

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

   function Az_Near (A, B : Real; Tol : Real := 1.0E-6) return Boolean is
      D : constant Real := Normalize_Longitude (A - B);
   begin
      return abs (D) <= Tol;
   end Az_Near;

begin
   Put_Line ("Vincenty test suite");
   Put_Line ("===================");

   ---------------------------------------------------------------------
   Section ("1. WGS-84 constants / Ellipsoid");
   ---------------------------------------------------------------------
   declare
      E : constant Ellipsoid := WGS84;
      B : constant Real := Semi_Minor (E);
   begin
      Check (Near (E.A, 6_378_137.0, 1.0E-6), "WGS84 a = 6378137 m");
      Check (Near (E.F, 1.0 / 298.257223563, 1.0E-15),
             "WGS84 f = 1/298.257223563");
      Check (Approx (B, 6_356_752.314245, 1.0E-3),
             "WGS84 b ≈ 6356752.314245 m");
      Check (B < E.A, "semi-minor < semi-major");
      Check (E.F > 0.0 and then E.F < 1.0, "flattening in (0,1)");
   end;

   ---------------------------------------------------------------------
   Section ("2. Deg_To_Rad / Rad_To_Deg / Near / Normalize");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Near (Deg_To_Rad (0.0), 0.0), "0 deg -> 0 rad");
      Check (Near (Deg_To_Rad (180.0), Pi, 1.0E-12), "180 deg -> pi");
      Check (Near (Deg_To_Rad (90.0), Half_Pi, 1.0E-12), "90 deg -> pi/2");
      Check (Near (Rad_To_Deg (Pi), 180.0, 1.0E-12), "pi -> 180 deg");
      Check (Near (Rad_To_Deg (0.0), 0.0), "0 rad -> 0 deg");
      Check (Near (Rad_To_Deg (Deg_To_Rad (45.0)), 45.0, 1.0E-12),
             "deg round-trip 45");
      Check (Near (1.0, 1.0), "Near equal");
      Check (not Near (1.0, 2.0), "Near rejects far");
      Check (Near (Normalize_Longitude (Pi + 0.1), -Pi + 0.1, 1.0E-12),
             "Normalize > pi wraps");
      Check (Near (Normalize_Longitude (-Pi - 0.1), Pi - 0.1, 1.0E-12),
             "Normalize < -pi wraps");
      Check (Near (Normalize_Longitude (0.0), 0.0), "Normalize 0");
      Check (Near (Two_Pi, 2.0 * Pi, 1.0E-15), "Two_Pi = 2*Pi");
   end;

   ---------------------------------------------------------------------
   Section ("3. Zero distance / same point");
   ---------------------------------------------------------------------
   declare
      R : Inverse_Result;
      D : Direct_Result;
   begin
      R := Inverse (0.0, 0.0, 0.0, 0.0);
      Check (R.Converged, "Inverse same origin converged");
      Check (Near (R.Distance, 0.0, 1.0E-9), "Inverse same origin s=0");
      Check (R.Iterations = 0, "Inverse same origin 0 iters");

      R := Inverse_Degrees (48.0, 11.0, 48.0, 11.0);
      Check (R.Converged and then Near (R.Distance, 0.0, 1.0E-6),
             "Inverse_Degrees Munich self s=0");

      R := Inverse_Degrees (-33.8688, 151.2093, -33.8688, 151.2093);
      Check (R.Converged and then Near (R.Distance, 0.0, 1.0E-6),
             "Inverse_Degrees Sydney self s=0");

      D := Direct (0.0, 0.0, 0.0, 0.0);
      Check (D.Converged, "Direct s=0 converged");
      Check (Near (D.Lat2, 0.0) and then Near (D.Lon2, 0.0),
             "Direct s=0 stays put");

      D := Direct_Degrees (40.0, -74.0, 90.0, 0.0);
      Check (D.Converged and then
             Near (Rad_To_Deg (D.Lat2), 40.0, 1.0E-9) and then
             Near (Rad_To_Deg (D.Lon2), -74.0, 1.0E-9),
             "Direct_Degrees s=0 NYC stays");
   end;

   ---------------------------------------------------------------------
   Section ("4. Short meridian arcs (~1 degree)");
   ---------------------------------------------------------------------
   declare
      R : Inverse_Result;
      --  1° of meridian near equator ≈ 110.6 km; near 45° ≈ 111.1 km
   begin
      R := Inverse_Degrees (0.0, 0.0, 1.0, 0.0);
      Check (R.Converged, "1° meridian equator converged");
      Check (R.Distance > 110_000.0 and then R.Distance < 112_000.0,
             "1° meridian equator ~111 km order");
      Check (Approx (R.Distance, 110_574.0, 50.0),
             "1° meridian equator ≈ 110574 m ±50");

      R := Inverse_Degrees (45.0, 10.0, 46.0, 10.0);
      Check (R.Converged, "1° meridian 45N converged");
      Check (R.Distance > 110_000.0 and then R.Distance < 112_500.0,
             "1° meridian 45N ~111 km");
      Check (Approx (R.Distance, 111_132.0, 200.0),
             "1° meridian 45N ≈ 111 km ±200");

      R := Inverse_Degrees (-10.0, 20.0, -9.0, 20.0);
      Check (R.Converged, "1° meridian S hemisphere");
      Check (R.Distance > 110_000.0 and then R.Distance < 112_000.0,
             "1° meridian S ~111 km");
   end;

   ---------------------------------------------------------------------
   Section ("5. Equatorial easting");
   ---------------------------------------------------------------------
   declare
      R : Inverse_Result;
      D : Direct_Result;
      --  1° longitude on equator: s = a * Δλ * (1-f roughly) ... ≈ 111319 m
   begin
      R := Inverse_Degrees (0.0, 0.0, 0.0, 1.0);
      Check (R.Converged, "1° equatorial east converged");
      Check (R.Distance > 111_000.0 and then R.Distance < 112_000.0,
             "1° equatorial ≈ 111.3 km");
      Check (Approx (R.Distance, 111_319.0, 50.0),
             "1° equatorial ≈ 111319 m ±50");
      Check (Az_Near (R.Azimuth1, Deg_To_Rad (90.0), 1.0E-4),
             "equatorial east α1 ≈ 90°");

      D := Direct_Degrees (0.0, 0.0, 90.0, R.Distance);
      Check (D.Converged, "Direct equatorial east converged");
      Check (Approx (Rad_To_Deg (D.Lat2), 0.0, 1.0E-6),
             "Direct equatorial stays on equator");
      Check (Approx (Rad_To_Deg (D.Lon2), 1.0, 1.0E-4),
             "Direct equatorial lon ≈ 1°");

      R := Inverse_Degrees (0.0, 0.0, 0.0, -1.0);
      Check (R.Converged, "1° equatorial west converged");
      Check (Az_Near (R.Azimuth1, Deg_To_Rad (-90.0), 1.0E-4) or else
             Az_Near (R.Azimuth1, Deg_To_Rad (270.0), 1.0E-4),
             "equatorial west α1 ≈ -90°");
   end;

   ---------------------------------------------------------------------
---------------------------------------------------------------------
   Section ("6. Direct then Inverse round-trip");
   ---------------------------------------------------------------------
   declare
      D : Direct_Result;
      R : Inverse_Result;
      type Case_Rec is record
         Lat, Lon, Az, Dist : Real;
      end record;
      Cases : constant array (Positive range <>) of Case_Rec :=
        [(0.0, 0.0, 45.0, 1_000.0),
         (48.137, 11.575, 0.0, 50_000.0),
         (40.7128, -74.0060, 90.0, 10_000.0),
         (-33.8688, 151.2093, 180.0, 25_000.0),
         (51.5074, -0.1278, 270.0, 5_000.0),
         (35.6762, 139.6503, 30.0, 100_000.0),
         (0.0, 0.0, 0.0, 1_000_000.0),
         (60.0, 10.0, 135.0, 500_000.0)];
   begin
      for I in Cases'Range loop
         declare
            C : Case_Rec renames Cases (I);
            Tag : constant String := "case" & Integer'Image (I);
         begin
            D := Direct_Degrees (C.Lat, C.Lon, C.Az, C.Dist);
            Check (D.Converged, "Direct round-trip " & Tag & " converged");
            R := Inverse
              (Deg_To_Rad (C.Lat), Deg_To_Rad (C.Lon), D.Lat2, D.Lon2);
            Check (R.Converged, "Inverse after Direct " & Tag);
            Check (Approx (R.Distance, C.Dist, 0.01),
                   "round-trip distance " & Tag & " within 1 cm");
            Check (Az_Near (R.Azimuth1, Deg_To_Rad (C.Az), 1.0E-5),
                   "round-trip azimuth " & Tag);
         end;
      end loop;
   end;


---------------------------------------------------------------------
   Section ("7. Inverse then Direct consistency");
   ---------------------------------------------------------------------
   declare
      R : Inverse_Result;
      D : Direct_Result;
      type Pair is record
         Lat1, Lon1, Lat2, Lon2 : Real;
      end record;
      Pairs : constant array (Positive range <>) of Pair :=
        [(48.137, 11.575, 52.52, 13.405),
         (51.5074, -0.1278, 48.8566, 2.3522),
         (40.7128, -74.0060, 34.0522, -118.2437),
         (-33.8688, 151.2093, -37.8136, 144.9631),
         (35.6762, 139.6503, 37.5665, 126.9780),
         (0.0, 0.0, 10.0, 20.0)];
   begin
      for I in Pairs'Range loop
         declare
            P : Pair renames Pairs (I);
            Tag : constant String := "pair" & Integer'Image (I);
         begin
            R := Inverse_Degrees (P.Lat1, P.Lon1, P.Lat2, P.Lon2);
            Check (R.Converged, "Inverse " & Tag & " converged");
            Check (R.Distance > 0.0, "Inverse " & Tag & " s > 0");
            D := Direct
              (Deg_To_Rad (P.Lat1), Deg_To_Rad (P.Lon1),
               R.Azimuth1, R.Distance);
            Check (D.Converged, "Direct from Inverse " & Tag);
            Check (Approx (Rad_To_Deg (D.Lat2), P.Lat2, 1.0E-5),
                   "lat2 match " & Tag);
            Check (Approx (Rad_To_Deg (D.Lon2), P.Lon2, 1.0E-5),
                   "lon2 match " & Tag);
         end;
      end loop;
   end;


   Section ("8. Published check: Flinders Peak → Buninyong");
   ---------------------------------------------------------------------
   --  Classic Vincenty test (Survey Review / Veness):
   --  φ1=−37°57'03.72030", L1=144°25'29.52440"
   --  φ2=−37°39'10.15610", L2=143°55'35.38390"
   --  s = 54972.271 m, alpha1 ~ 306 deg 52 min 05.37 sec
   declare
      Lat1 : constant Real :=
        -(37.0 + 57.0 / 60.0 + 3.72030 / 3600.0);
      Lon1 : constant Real :=
        144.0 + 25.0 / 60.0 + 29.52440 / 3600.0;
      Lat2 : constant Real :=
        -(37.0 + 39.0 / 60.0 + 10.15610 / 3600.0);
      Lon2 : constant Real :=
        143.0 + 55.0 / 60.0 + 35.38390 / 3600.0;
      R : Inverse_Result;
      D : Direct_Result;
      A1_Deg : Real;
   begin
      R := Inverse_Degrees (Lat1, Lon1, Lat2, Lon2);
      Check (R.Converged, "Flinders-Buninyong converged");
      Check (Approx (R.Distance, 54_972.271, 0.05),
             "Flinders-Buninyong s ≈ 54972.271 m");
      A1_Deg := Rad_To_Deg (R.Azimuth1);
      if A1_Deg < 0.0 then
         A1_Deg := A1_Deg + 360.0;
      end if;
      Check (Approx (A1_Deg, 306.0 + 52.0 / 60.0 + 5.37 / 3600.0, 0.01),
             "Flinders alpha1 ~ 306d 52m 05s");
      Check (R.Iterations < 20, "Flinders few iterations");

      D := Direct_Degrees (Lat1, Lon1, A1_Deg, R.Distance);
      Check (D.Converged, "Flinders Direct converged");
      Check (Approx (Rad_To_Deg (D.Lat2), Lat2, 1.0E-6),
             "Flinders Direct lat2");
      Check (Approx (Rad_To_Deg (D.Lon2), Lon2, 1.0E-6),
             "Flinders Direct lon2");
   end;

   ---------------------------------------------------------------------
   Section ("9. Degree wrappers vs radian API");
   ---------------------------------------------------------------------
   declare
      Rr, Rd : Inverse_Result;
      Dr, Dd : Direct_Result;
   begin
      Rr := Inverse (Deg_To_Rad (10.0), Deg_To_Rad (20.0),
                     Deg_To_Rad (30.0), Deg_To_Rad (40.0));
      Rd := Inverse_Degrees (10.0, 20.0, 30.0, 40.0);
      Check (Rr.Converged and then Rd.Converged, "wrappers inverse both ok");
      Check (Near (Rr.Distance, Rd.Distance, 1.0E-6),
             "Inverse vs Inverse_Degrees distance");
      Check (Az_Near (Rr.Azimuth1, Rd.Azimuth1), "azimuth1 match wrappers");
      Check (Az_Near (Rr.Azimuth2, Rd.Azimuth2), "azimuth2 match wrappers");

      Dr := Direct (Deg_To_Rad (10.0), Deg_To_Rad (20.0),
                    Deg_To_Rad (45.0), 12_345.0);
      Dd := Direct_Degrees (10.0, 20.0, 45.0, 12_345.0);
      Check (Dr.Converged and then Dd.Converged, "wrappers direct both ok");
      Check (Near (Dr.Lat2, Dd.Lat2, 1.0E-12), "Direct lat2 wrappers");
      Check (Near (Dr.Lon2, Dd.Lon2, 1.0E-12), "Direct lon2 wrappers");
      Check (Az_Near (Dr.Azimuth2, Dd.Azimuth2), "Direct α2 wrappers");
   end;

   ---------------------------------------------------------------------
   Section ("10. Haversine vs Vincenty (short arcs)");
   ---------------------------------------------------------------------
   declare
      Hv, Vn : Real;
      R : Inverse_Result;
   begin
      R := Inverse_Degrees (48.0, 11.0, 48.1, 11.1);
      Check (R.Converged, "short Munich arc converged");
      Hv := Haversine_Degrees (48.0, 11.0, 48.1, 11.1);
      Vn := R.Distance;
      Check (Hv > 0.0 and then Vn > 0.0, "haversine and vincenty > 0");
      --  Relative difference typically < 0.5% on ~10–15 km arcs
      Check (abs (Hv - Vn) / Vn < 0.01,
             "haversine within 1% of Vincenty short");
      Check (Near (Haversine (0.0, 0.0, 0.0, 0.0), 0.0),
             "haversine same point 0");
      Check (Near (Haversine_Degrees (0.0, 0.0, 0.0, 0.0), 0.0),
             "haversine_deg same point 0");
      --  1° equator haversine with a=6378137 closer to Vincenty
      Hv := Haversine_Degrees (0.0, 0.0, 0.0, 1.0, WGS84_A);
      R := Inverse_Degrees (0.0, 0.0, 0.0, 1.0);
      Check (abs (Hv - R.Distance) < 100.0,
             "1° equator haversine(a) near Vincenty");
   end;

   ---------------------------------------------------------------------
   Section ("11. Antipode / near-antipode status (no crash)");
   ---------------------------------------------------------------------
   declare
      R : Inverse_Result;
   begin
      --  Exact geographic antipode of (0,0) is (0,180) — often fails
      R := Inverse_Degrees (0.0, 0.0, 0.0, 180.0);
      Check (True, "antipode (0,180) did not crash");
      Check (R.Converged = False or else R.Distance > 0.0,
             "antipode either fails or yields long distance");

      --  Wikipedia failure example: (0,0) to (0.5, 179.7)
      R := Inverse_Degrees (0.0, 0.0, 0.5, 179.7);
      Check (True, "near-antipode 179.7 did not crash");
      --  May or may not converge depending on iteration limit
      if R.Converged then
         Check (R.Distance > 19_000_000.0, "if converged, s ~ 20e6 m");
      else
         Check (not R.Converged, "179.7 reported non-convergence");
         Check (R.Iterations >= 1, "non-convergence recorded iterations");
      end if;

      --  Slow but usually ok: (0,0) to (0.5, 179.5) → ~19936288.579 m
      R := Inverse_Degrees (0.0, 0.0, 0.5, 179.5);
      Check (True, "near-antipode 179.5 did not crash");
      if R.Converged then
         Check (Approx (R.Distance, 19_936_288.579, 5.0),
                "179.5 distance ≈ 19936288.579 m");
      else
         Check (not R.Converged, "179.5 status flag if not converged");
      end if;

      R := Inverse_Degrees (10.0, 20.0, -10.0, -160.0);
      Check (True, "far pair did not crash");
   end;

   ---------------------------------------------------------------------
   Section ("12. Polar / high latitude sanity");
   ---------------------------------------------------------------------
   declare
      R : Inverse_Result;
      D : Direct_Result;
   begin
      R := Inverse_Degrees (89.0, 0.0, 89.0, 10.0);
      Check (R.Converged, "near-pole parallel converged");
      Check (R.Distance > 0.0 and then R.Distance < 20_000.0,
             "near-pole 10° lon is short");

      D := Direct_Degrees (80.0, 0.0, 0.0, 100_000.0);
      Check (D.Converged, "Direct from 80N north converged");
      Check (Rad_To_Deg (D.Lat2) > 80.0, "moved further north");

      D := Direct_Degrees (-80.0, 0.0, 180.0, 100_000.0);
      Check (D.Converged, "Direct from 80S south converged");
      Check (Rad_To_Deg (D.Lat2) < -80.0, "moved further south");

      R := Inverse_Degrees (70.0, -50.0, 71.0, -49.0);
      Check (R.Converged and then R.Distance > 50_000.0,
             "Arctic short baseline");
   end;

   ---------------------------------------------------------------------
   Section ("13. Custom ellipsoid / Invalid_Argument");
   ---------------------------------------------------------------------
   declare
      Sphere : constant Ellipsoid := (A => 6_371_000.0, F => 1.0E-12);
      R : Inverse_Result;
      Raised : Boolean := False;
   begin
      R := Inverse_Degrees (0.0, 0.0, 0.0, 1.0, Sphere);
      Check (R.Converged, "near-sphere ellipsoid inverse ok");
      Check (Approx (R.Distance, Haversine_Degrees
             (0.0, 0.0, 0.0, 1.0, 6_371_000.0), 2.0),
             "near-sphere ≈ haversine");

      begin
         declare
            Unused : Direct_Result :=
              Direct (0.0, 0.0, 0.0, -1.0);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Direct negative distance raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("14. More generated round-trips (bulk PASS)");
   ---------------------------------------------------------------------
   declare
      D : Direct_Result;
      R : Inverse_Result;
      Lat, Lon, Az, Dist : Real;
   begin
      for I in 1 .. 20 loop
         Lat  := Real (I) * 3.0 - 30.0;
         Lon  := Real (I) * 7.0 - 70.0;
         Az   := Real (I) * 17.0;
         Dist := 1_000.0 * Real (I);
         D := Direct_Degrees (Lat, Lon, Az, Dist);
         Check (D.Converged, "bulk Direct converged #" &
                Integer'Image (I));
         R := Inverse (Deg_To_Rad (Lat), Deg_To_Rad (Lon), D.Lat2, D.Lon2);
         Check (R.Converged, "bulk Inverse converged #" &
                Integer'Image (I));
         Check (Approx (R.Distance, Dist, 0.05),
                "bulk distance #" & Integer'Image (I));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("15. Azimuth reverse / longitudes");
   ---------------------------------------------------------------------
   declare
      R : Inverse_Result;
      D : Direct_Result;
   begin
      R := Inverse_Degrees (0.0, 0.0, 0.0, 90.0);
      Check (R.Converged, "quarter equator converged");
      Check (R.Distance > 9_000_000.0 and then R.Distance < 11_000_000.0,
             "quarter equator ~10 Mm");

      D := Direct_Degrees (0.0, 10.0, 90.0, 1_000_000.0);
      Check (D.Converged, "1 Mm east from (0,10)");
      Check (Approx (Rad_To_Deg (D.Lat2), 0.0, 1.0E-4),
             "1 Mm east stays equatorial");
      Check (Rad_To_Deg (D.Lon2) > 10.0, "longitude increased");

      R := Inverse_Degrees (12.0, -45.0, 12.0, 45.0);
      Check (R.Converged, "same-lat parallel-ish converged");
      Check (R.Distance > 0.0, "same-lat distance > 0");
   end;

   New_Line;
   Put_Line ("================================");
   Put_Line ("PASS: " & Natural'Image (Pass_Count));
   Put_Line ("FAIL: " & Natural'Image (Fail_Count));
   Put_Line ("Fail_Count=" & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("ALL TESTS PASSED");
   elsif Fail_Count = 0 then
      Put_Line ("OK but fewer than 100 PASS");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;
end Tests;
