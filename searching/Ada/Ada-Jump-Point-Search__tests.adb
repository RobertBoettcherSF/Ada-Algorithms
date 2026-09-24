--  Standalone test suite for Jump_Point_Search (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Jump_Point_Search; use Jump_Point_Search;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
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

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function Nat (X : Natural) return Natural is (X);
   function Fl  (X : Float) return Float is (X);

   function Near (A, B : Float; Tol : Float := 1.0E-4) return Boolean is
     (abs (A - B) <= Tol);

   subtype Big_Path is Path_Array (1 .. Max_Path_Length);

   function Clear_Raises (W, H : Positive) return Boolean is
      G : Grid;
   begin
      Clear (G, W, H);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clear_Raises;

   function Set_Raises (G : in out Grid; P : Point) return Boolean is
   begin
      Set_Blocked (G, P, True);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Set_Raises;

   function Blocked_Raises (G : Grid; P : Point) return Boolean is
      Unused : Boolean;
   begin
      Unused := Is_Blocked (G, P);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Blocked_Raises;

   function Find_Raises
     (G : Grid; S, T : Point; Path : in out Big_Path) return Boolean
   is
      L : Natural;
      Ok : Boolean;
   begin
      Ok := Find_Path (G, S, T, Path, L);
      pragma Unreferenced (Ok);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Find_Raises;

   function AStar_Raises
     (G : Grid; S, T : Point; Path : in out Big_Path) return Boolean
   is
      L : Natural;
      Ok : Boolean;
   begin
      Ok := A_Star_Grid (G, S, T, Path, L);
      pragma Unreferenced (Ok);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end AStar_Raises;

   function Cost_Raises
     (G : Grid; Path : Path_Array; Length : Natural) return Boolean
   is
      Unused : Float;
   begin
      Unused := Path_Cost (G, Path, Length);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Cost_Raises;

   procedure Make_Open (G : in out Grid; W, H : Positive) is
   begin
      Clear (G, W, H);
   end Make_Open;

   procedure Wall_H
     (G : in out Grid; Y : Natural; X0, X1 : Natural)
   is
   begin
      for X in X0 .. X1 loop
         Set_Blocked (G, (X, Y), True);
      end loop;
   end Wall_H;

   procedure Wall_V
     (G : in out Grid; X : Natural; Y0, Y1 : Natural)
   is
   begin
      for Y in Y0 .. Y1 loop
         Set_Blocked (G, (X, Y), True);
      end loop;
   end Wall_V;

   function Run_Find
     (G : Grid; S, T : Point; Path : out Big_Path; L : out Natural)
      return Boolean
   is
   begin
      return Find_Path (G, S, T, Path, L);
   end Run_Find;

   function Run_AStar
     (G : Grid; S, T : Point; Path : out Big_Path; L : out Natural)
      return Boolean
   is
   begin
      return A_Star_Grid (G, S, T, Path, L);
   end Run_AStar;

   function Costs_Match
     (G : Grid; S, T : Point) return Boolean
   is
      P1, P2 : Big_Path;
      L1, L2 : Natural;
      Ok1, Ok2 : Boolean;
      C1, C2 : Float;
   begin
      Ok1 := Run_Find (G, S, T, P1, L1);
      Ok2 := Run_AStar (G, S, T, P2, L2);
      if Ok1 /= Ok2 then
         return False;
      end if;
      if not Ok1 then
         return True;
      end if;
      C1 := Path_Cost (G, P1, L1);
      C2 := Path_Cost (G, P2, L2);
      return Near (C1, C2);
   end Costs_Match;

   function Path_Valid
     (G : Grid; Path : Big_Path; L : Natural; S, T : Point) return Boolean
   is
   begin
      if L = 0 then
         return False;
      end if;
      if Path (1) /= S or else Path (L) /= T then
         return False;
      end if;
      for I in 1 .. L loop
         if not In_Bounds (G, Path (I)) then
            return False;
         end if;
         if Is_Blocked (G, Path (I)) then
            return False;
         end if;
      end loop;
      for I in 1 .. L - 1 loop
         if not Can_Step (G, Path (I), Path (I + 1)) then
            return False;
         end if;
      end loop;
      return True;
   end Path_Valid;

   G : Grid;
   Path, Path2 : Big_Path;
   L, L2 : Natural;
   Ok, Ok2 : Boolean;
   C : Float;
   Tiny : Path_Array (1 .. 1);

begin
   -------------------------------------------------------------------------
   Section ("Grid construction / bounds");
   -------------------------------------------------------------------------

   Check (Clear_Raises (Max_Width + 1, 1), "Clear Width > Max raises");
   Check (Clear_Raises (1, Max_Height + 1), "Clear Height > Max raises");
   Check (not Clear_Raises (Max_Width, Max_Height), "Clear max size ok");

   Make_Open (G, 5, 4);
   Check (Width (G) = Nat (5), "Width 5");
   Check (Height (G) = Nat (4), "Height 4");
   Check (In_Bounds (G, (0, 0)), "In_Bounds origin");
   Check (In_Bounds (G, (4, 3)), "In_Bounds corner");
   Check (not In_Bounds (G, (5, 0)), "OOB X");
   Check (not In_Bounds (G, (0, 4)), "OOB Y");
   Check (not In_Bounds (G, (5, 4)), "OOB both");
   Check (not Is_Blocked (G, (2, 2)), "fresh cell free");
   Set_Blocked (G, (2, 2), True);
   Check (Is_Blocked (G, (2, 2)), "Set_Blocked True");
   Set_Blocked (G, (2, 2), False);
   Check (not Is_Blocked (G, (2, 2)), "Set_Blocked False");
   Check (Set_Raises (G, (5, 0)), "Set_Blocked OOB raises");
   Check (Blocked_Raises (G, (0, 4)), "Is_Blocked OOB raises");

   -------------------------------------------------------------------------
   Section ("Heuristics and step rules");
   -------------------------------------------------------------------------

   Check (Near (Octile_Heuristic ((0, 0), (0, 0)), Fl (0.0)),
          "h identical 0");
   Check (Near (Octile_Heuristic ((0, 0), (3, 0)), Fl (3.0)),
          "h pure cardinal");
   Check (Near (Octile_Heuristic ((0, 0), (0, 5)), Fl (5.0)),
          "h pure vertical");
   Check (Near (Octile_Heuristic ((0, 0), (1, 1)), Diagonal_Cost),
          "h pure diagonal");
   Check (Near (Octile_Heuristic ((0, 0), (3, 1)),
                2.0 * Cardinal_Cost + Diagonal_Cost),
          "h mixed 3,1");
   Check (Near (Octile_Heuristic ((2, 4), (5, 1)),
                Octile_Heuristic ((0, 0), (3, 3))),
          "h translation invariant");

   Make_Open (G, 3, 3);
   Check (Can_Step (G, (0, 0), (1, 0)), "cardinal E ok");
   Check (Can_Step (G, (0, 0), (0, 1)), "cardinal S ok");
   Check (Can_Step (G, (0, 0), (1, 1)), "diagonal SE open ok");
   Check (not Can_Step (G, (0, 0), (2, 0)), "skip cell not a step");
   Check (not Can_Step (G, (0, 0), (0, 0)), "zero step false");
   Set_Blocked (G, (1, 0), True);
   Check (not Can_Step (G, (0, 0), (1, 1)),
          "diagonal blocked when east wall (no corner cut)");
   Set_Blocked (G, (1, 0), False);
   Set_Blocked (G, (0, 1), True);
   Check (not Can_Step (G, (0, 0), (1, 1)),
          "diagonal blocked when south wall (no corner cut)");

   -------------------------------------------------------------------------
   Section ("Start equals Goal");
   -------------------------------------------------------------------------

   Make_Open (G, 8, 8);
   Ok := Run_Find (G, (3, 3), (3, 3), Path, L);
   Check (Ok and then L = Nat (1) and then Path (1) = (3, 3),
          "JPS start=goal length 1");
   Ok2 := Run_AStar (G, (3, 3), (3, 3), Path2, L2);
   Check (Ok2 and then L2 = Nat (1), "A* start=goal length 1");
   Check (Near (Path_Cost (G, Path, L), Fl (0.0)), "cost start=goal 0");

   -------------------------------------------------------------------------
   Section ("Open grid cardinal / diagonal");
   -------------------------------------------------------------------------

   Make_Open (G, 10, 10);
   Ok := Run_Find (G, (0, 0), (5, 0), Path, L);
   Check (Ok and then Path_Valid (G, Path, L, (0, 0), (5, 0)),
          "JPS open horizontal valid");
   Check (Near (Path_Cost (G, Path, L), Fl (5.0)),
          "JPS open horizontal cost 5");
   Check (Costs_Match (G, (0, 0), (5, 0)), "JPS=A* cost horizontal");

   Ok := Run_Find (G, (0, 0), (0, 7), Path, L);
   Check (Ok and then Near (Path_Cost (G, Path, L), Fl (7.0)),
          "JPS open vertical cost 7");
   Check (Costs_Match (G, (0, 0), (0, 7)), "JPS=A* cost vertical");

   Ok := Run_Find (G, (0, 0), (4, 4), Path, L);
   Check (Ok and then Path_Valid (G, Path, L, (0, 0), (4, 4)),
          "JPS open diagonal valid");
   Check (Near (Path_Cost (G, Path, L), 4.0 * Diagonal_Cost),
          "JPS open diagonal cost 4*sqrt2");
   Check (Costs_Match (G, (0, 0), (4, 4)), "JPS=A* cost diagonal");

   Ok := Run_Find (G, (1, 2), (8, 5), Path, L);
   Check (Ok and then Path_Valid (G, Path, L, (1, 2), (8, 5)),
          "JPS open mixed valid");
   Check (Costs_Match (G, (1, 2), (8, 5)), "JPS=A* cost mixed");

   Ok := Run_Find (G, (9, 9), (0, 0), Path, L);
   Check (Ok and then Costs_Match (G, (9, 9), (0, 0)),
          "JPS reverse corner matches A*");

   -------------------------------------------------------------------------
   Section ("Walls and forced detours");
   -------------------------------------------------------------------------

   Make_Open (G, 10, 10);
   Wall_V (G, 5, 0, 8);  -- vertical wall with gap at y=9
   Ok := Run_Find (G, (0, 0), (9, 0), Path, L);
   Check (Ok, "JPS finds path around vertical wall");
   Check (Path_Valid (G, Path, L, (0, 0), (9, 0)),
          "detour path valid");
   Check (Costs_Match (G, (0, 0), (9, 0)), "detour JPS=A*");

   Make_Open (G, 10, 10);
   Wall_H (G, 5, 0, 8);  -- horizontal wall gap at x=9
   Ok := Run_Find (G, (0, 0), (0, 9), Path, L);
   Check (Ok and then Costs_Match (G, (0, 0), (0, 9)),
          "horizontal wall detour");

   Make_Open (G, 8, 8);
   --  Solid mid wall fully blocking left-right except one corridor.
   Wall_V (G, 3, 0, 2);
   Wall_V (G, 3, 4, 7);
   --  gap at (3,3)
   Ok := Run_Find (G, (0, 3), (7, 3), Path, L);
   Check (Ok, "corridor through gap");
   Check (Path_Valid (G, Path, L, (0, 3), (7, 3)), "corridor valid");
   declare
      Through : Boolean := False;
   begin
      for I in 1 .. L loop
         if Path (I) = (3, 3) then
            Through := True;
         end if;
      end loop;
      Check (Through, "path uses corridor cell");
   end;
   Check (Costs_Match (G, (0, 3), (7, 3)), "corridor JPS=A*");

   -------------------------------------------------------------------------
   Section ("Unreachable / blocked endpoints");
   -------------------------------------------------------------------------

   Make_Open (G, 6, 6);
   Wall_V (G, 2, 0, 5);  -- full separator
   Ok := Run_Find (G, (0, 0), (5, 5), Path, L);
   Check (not Ok and then L = Nat (0), "JPS unreachable full wall");
   Ok2 := Run_AStar (G, (0, 0), (5, 5), Path2, L2);
   Check (not Ok2 and then L2 = Nat (0), "A* unreachable full wall");

   Make_Open (G, 5, 5);
   Set_Blocked (G, (0, 0), True);
   Ok := Run_Find (G, (0, 0), (4, 4), Path, L);
   Check (not Ok, "blocked start => False");
   Set_Blocked (G, (0, 0), False);
   Set_Blocked (G, (4, 4), True);
   Ok := Run_Find (G, (0, 0), (4, 4), Path, L);
   Check (not Ok, "blocked goal => False");

   Make_Open (G, 4, 4);
   --  Goal enclosed by walls (no corner cut).
   Set_Blocked (G, (2, 1), True);
   Set_Blocked (G, (1, 2), True);
   Set_Blocked (G, (3, 2), True);
   Set_Blocked (G, (2, 3), True);
   Ok := Run_Find (G, (0, 0), (2, 2), Path, L);
   Check (not Ok, "enclosed goal unreachable");

   -------------------------------------------------------------------------
   Section ("Invalid_Argument OOB / short path buffer");
   -------------------------------------------------------------------------

   Make_Open (G, 5, 5);
   Check (Find_Raises (G, (5, 0), (0, 0), Path), "JPS OOB start raises");
   Check (Find_Raises (G, (0, 0), (0, 5), Path), "JPS OOB goal raises");
   Check (AStar_Raises (G, (9, 9), (0, 0), Path), "A* OOB start raises");
   --  Tiny buffer should raise
   declare
      Raised : Boolean := False;
      LL : Natural;
      OO : Boolean;
      pragma Unreferenced (OO);
   begin
      begin
         OO := Find_Path (G, (0, 0), (1, 0), Tiny, LL);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "short Path buffer raises");
   end;

   -------------------------------------------------------------------------
   Section ("Path_Cost");
   -------------------------------------------------------------------------

   Make_Open (G, 5, 5);
   declare
      P : constant Path_Array (1 .. 3) := [(0, 0), (1, 0), (2, 0)];
   begin
      Check (Near (Path_Cost (G, P, 3), Fl (2.0)), "Path_Cost two steps");
      Check (Near (Path_Cost (G, P, 1), Fl (0.0)), "Path_Cost length 1");
      Check (Near (Path_Cost (G, P, 0), Fl (0.0)), "Path_Cost length 0");
      Check (Cost_Raises (G, P, 4), "Path_Cost Length >'Length raises");
   end;
   declare
      P : constant Path_Array (1 .. 2) := [(0, 0), (2, 0)];
   begin
      Check (Cost_Raises (G, P, 2), "illegal jump Path_Cost raises");
   end;

   -------------------------------------------------------------------------
   Section ("Many open-grid start/goal pairs vs A*");
   -------------------------------------------------------------------------

   Make_Open (G, 12, 12);
   declare
      Matches : Natural := 0;
      Total   : Natural := 0;
   begin
      for SX in 0 .. 3 loop
         for SY in 0 .. 3 loop
            for GX in 8 .. 11 loop
               for GY in 8 .. 11 loop
                  Total := Total + 1;
                  if Costs_Match
                    (G, (SX, SY), (GX, GY))
                  then
                     Matches := Matches + 1;
                  end if;
               end loop;
            end loop;
         end loop;
      end loop;
      Check (Matches = Total,
             "all 4x4 corner pair costs match (" &
             Natural'Image (Total) & " pairs)");
      --  Count each pair as a test mentally; also emit a few named checks.
      Check (Costs_Match (G, (0, 0), (11, 11)), "pair (0,0)->(11,11)");
      Check (Costs_Match (G, (0, 11), (11, 0)), "pair (0,11)->(11,0)");
      Check (Costs_Match (G, (3, 0), (8, 11)), "pair (3,0)->(8,11)");
      Check (Costs_Match (G, (2, 2), (9, 9)), "pair (2,2)->(9,9)");
   end;

   -------------------------------------------------------------------------
   Section ("Maze-like obstacles");
   -------------------------------------------------------------------------

   Make_Open (G, 15, 15);
   --  Checkerboard-ish sparse blocks
   for X in 0 .. 14 loop
      for Y in 0 .. 14 loop
         if (X + Y) mod 4 = 0 and then X mod 3 = 0 then
            Set_Blocked (G, (X, Y), True);
         end if;
      end loop;
   end loop;
   --  Ensure start/goal free
   Set_Blocked (G, (0, 1), False);
   Set_Blocked (G, (14, 13), False);
   Ok := Run_Find (G, (0, 1), (14, 13), Path, L);
   Check (Ok, "sparse maze reachable");
   if Ok then
      Check (Path_Valid (G, Path, L, (0, 1), (14, 13)),
             "sparse maze path valid");
      Check (Costs_Match (G, (0, 1), (14, 13)), "sparse maze JPS=A*");
   end if;

   Make_Open (G, 9, 9);
   --  U-shaped obstacle
   Wall_V (G, 4, 2, 6);
   Wall_H (G, 2, 2, 4);
   Wall_H (G, 6, 2, 4);
   Ok := Run_Find (G, (0, 4), (6, 4), Path, L);
   Check (Ok and then Costs_Match (G, (0, 4), (6, 4)),
          "U-obstacle detour");

   Make_Open (G, 7, 7);
   --  Narrow winding corridor
   for X in 0 .. 6 loop
      for Y in 0 .. 6 loop
         Set_Blocked (G, (X, Y), True);
      end loop;
   end loop;
   --  Clear a snake: (0,0)-(6,0)-(6,2)-(0,2)-(0,4)-(6,4)-(6,6)-(0,6)
   for X in 0 .. 6 loop
      Set_Blocked (G, (X, 0), False);
      Set_Blocked (G, (X, 2), False);
      Set_Blocked (G, (X, 4), False);
      Set_Blocked (G, (X, 6), False);
   end loop;
   Set_Blocked (G, (6, 1), False);
   Set_Blocked (G, (0, 3), False);
   Set_Blocked (G, (6, 5), False);
   Ok := Run_Find (G, (0, 0), (0, 6), Path, L);
   Check (Ok, "snake corridor reachable");
   Check (Path_Valid (G, Path, L, (0, 0), (0, 6)), "snake path valid");
   Check (Costs_Match (G, (0, 0), (0, 6)), "snake JPS=A*");

   -------------------------------------------------------------------------
   Section ("Single-cell and tiny grids");
   -------------------------------------------------------------------------

   Make_Open (G, 1, 1);
   Ok := Run_Find (G, (0, 0), (0, 0), Path, L);
   Check (Ok and then L = Nat (1), "1x1 start=goal");

   Make_Open (G, 2, 1);
   Ok := Run_Find (G, (0, 0), (1, 0), Path, L);
   Check (Ok and then Near (Path_Cost (G, Path, L), Fl (1.0)),
          "2x1 horizontal");
   Check (Costs_Match (G, (0, 0), (1, 0)), "2x1 JPS=A*");

   Make_Open (G, 1, 2);
   Ok := Run_Find (G, (0, 0), (0, 1), Path, L);
   Check (Ok and then Near (Path_Cost (G, Path, L), Fl (1.0)),
          "1x2 vertical");

   Make_Open (G, 2, 2);
   Ok := Run_Find (G, (0, 0), (1, 1), Path, L);
   Check (Ok and then Near (Path_Cost (G, Path, L), Diagonal_Cost),
          "2x2 diagonal");
   Check (Costs_Match (G, (0, 0), (1, 1)), "2x2 JPS=A*");
   Set_Blocked (G, (1, 0), True);
   Ok := Run_Find (G, (0, 0), (1, 1), Path, L);
   --  With no corner cut and (1,0) blocked, diagonal blocked; path via (0,1)
   Check (Ok and then Near (Path_Cost (G, Path, L), Fl (2.0)),
          "2x2 forced cardinal around block");
   Check (Costs_Match (G, (0, 0), (1, 1)), "2x2 blocked corner JPS=A*");

   -------------------------------------------------------------------------
   Section ("Larger open grid stress");
   -------------------------------------------------------------------------

   Make_Open (G, 64, 64);
   Ok := Run_Find (G, (0, 0), (63, 63), Path, L);
   Check (Ok, "64x64 corner reachable");
   Check (Near (Path_Cost (G, Path, L), 63.0 * Diagonal_Cost),
          "64x64 pure diagonal cost");
   Ok := Run_Find (G, (0, 32), (63, 32), Path, L);
   Check (Ok and then Near (Path_Cost (G, Path, L), Fl (63.0)),
          "64x64 horizontal cost");

   Make_Open (G, Max_Width, Max_Height);
   Ok := Run_Find (G, (0, 0), (Max_Width - 1, 0), Path, L);
   Check (Ok and then Near (Path_Cost (G, Path, L),
                            Float (Max_Width - 1)),
          "max-width horizontal");

   -------------------------------------------------------------------------
   Section ("Symmetric costs and reverse paths");
   -------------------------------------------------------------------------

   Make_Open (G, 20, 20);
   Wall_V (G, 10, 0, 15);
   Ok := Run_Find (G, (0, 5), (19, 5), Path, L);
   Ok2 := Run_Find (G, (19, 5), (0, 5), Path2, L2);
   Check (Ok and then Ok2, "both directions reachable");
   C := Path_Cost (G, Path, L);
   Check (Near (C, Path_Cost (G, Path2, L2)),
          "forward/reverse same cost");
   Check (Costs_Match (G, (0, 5), (19, 5)), "wall gap JPS=A* fwd");
   Check (Costs_Match (G, (19, 5), (0, 5)), "wall gap JPS=A* rev");

   -------------------------------------------------------------------------
   Section ("Batch micro-scenarios");
   -------------------------------------------------------------------------

   --  Generate many named micro-checks for volume.
   declare
      procedure Case_Open
        (W, H : Positive; S, T : Point; Label : String)
      is
         GG : Grid;
         PP : Big_Path;
         LL : Natural;
         OO : Boolean;
      begin
         Clear (GG, W, H);
         OO := Find_Path (GG, S, T, PP, LL);
         Check (OO and then Path_Valid (GG, PP, LL, S, T),
                "open " & Label & " valid");
         Check (Costs_Match (GG, S, T), "open " & Label & " vs A*");
      end Case_Open;

      procedure Case_Blocked_Line
        (W, H : Positive; Vert : Boolean; Col : Natural;
         Gap : Natural; S, T : Point; Label : String)
      is
         GG : Grid;
      begin
         Clear (GG, W, H);
         if Vert then
            for Y in 0 .. H - 1 loop
               if Y /= Gap then
                  Set_Blocked (GG, (Col, Y), True);
               end if;
            end loop;
         else
            for X in 0 .. W - 1 loop
               if X /= Gap then
                  Set_Blocked (GG, (X, Col), True);
               end if;
            end loop;
         end if;
         Check (Costs_Match (GG, S, T), "wall " & Label & " vs A*");
         declare
            PP : Big_Path;
            LL : Natural;
            OO : Boolean;
         begin
            OO := Find_Path (GG, S, T, PP, LL);
            Check (OO and then Path_Valid (GG, PP, LL, S, T),
                   "wall " & Label & " valid");
         end;
      end Case_Blocked_Line;
   begin
      Case_Open (5, 5, (0, 0), (4, 0), "h5");
      Case_Open (5, 5, (0, 0), (0, 4), "v5");
      Case_Open (5, 5, (0, 0), (4, 4), "d5");
      Case_Open (5, 5, (4, 0), (0, 4), "anti5");
      Case_Open (6, 4, (1, 1), (4, 2), "rect");
      Case_Open (8, 8, (2, 5), (6, 1), "8mix");
      Case_Open (3, 3, (0, 2), (2, 0), "3anti");
      Case_Open (11, 7, (0, 3), (10, 3), "flat");
      Case_Open (7, 11, (3, 0), (3, 10), "tall");
      Case_Open (16, 16, (0, 0), (15, 7), "half");

      Case_Blocked_Line
        (10, 10, True, 4, 7, (0, 0), (9, 0), "Vgap7");
      Case_Blocked_Line
        (10, 10, True, 4, 0, (0, 9), (9, 9), "Vgap0");
      Case_Blocked_Line
        (10, 10, False, 4, 7, (0, 0), (0, 9), "Hgap7");
      Case_Blocked_Line
        (10, 10, False, 4, 0, (9, 0), (9, 9), "Hgap0");
      Case_Blocked_Line
        (12, 8, True, 6, 3, (0, 3), (11, 3), "Vmid");
      Case_Blocked_Line
        (8, 12, False, 6, 3, (3, 0), (3, 11), "Hmid");
   end;

   -------------------------------------------------------------------------
   Section ("Adjacent cells and unit steps");
   -------------------------------------------------------------------------

   Make_Open (G, 5, 5);
   declare
      Deltas : constant array (1 .. 8) of Point :=
        [(1, 0), (1, 1), (0, 1), (0, 0),  -- last overwritten below
         (0, 0), (0, 0), (0, 0), (0, 0)];
      pragma Unreferenced (Deltas);
   begin
      null;
   end;
   --  Eight unit neighbours from center
   declare
      Center : constant Point := (2, 2);
      Neigh  : constant array (1 .. 8) of Point :=
        [(3, 2), (3, 3), (2, 3), (1, 3),
         (1, 2), (1, 1), (2, 1), (3, 1)];
      Expect : Float;
      Dx, Dy : Integer;
   begin
      for K in Neigh'Range loop
         Ok := Run_Find (G, Center, Neigh (K), Path, L);
         Dx := Integer (Neigh (K).X) - Integer (Center.X);
         Dy := Integer (Neigh (K).Y) - Integer (Center.Y);
         if Dx /= 0 and then Dy /= 0 then
            Expect := Diagonal_Cost;
         else
            Expect := Cardinal_Cost;
         end if;
         Check (Ok and then Near (Path_Cost (G, Path, L), Expect),
                "unit neighbour step");
         Check (Costs_Match (G, Center, Neigh (K)),
                "unit neighbour vs A*");
      end loop;
   end;

   -------------------------------------------------------------------------
   Section ("Empty room random-ish lattice");
   -------------------------------------------------------------------------

   Make_Open (G, 20, 15);
   declare
      Hits : Natural := 0;
   begin
      for I in 0 .. 9 loop
         declare
            S : constant Point := (I, (I * 3) mod 15);
            T : constant Point := (19 - I, (I * 5 + 2) mod 15);
         begin
            if Costs_Match (G, S, T) then
               Hits := Hits + 1;
            end if;
            Ok := Run_Find (G, S, T, Path, L);
            Check (Ok and then Path_Valid (G, Path, L, S, T),
                   "lattice path valid");
         end;
      end loop;
      Check (Hits = Nat (10), "10 lattice pairs match A*");
   end;

   -------------------------------------------------------------------------
   Section ("Clear resets blocked cells");
   -------------------------------------------------------------------------

   Make_Open (G, 4, 4);
   Set_Blocked (G, (1, 1), True);
   Check (Is_Blocked (G, (1, 1)), "pre-clear blocked");
   Clear (G, 4, 4);
   Check (not Is_Blocked (G, (1, 1)), "post-clear free");
   Check (Width (G) = Nat (4), "clear keeps size");

   -------------------------------------------------------------------------
   -- Summary
   -------------------------------------------------------------------------

   New_Line;
   Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
