pragma Ada_2022;
--  Own checks (V&V sweep agent A3; extended for H126 by agent-CF). Grids
--  are labelled and compared with an independent union-find over the cells
--  (each foreground cell joined with its foreground N/E/S/W neighbours).
--  Required: background cells are 0; two foreground cells have the same
--  label exactly when union-find puts them in the same set; the labels used
--  are exactly 1 .. Count; Count is the number of sets. Cases: every grid
--  of every region size up to 4 x 4 (Label_Region), 300 random regions up
--  to Max_Rows x Max_Cols with densities 10 .. 90 %, and 20 random full
--  grids through Label and Component_Count (seed 20261009).
with Ada.Text_IO;
with Connected_Component_Labeling; use Connected_Component_Labeling;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked  : Natural := 0;
   Seed     : Long_Long_Integer := 20261009;

   function Rand (N : Positive) return Natural is
   begin
      Seed := (Seed * 16807) mod 2_147_483_647;
      return Natural (Seed mod Long_Long_Integer (N));
   end Rand;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   Cells : constant Positive := Max_Rows * Max_Cols;
   subtype Cell is Positive range 1 .. Cells;
   function Id (R : Row_Index; C : Col_Index) return Cell is
     ((R - 1) * Max_Cols + C);

   type Parent_Array is array (Cell) of Cell;
   type Grid_Access is access Binary_Grid;
   type Labels_Access is access Label_Grid;
   type Parents_Access is access Parent_Array;
   Parent : constant Parents_Access := new Parent_Array;

   function Find (X : Cell) return Cell is
      Y : Cell := X;
   begin
      while Parent (Y) /= Y loop
         Y := Parent (Y);
      end loop;
      return Y;
   end Find;
   procedure Join (A, B : Cell) is
      RA : constant Cell := Find (A);
      RB : constant Cell := Find (B);
   begin
      if RA /= RB then
         Parent (RA) := RB;
      end if;
   end Join;

   --  Compare Out_G / N with union-find on G (1 .. Rows, 1 .. Cols).
   procedure Compare (G : Binary_Grid; Rows : Row_Count; Cols : Col_Count;
                      Out_G : Label_Grid; N : Label_Id; Tag : String) is
      Sets  : Natural := 0;
      Used  : array (0 .. Cells) of Boolean := [others => False];
      Root_Label : array (Cell) of Natural := [others => 0];
      Ok    : Boolean := True;
   begin
      for R in 1 .. Rows loop
         for C in 1 .. Cols loop
            Parent (Id (R, C)) := Id (R, C);
         end loop;
      end loop;
      for R in 1 .. Rows loop
         for C in 1 .. Cols loop
            if G (R, C) then
               if R < Rows and then G (R + 1, C) then
                  Join (Id (R, C), Id (R + 1, C));
               end if;
               if C < Cols and then G (R, C + 1) then
                  Join (Id (R, C), Id (R, C + 1));
               end if;
            end if;
         end loop;
      end loop;
      for R in 1 .. Rows loop
         for C in 1 .. Cols loop
            if G (R, C) and then Find (Id (R, C)) = Id (R, C) then
               Sets := Sets + 1;
            end if;
         end loop;
      end loop;
      Report (N = Sets, "Count = number of components" & Tag);
      --  same label iff same set: the map root -> label must be a bijection
      for R in 1 .. Rows loop
         for C in 1 .. Cols loop
            if (Out_G (R, C) = 0) /= not G (R, C) or else Out_G (R, C) > N then
               Ok := False;
            elsif G (R, C) then
               Used (Out_G (R, C)) := True;
               declare
                  Rt : constant Cell := Find (Id (R, C));
               begin
                  if Root_Label (Rt) = 0 then
                     Root_Label (Rt) := Out_G (R, C);
                  elsif Root_Label (Rt) /= Out_G (R, C) then
                     Ok := False;   --  one component, two labels
                  end if;
               end;
            end if;
         end loop;
      end loop;
      Report (Ok, "0 exactly on background, labels <= Count, one label per component" & Tag);
      --  distinct components get distinct labels: Count labels used, each once
      declare
         Distinct : Natural := 0;
      begin
         for L in 1 .. N loop
            if Used (L) then
               Distinct := Distinct + 1;
            end if;
         end loop;
         Report (Distinct = N and then Distinct = Sets, "labels are 1 .. Count, one per component" & Tag);
      end;
   end Compare;

   G     : constant Grid_Access := new Binary_Grid'[others => [others => False]];
   Out_G : constant Labels_Access := new Label_Grid;
   N     : Label_Id;
begin
   for Rows in 1 .. 4 loop
      for Cols in 1 .. 4 loop
         for Code in 0 .. 2 ** (Rows * Cols) - 1 loop
            G.all := [others => [others => False]];
            for R in 1 .. Rows loop
               for C in 1 .. Cols loop
                  G (R, C) := (Code / 2 ** ((R - 1) * Cols + C - 1)) mod 2 = 1;
               end loop;
            end loop;
            Label_Region (G.all, Rows, Cols, Out_G.all, N);
            Compare (G.all, Rows, Cols, Out_G.all, N,
                     ", region" & Rows'Image & " x" & Cols'Image & " grid" & Code'Image);
         end loop;
      end loop;
   end loop;
   for T in 1 .. 300 loop
      declare
         Rows    : constant Row_Count := 1 + Rand (Max_Rows);
         Cols    : constant Col_Count := 1 + Rand (Max_Cols);
         Density : constant Natural := 10 + Rand (81);
      begin
         G.all := [others => [others => Rand (2) = 0]];   --  outside the region: noise
         for R in 1 .. Rows loop
            for C in 1 .. Cols loop
               G (R, C) := Rand (100) < Density;
            end loop;
         end loop;
         Label_Region (G.all, Rows, Cols, Out_G.all, N);
         Compare (G.all, Rows, Cols, Out_G.all, N, ", random region" & T'Image);
      end;
   end loop;
   for T in 1 .. 20 loop
      declare
         Density : constant Natural := 30 + Rand (41);
      begin
         for R in Row_Index loop
            for C in Col_Index loop
               G (R, C) := Rand (100) < Density;
            end loop;
         end loop;
         Label (G.all, Out_G.all, N);
         Compare (G.all, Max_Rows, Max_Cols, Out_G.all, N, ", random full grid" & T'Image);
         Report (Component_Count (Out_G.all) = N, "Component_Count, random full grid" & T'Image);
      end;
   end loop;
   Ada.Text_IO.Put_Line
     ("Own checks:" & Checked'Image & " checks," & Failures'Image
      & " failures (seed 20261009)");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
