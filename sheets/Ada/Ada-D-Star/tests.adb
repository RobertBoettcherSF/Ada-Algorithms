--  Standalone test suite for D_Star (D* Lite educational package).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with D_Star; use D_Star;

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

   function Nat (X : Natural) return Natural is (X);
   function Fl  (X : Float) return Float is (X);
   function Pos (X : Positive) return Positive is (X);

   function Near (A, B : Float; Tol : Float := 1.0E-3) return Boolean is
     (abs (A - B) <= Tol);

   function Same_XY (A, B : Point) return Boolean is
     (A.X = B.X and then A.Y = B.Y);

   function Is_Finite (C : Float) return Boolean is
     (C < Infinity * 0.5);

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

   function Set_Blocked_Raises (G : in out Grid; P : Point) return Boolean is
   begin
      Set_Blocked (G, P, True);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Set_Blocked_Raises;

   function Set_Cost_Raises
     (G : in out Grid; P : Point; Cost : Float) return Boolean
   is
   begin
      Set_Cell_Cost (G, P, Cost);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Set_Cost_Raises;

   function Is_Blocked_Raises (G : Grid; P : Point) return Boolean is
      B : Boolean;
   begin
      B := Is_Blocked (G, P);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Is_Blocked_Raises;

   function Init_Raises (G : Grid; S, T : Point) return Boolean is
      Pl : Planner;
   begin
      Initialize (Pl, G, S, T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Init_Raises;

   function Uninit_Path_Exists_Raises return Boolean is
      Pl : Planner;
      B  : Boolean;
   begin
      B := Path_Exists (Pl);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Uninit_Path_Exists_Raises;

   function Uninit_Replan_Raises return Boolean is
      Pl : Planner;
   begin
      Replan (Pl);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Uninit_Replan_Raises;

   function Get_Path_Short_Raises (Pl : Planner) return Boolean is
      Short : Path_Array (1 .. 1);
      Len   : Natural;
   begin
      Get_Path (Pl, Short, Len);
      pragma Unreferenced (Len);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Get_Path_Short_Raises;

   function A_Star_Short_Raises (G : Grid; S, T : Point) return Boolean is
      Short : Path_Array (1 .. 1);
      Len   : Natural;
      Ok    : Boolean;
   begin
      Ok := A_Star_Replan (G, S, T, Short, Len);
      pragma Unreferenced (Ok, Len);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end A_Star_Short_Raises;

   function A_Star_OOB_Raises (G : Grid) return Boolean is
      Path : Big_Path;
      Len  : Natural;
      Ok   : Boolean;
   begin
      Ok := A_Star_Replan (G, (Width (G), 0), (0, 0), Path, Len);
      pragma Unreferenced (Ok, Len);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end A_Star_OOB_Raises;

   procedure Expect_Match
     (G : Grid; S, T : Point; Label : String)
   is
      Pl   : Planner;
      Path : Big_Path;
      Len  : Natural;
      Ok   : Boolean;
      DC, AC : Float;
   begin
      Initialize (Pl, G, S, T);
      Ok := A_Star_Replan (G, S, T, Path, Len);
      if Path_Exists (Pl) then
         DC := Path_Cost (Pl);
         Check (Ok, Label & " — A* finds path");
         AC := Path_Cost (G, Path, Len);
         Check (Near (DC, AC), Label & " — D* Lite cost = A* cost");
      else
         Check (not Ok, Label & " — both report no path");
      end if;
   end Expect_Match;

   G      : Grid;
   Pl     : Planner;
   Path   : Big_Path;
   Len    : Natural;
   Ok     : Boolean;
   C      : Float;
   E1, E2 : Natural;

begin
   Section ("Grid construction");
   Clear (G, Pos (5), Pos (4));
   Check (Width (G) = Nat (5), "Width 5");
   Check (Height (G) = Nat (4), "Height 4");
   Check (In_Bounds (G, (0, 0)), "In bounds corner");
   Check (In_Bounds (G, (4, 3)), "In bounds far");
   Check (not In_Bounds (G, (5, 0)), "OOB x");
   Check (not In_Bounds (G, (0, 4)), "OOB y");
   Check (not Is_Blocked (G, (2, 2)), "default free");
   Check (Near (Get_Cell_Cost (G, (1, 1)), Fl (1.0)), "default cost 1");

   Check (Clear_Raises (Pos (Max_Width + 1), Pos (1)), "Clear oversize W");
   Check (Clear_Raises (Pos (1), Pos (Max_Height + 1)), "Clear oversize H");
   Check (Clear_Raises (Pos (Max_Width), Pos (Max_Height + 1)),
          "Clear oversize H with max W");

   Section ("Blocked and cell costs");
   Clear (G, Pos (6), Pos (6));
   Set_Blocked (G, (3, 3), True);
   Check (Is_Blocked (G, (3, 3)), "set blocked");
   Check (not Is_Finite (Get_Cell_Cost (G, (3, 3))), "blocked cost Inf");
   Set_Blocked (G, (3, 3), False);
   Check (not Is_Blocked (G, (3, 3)), "unblock");
   Check (Near (Get_Cell_Cost (G, (3, 3)), Fl (1.0)), "unblocked cost 1");
   Set_Cell_Cost (G, (2, 2), Fl (2.5));
   Check (Near (Get_Cell_Cost (G, (2, 2)), Fl (2.5)), "custom cost 2.5");
   Set_Blocked (G, (2, 2), True);
   Check (Is_Blocked (G, (2, 2)), "block after custom cost");
   Set_Blocked (G, (2, 2), False);
   Check (Near (Get_Cell_Cost (G, (2, 2)), Fl (2.5)), "cost restored");
   Check (Set_Blocked_Raises (G, (9, 0)), "Set_Blocked OOB");
   Check (Set_Cost_Raises (G, (0, 9), Fl (1.0)), "Set_Cell_Cost OOB");
   Check (Set_Cost_Raises (G, (0, 0), Fl (0.0)), "cost zero rejected");
   Check (Set_Cost_Raises (G, (0, 0), Fl (-1.0)), "cost negative rejected");
   Check (Set_Cost_Raises (G, (0, 0), Fl (Max_Cell_Cost + 1.0)),
          "cost too large rejected");
   Check (Is_Blocked_Raises (G, (10, 10)), "Is_Blocked OOB");

   Section ("Manhattan heuristic");
   Check (Near (Manhattan_Heuristic ((0, 0), (0, 0)), Fl (0.0)), "h=0");
   Check (Near (Manhattan_Heuristic ((0, 0), (3, 4)), Fl (7.0)), "h=7");
   Check (Near (Manhattan_Heuristic ((5, 2), (1, 2)), Fl (4.0)), "h=4 horiz");
   Check (Near (Manhattan_Heuristic ((1, 8), (1, 3)), Fl (5.0)), "h=5 vert");
   Check (Near (Manhattan_Heuristic ((2, 2), (5, 6)), Fl (7.0)), "h=7 diagish");

   Section ("Invalid planner use");
   Check (Uninit_Path_Exists_Raises, "Path_Exists before Initialize");
   Check (Uninit_Replan_Raises, "Replan before Initialize");
   Clear (G, Pos (3), Pos (3));
   Check (Init_Raises (G, (5, 0), (0, 0)), "Initialize Start OOB");
   Check (Init_Raises (G, (0, 0), (0, 5)), "Initialize Goal OOB");
   Initialize (Pl, G, (0, 0), (2, 2));
   Check (Get_Path_Short_Raises (Pl), "Get_Path short buffer");
   Check (A_Star_Short_Raises (G, (0, 0), (2, 2)), "A* short buffer");
   Check (A_Star_OOB_Raises (G), "A* OOB start");

   Section ("Open grid — trivial paths");
   Clear (G, Pos (1), Pos (1));
   Initialize (Pl, G, (0, 0), (0, 0));
   Check (Path_Exists (Pl), "1x1 Start=Goal exists");
   Get_Path (Pl, Path, Len);
   Check (Len = Nat (1), "1x1 length 1");
   Check (Near (Path_Cost (Pl), Fl (0.0)), "1x1 cost 0");
   Check (Same_XY (Path (1), (0, 0)), "1x1 cell");
   Ok := A_Star_Replan (G, (0, 0), (0, 0), Path, Len);
   Check (Ok and then Len = Nat (1), "A* 1x1");

   Clear (G, Pos (5), Pos (1));
   Initialize (Pl, G, (0, 0), (4, 0));
   Check (Path_Exists (Pl), "row path exists");
   Get_Path (Pl, Path, Len);
   Check (Len = Nat (5), "row length 5");
   Check (Near (Path_Cost (Pl), Fl (4.0)), "row cost 4");
   Check (Near (Path_Cost (Pl), Float (Len - 1)), "row cost = len-1");
   Expect_Match (G, (0, 0), (4, 0), "row");

   Clear (G, Pos (1), Pos (8));
   Initialize (Pl, G, (0, 0), (0, 7));
   Check (Path_Exists (Pl), "column path exists");
   Check (Near (Path_Cost (Pl), Fl (7.0)), "column cost 7");
   Expect_Match (G, (0, 0), (0, 7), "column");

   Clear (G, Pos (10), Pos (10));
   Initialize (Pl, G, (0, 0), (9, 9));
   Check (Path_Exists (Pl), "open 10x10 exists");
   Check (Near (Path_Cost (Pl), Fl (18.0)), "open 10x10 Manhattan 18");
   Get_Path (Pl, Path, Len);
   Check (Len = Nat (19), "open 10x10 length 19");
   Check (Path (1).X = Nat (0) and then Path (1).Y = Nat (0), "path start");
   Check (Path (Len).X = Nat (9) and then Path (Len).Y = Nat (9), "path goal");
   Expect_Match (G, (0, 0), (9, 9), "open 10x10");
   Check (Same_XY (Start_Point (Pl), (0, 0)), "Start_Point");
   Check (Same_XY (Goal_Point (Pl), (9, 9)), "Goal_Point");

   Section ("Walls and detours");
   Clear (G, Pos (7), Pos (5));
   --  Vertical wall with a gap
   for Y in 0 .. 4 loop
      if Y /= 2 then
         Set_Blocked (G, (3, Y), True);
      end if;
   end loop;
   Initialize (Pl, G, (0, 2), (6, 2));
   Check (Path_Exists (Pl), "wall with gap — path");
   Check (Near (Path_Cost (Pl), Fl (6.0)), "wall gap still cost 6");
   Expect_Match (G, (0, 2), (6, 2), "wall gap");

   Clear (G, Pos (7), Pos (5));
   for Y in 0 .. 4 loop
      Set_Blocked (G, (3, Y), True);
   end loop;
   Initialize (Pl, G, (0, 2), (6, 2));
   Check (not Path_Exists (Pl), "solid wall — unreachable");
   Get_Path (Pl, Path, Len);
   Check (Len = Nat (0), "solid wall — empty path");
   Check (not Is_Finite (Path_Cost (Pl)), "solid wall — Inf cost");
   Ok := A_Star_Replan (G, (0, 2), (6, 2), Path, Len);
   Check (not Ok, "solid wall — A* agrees");

   Clear (G, Pos (8), Pos (8));
   for X in 2 .. 5 loop
      Set_Blocked (G, (X, 3), True);
   end loop;
   Initialize (Pl, G, (0, 3), (7, 3));
   Check (Path_Exists (Pl), "horizontal barrier detour");
   Check (Path_Cost (Pl) > Fl (7.0), "detour longer than 7");
   Expect_Match (G, (0, 3), (7, 3), "horizontal barrier");

   Section ("Blocked endpoints");
   Clear (G, Pos (4), Pos (4));
   Set_Blocked (G, (0, 0), True);
   Initialize (Pl, G, (0, 0), (3, 3));
   Check (not Path_Exists (Pl), "blocked start");
   Clear (G, Pos (4), Pos (4));
   Set_Blocked (G, (3, 3), True);
   Initialize (Pl, G, (0, 0), (3, 3));
   Check (not Path_Exists (Pl), "blocked goal");
   Ok := A_Star_Replan (G, (0, 0), (3, 3), Path, Len);
   Check (not Ok, "A* blocked goal");

   Section ("Non-uniform cell costs");
   Clear (G, Pos (5), Pos (3));
   for X in 0 .. 4 loop
      Set_Cell_Cost (G, (X, 1), Fl (10.0));
   end loop;
   --  Prefer top or bottom row (cost 1) over middle (cost 10)
   Initialize (Pl, G, (0, 0), (4, 0));
   Check (Path_Exists (Pl), "prefer cheap row");
   Check (Near (Path_Cost (Pl), Fl (4.0)), "cheap row cost 4");
   Expect_Match (G, (0, 0), (4, 0), "cheap row");

   Clear (G, Pos (4), Pos (4));
   Set_Cell_Cost (G, (1, 0), Fl (5.0));
   Set_Cell_Cost (G, (2, 0), Fl (5.0));
   Initialize (Pl, G, (0, 0), (3, 0));
   Check (Path_Exists (Pl), "expensive corridor still ok");
   Expect_Match (G, (0, 0), (3, 0), "expensive corridor");

   Section ("Incremental replan — block cell on path");
   Clear (G, Pos (12), Pos (8));
   Initialize (Pl, G, (0, 4), (11, 4));
   Check (Path_Exists (Pl), "pre-block path");
   Check (Near (Path_Cost (Pl), Fl (11.0)), "pre-block cost 11");
   E1 := Expansion_Count (Pl);
   Check (E1 > Nat (0), "initial expansions > 0");
   Get_Path (Pl, Path, Len);
   --  Block a cell that must be on every shortest path (straight corridor
   --  middle): (5,4)
   Set_Blocked (Pl, (5, 4), True);
   Replan (Pl);
   Check (Path_Exists (Pl), "post-block path still exists");
   Check (Path_Cost (Pl) > Fl (11.0), "post-block cost increased");
   E2 := Expansion_Count (Pl);
   --  Fresh restart for comparison
   declare
      Pl2 : Planner;
      G2  : Grid := G;
   begin
      Set_Blocked (G2, (5, 4), True);
      Initialize (Pl2, G2, (0, 4), (11, 4));
      Check (Near (Path_Cost (Pl), Path_Cost (Pl2)),
             "replan cost = fresh Initialize cost");
      Check (Expansion_Count (Pl2) >= E2
             or else Expansion_Count (Pl2) > Nat (0),
             "fresh restart ran a search");
      --  Incremental repair should not expand more than a full restart
      Check (E2 <= Expansion_Count (Pl2) + Nat (5),
             "replan expansions not wildly above restart");
   end;
   declare
      G2 : Grid;
   begin
      Clear (G2, Pos (12), Pos (8));
      Set_Blocked (G2, (5, 4), True);
      Expect_Match (G2, (0, 4), (11, 4), "blocked mid after change");
   end;

   Section ("Incremental replan — unblock restores short path");
   Clear (G, Pos (10), Pos (6));
   for Y in 0 .. 5 loop
      if Y /= 0 then
         Set_Blocked (G, (4, Y), True);
      end if;
   end loop;
   Initialize (Pl, G, (0, 3), (9, 3));
   Check (Path_Exists (Pl), "gap-at-top path");
   C := Path_Cost (Pl);
   Set_Blocked (Pl, (4, 3), False);  -- open a shorter hole on the row
   --  (4,3) may already be free — block the long way's necessity differently:
   --  close top gap and open middle
   Set_Blocked (Pl, (4, 0), True);
   Set_Blocked (Pl, (4, 3), False);
   Replan (Pl);
   Check (Path_Exists (Pl), "after opening middle");
   Check (Path_Cost (Pl) < C or else Near (Path_Cost (Pl), C),
          "cost did not increase after opening middle");

   Section ("Incremental — cost increase on path");
   Clear (G, Pos (9), Pos (5));
   Initialize (Pl, G, (0, 2), (8, 2));
   Check (Near (Path_Cost (Pl), Fl (8.0)), "uniform cost 8");
   Update_Cell_Cost (Pl, (4, 2), Fl (50.0));
   Replan (Pl);
   Check (Path_Exists (Pl), "after expensive cell");
   Check (Path_Cost (Pl) < Fl (50.0), "detours around expensive cell");
   declare
      G2 : Grid;
   begin
      Clear (G2, Pos (9), Pos (5));
      Set_Cell_Cost (G2, (4, 2), Fl (50.0));
      Expect_Match (G2, (0, 2), (8, 2), "expensive mid vs A*");
   end;

   Section ("Incremental cheaper than full restart");
   Clear (G, Pos (25), Pos (15));
   Initialize (Pl, G, (0, 7), (24, 7));
   E1 := Expansion_Count (Pl);
   Check (E1 >= Nat (20), "open corridor initial expansions");
   --  Off-path obstacle: start stays consistent → zero expansions
   Set_Blocked (Pl, (12, 0), True);
   Replan (Pl);
   Check (Expansion_Count (Pl) = Nat (0),
          "off-path block — replan expansions = 0");
   Check (Path_Exists (Pl), "off-path block — path unchanged");
   Check (Near (Path_Cost (Pl), Fl (24.0)), "off-path block — cost unchanged");

   --  Block near the start: incremental repair vs full restart
   Clear (G, Pos (25), Pos (15));
   Initialize (Pl, G, (0, 7), (24, 7));
   Set_Blocked (Pl, (1, 7), True);
   Replan (Pl);
   E2 := Expansion_Count (Pl);
   declare
      Pl_Full : Planner;
      G2      : Grid;
   begin
      Clear (G2, Pos (25), Pos (15));
      Set_Blocked (G2, (1, 7), True);
      Initialize (Pl_Full, G2, (0, 7), (24, 7));
      Check (Path_Exists (Pl) and then Path_Exists (Pl_Full),
             "both find path after near-start block");
      Check (Near (Path_Cost (Pl), Path_Cost (Pl_Full)),
             "incremental cost matches full restart");
      Check (E2 < Expansion_Count (Pl_Full),
             "replan expansions < full Initialize expansions");
   end;

   Section ("Make unreachable then recoverable");
   Clear (G, Pos (6), Pos (6));
   Initialize (Pl, G, (0, 0), (5, 5));
   Check (Path_Exists (Pl), "before seal");
   for X in 0 .. 5 loop
      Set_Blocked (Pl, (X, 2), True);
   end loop;
   Replan (Pl);
   Check (not Path_Exists (Pl), "sealed — unreachable");
   Set_Blocked (Pl, (3, 2), False);
   Replan (Pl);
   Check (Path_Exists (Pl), "unsealed — reachable again");
   Expect_Match_Seal:
   declare
      G2 : Grid;
   begin
      Clear (G2, Pos (6), Pos (6));
      for X in 0 .. 5 loop
         if X /= 3 then
            Set_Blocked (G2, (X, 2), True);
         end if;
      end loop;
      Expect_Match (G2, (0, 0), (5, 5), "unsealed map");
   end Expect_Match_Seal;

   Section ("Path_Cost helper on Grid");
   Clear (G, Pos (4), Pos (4));
   declare
      P : constant Path_Array (1 .. 4) := [(0, 0), (1, 0), (2, 0), (3, 0)];
   begin
      Check (Near (Path_Cost (G, P, Nat (4)), Fl (3.0)), "grid path cost 3");
      Check (Near (Path_Cost (G, P, Nat (1)), Fl (0.0)), "len 1 cost 0");
      Check (Near (Path_Cost (G, P, Nat (0)), Fl (0.0)), "len 0 cost 0");
   end;

   Section ("Many open-grid size variants");
   for N in 2 .. 16 loop
      Clear (G, Pos (N), Pos (N));
      Initialize (Pl, G, (0, 0), (N - 1, N - 1));
      Check (Path_Exists (Pl),
             "NxN exists N=" & Positive'Image (N));
      Check (Near (Path_Cost (Pl), Fl (Float (2 * (N - 1)))),
             "NxN cost N=" & Positive'Image (N));
   end loop;

   Section ("Many start/goal pairs on 8x8");
   Clear (G, Pos (8), Pos (8));
   Set_Blocked (G, (3, 3), True);
   Set_Blocked (G, (4, 4), True);
   Set_Blocked (G, (2, 5), True);
   declare
      Starts : constant array (1 .. 6) of Point :=
        [(0, 0), (0, 7), (7, 0), (7, 7), (1, 4), (5, 1)];
      Goals  : constant array (1 .. 6) of Point :=
        [(7, 7), (7, 0), (0, 7), (0, 0), (6, 6), (2, 2)];
   begin
      for I in Starts'Range loop
         Expect_Match
           (G, Starts (I), Goals (I),
            "8x8 pair" & Integer'Image (I));
      end loop;
   end;

   Section ("Replan idempotent");
   Clear (G, Pos (7), Pos (7));
   Initialize (Pl, G, (1, 1), (5, 5));
   C := Path_Cost (Pl);
   Replan (Pl);
   Check (Near (Path_Cost (Pl), C), "idle Replan same cost");
   Check (Path_Exists (Pl), "idle Replan still exists");
   Replan (Pl);
   Check (Near (Path_Cost (Pl), C), "second idle Replan");

   Section ("Max-size smoke");
   Clear (G, Pos (Max_Width), Pos (Max_Height));
   Initialize (Pl, G, (0, 0), (Max_Width - 1, 0));
   Check (Path_Exists (Pl), "max width row path");
   Check (Near (Path_Cost (Pl), Fl (Float (Max_Width - 1))),
          "max width row cost");

   Section ("A* vs D* Lite random-ish obstacles");
   Clear (G, Pos (15), Pos (15));
   for X in 0 .. 14 loop
      for Y in 0 .. 14 loop
         if ((X * 7 + Y * 3) mod 11 = 0)
           and then not (X = 0 and then Y = 0)
           and then not (X = 14 and then Y = 14)
         then
            Set_Blocked (G, (X, Y), True);
         end if;
      end loop;
   end loop;
   Expect_Match (G, (0, 0), (14, 14), "pseudo-random obstacles");
   Expect_Match (G, (0, 14), (14, 0), "pseudo-random opposite");
   Expect_Match (G, (2, 2), (12, 8), "pseudo-random mid");

   Section ("Expansion_Count positive after Initialize");
   Clear (G, Pos (5), Pos (5));
   Initialize (Pl, G, (0, 0), (4, 4));
   Check (Expansion_Count (Pl) >= Nat (5), "expansions >= 5 on 5x5");

   --  Summary
   New_Line;
   Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;

end Tests;
