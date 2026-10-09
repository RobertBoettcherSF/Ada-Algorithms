pragma Ada_2022;
--  Own checks (V&V sweep, agent A3). Every Binary_Grid of the package's
--  size (2 ** (Max_Rows * Max_Cols) grids) is labelled and compared with an
--  independent union-find over the cells (each foreground cell joined with
--  its foreground N/E/S/W neighbours). Required: background cells are 0;
--  two foreground cells have the same label exactly when union-find puts
--  them in the same set; the labels used are exactly 1 .. Count (compact);
--  Count is the number of sets; Component_Count (Output) = Count.
with Ada.Text_IO;
with Connected_Component_Labeling; use Connected_Component_Labeling;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked  : Natural := 0;

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

   Parent : array (Cell) of Cell;
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

   G     : Binary_Grid;
   Out_G : Label_Grid;
   N     : Label_Id;
   Sets  : Natural;
   Used  : array (0 .. Cells) of Boolean;
begin
   for Code in 0 .. 2 ** Cells - 1 loop
      for R in Row_Index loop
         for C in Col_Index loop
            G (R, C) := (Code / 2 ** (Id (R, C) - 1)) mod 2 = 1;
         end loop;
      end loop;
      for X in Cell loop
         Parent (X) := X;
      end loop;
      for R in Row_Index loop
         for C in Col_Index loop
            if G (R, C) then
               if R < Max_Rows and then G (R + 1, C) then
                  Join (Id (R, C), Id (R + 1, C));
               end if;
               if C < Max_Cols and then G (R, C + 1) then
                  Join (Id (R, C), Id (R, C + 1));
               end if;
            end if;
         end loop;
      end loop;
      Sets := 0;
      for R in Row_Index loop
         for C in Col_Index loop
            if G (R, C) and then Find (Id (R, C)) = Id (R, C) then
               Sets := Sets + 1;
            end if;
         end loop;
      end loop;

      Label (G, Out_G, N);
      Report (N = Sets, "Count = number of components, grid" & Code'Image);
      Report (Component_Count (Out_G) = N, "Component_Count, grid" & Code'Image);
      Used := [others => False];
      for R in Row_Index loop
         for C in Col_Index loop
            Report ((Out_G (R, C) = 0) = not G (R, C),
                    "0 exactly on background, grid" & Code'Image);
            Used (Out_G (R, C)) := True;
            for R2 in Row_Index loop
               for C2 in Col_Index loop
                  if G (R, C) and then G (R2, C2) then
                     Report ((Out_G (R, C) = Out_G (R2, C2))
                             = (Find (Id (R, C)) = Find (Id (R2, C2))),
                             "same label iff connected, grid" & Code'Image);
                  end if;
               end loop;
            end loop;
         end loop;
      end loop;
      for L in 1 .. Cells loop
         Report (Used (L) = (L <= N), "labels are 1 .. Count, grid" & Code'Image);
      end loop;
   end loop;
   Ada.Text_IO.Put_Line
     ("Own checks:" & Checked'Image & " checks," & Failures'Image
      & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
