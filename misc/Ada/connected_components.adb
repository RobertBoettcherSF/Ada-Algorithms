-- connected_components.adb
-- Body for the Connected-Component Labeling algorithm
package body Connected_Components is

   -----------------------------------------------------------------------------
   -- Helper: Validate bounds of Input and Output arrays
   -----------------------------------------------------------------------------
   procedure Validate_Bounds (Input : Binary_Image; Output : Label_Image) is
   begin
      if Input'Length(1) /= Output'Length(1) or else Input'Length(2) /= Output'Length(2) then
         raise Bounds_Mismatch_Error with "Input and Output dimensions must match.";
      end if;
      if Input'First(1) /= Output'First(1) or else Input'First(2) /= Output'First(2) then
         raise Bounds_Mismatch_Error with "Input and Output starting indices must match.";
      end if;
   end Validate_Bounds;

   -----------------------------------------------------------------------------
   -- Variant 1: Two-Pass Labeling using Union-Find (Disjoint Set)
   -----------------------------------------------------------------------------
   procedure Two_Pass_Labeling (
      Input        : in  Binary_Image;
      Output       : out Label_Image;
      Connectivity : in  Connectivity_Type
   ) is
      -- Maximum possible disjoint components (e.g. checkerboard pattern)
      Max_Labels : constant Natural := (Input'Length(1) * Input'Length(2)) / 2 + 1;
      Parents    : array (1 .. Max_Labels) of Natural := (others => 0);
      Next_Label : Natural := 1;

      -- Union-Find: Find with Path Compression
      function Find (X : Natural) return Natural is
         Root : Natural := X;
         Curr : Natural;
         Next : Natural;
      begin
         while Parents (Root) /= Root loop
            Root := Parents (Root);
         end loop;
         
         -- Path compression
         Curr := X;
         while Curr /= Root loop
            Next := Parents (Curr);
            Parents (Curr) := Root;
            Curr := Next;
         end loop;
         return Root;
      end Find;

      -- Union-Find: Union operation (links larger label to smaller label)
      procedure Union (X, Y : Natural) is
         Root_X : constant Natural := Find (X);
         Root_Y : constant Natural := Find (Y);
      begin
         if Root_X < Root_Y then
            Parents (Root_Y) := Root_X;
         elsif Root_Y < Root_X then
            Parents (Root_X) := Root_Y;
         end if;
      end Union;

   begin
      if Input'Length(1) = 0 or else Input'Length(2) = 0 then
         return; -- Edge case: Empty input
      end if;

      Validate_Bounds (Input, Output);
      Output := (others => (others => 0));

      -- Pass 1: Assign initial labels and record equivalences
      for R in Input'Range(1) loop
         for C in Input'Range(2) loop
            if Input (R, C) then
               declare
                  Neighbors : array (1 .. 4) of Natural := (others => 0);
                  Min_Label : Natural := Natural'Last;
                  Count     : Natural := 0;
               begin
                  -- Check Left (4 and 8 connected)
                  if C > Input'First(2) and then Output(R, C - 1) > 0 then
                     Count := Count + 1;
                     Neighbors(Count) := Output(R, C - 1);
                  end if;
                  
                  -- Check Top (4 and 8 connected)
                  if R > Input'First(1) and then Output(R - 1, C) > 0 then
                     Count := Count + 1;
                     Neighbors(Count) := Output(R - 1, C);
                  end if;

                  if Connectivity = Eight_Connected then
                     -- Check Top-Left
                     if R > Input'First(1) and then C > Input'First(2) and then Output(R - 1, C - 1) > 0 then
                        Count := Count + 1;
                        Neighbors(Count) := Output(R - 1, C - 1);
                     end if;
                     -- Check Top-Right
                     if R > Input'First(1) and then C < Input'Last(2) and then Output(R - 1, C + 1) > 0 then
                        Count := Count + 1;
                        Neighbors(Count) := Output(R - 1, C + 1);
                     end if;
                  end if;

                  if Count = 0 then
                     -- New component
                     Output(R, C) := Next_Label;
                     Parents(Next_Label) := Next_Label;
                     Next_Label := Next_Label + 1;
                  else
                     -- Find minimum label among neighbors
                     for I in 1 .. Count loop
                        if Neighbors(I) < Min_Label then
                           Min_Label := Neighbors(I);
                        end if;
                     end loop;
                     
                     Output(R, C) := Min_Label;
                     
                     -- Record equivalences
                     for I in 1 .. Count loop
                        Union(Min_Label, Neighbors(I));
                     end loop;
                  end if;
               end;
            end if;
         end loop;
      end loop;

      -- Pass 2: Resolve equivalences and compact labels sequentially
      declare
         Label_Map           : array (1 .. Next_Label) of Natural := (others => 0);
         Current_Final_Label : Natural := 1;
      begin
         for R in Output'Range(1) loop
            for C in Output'Range(2) loop
               if Output(R, C) > 0 then
                  declare
                     Root : constant Natural := Find(Output(R, C));
                  begin
                     if Label_Map(Root) = 0 then
                        Label_Map(Root) := Current_Final_Label;
                        Current_Final_Label := Current_Final_Label + 1;
                     end if;
                     Output(R, C) := Label_Map(Root);
                  end;
               end if;
            end loop;
         end loop;
      end;
   end Two_Pass_Labeling;

   -----------------------------------------------------------------------------
   -- Variant 2: Breadth-First Search (BFS) Labeling
   -----------------------------------------------------------------------------
   procedure BFS_Labeling (
      Input        : in  Binary_Image;
      Output       : out Label_Image;
      Connectivity : in  Connectivity_Type
   ) is
      type Coordinate is record
         R, C : Positive;
      end record;
      
      Queue       : array (1 .. Input'Length(1) * Input'Length(2)) of Coordinate;
      Head, Tail  : Natural := 1;
      Current_Lbl : Natural := 1;

      procedure Push (R, C : Positive) is
      begin
         Queue(Tail) := (R, C);
         Tail := Tail + 1;
      end Push;

      procedure Pop (R, C : out Positive) is
      begin
         R := Queue(Head).R;
         C := Queue(Head).C;
         Head := Head + 1;
      end Pop;
   begin
      if Input'Length(1) = 0 or else Input'Length(2) = 0 then
         return;
      end if;

      Validate_Bounds (Input, Output);
      Output := (others => (others => 0));

      for R in Input'Range(1) loop
         for C in Input'Range(2) loop
            if Input(R, C) and then Output(R, C) = 0 then
               -- Discovered new component
               Push(R, C);
               Output(R, C) := Current_Lbl;

               -- Process Queue
               while Head < Tail loop
                  declare
                     Curr_R, Curr_C : Positive;
                  begin
                     Pop(Curr_R, Curr_C);

                     -- 4-Connected Neighbors
                     if Curr_R > Input'First(1) and then Input(Curr_R - 1, Curr_C) and then Output(Curr_R - 1, Curr_C) = 0 then
                        Output(Curr_R - 1, Curr_C) := Current_Lbl; Push(Curr_R - 1, Curr_C);
                     end if;
                     if Curr_R < Input'Last(1) and then Input(Curr_R + 1, Curr_C) and then Output(Curr_R + 1, Curr_C) = 0 then
                        Output(Curr_R + 1, Curr_C) := Current_Lbl; Push(Curr_R + 1, Curr_C);
                     end if;
                     if Curr_C > Input'First(2) and then Input(Curr_R, Curr_C - 1) and then Output(Curr_R, Curr_C - 1) = 0 then
                        Output(Curr_R, Curr_C - 1) := Current_Lbl; Push(Curr_R, Curr_C - 1);
                     end if;
                     if Curr_C < Input'Last(2) and then Input(Curr_R, Curr_C + 1) and then Output(Curr_R, Curr_C + 1) = 0 then
                        Output(Curr_R, Curr_C + 1) := Current_Lbl; Push(Curr_R, Curr_C + 1);
                     end if;

                     -- 8-Connected Neighbors
                     if Connectivity = Eight_Connected then
                        if Curr_R > Input'First(1) and then Curr_C > Input'First(2) and then Input(Curr_R - 1, Curr_C - 1) and then Output(Curr_R - 1, Curr_C - 1) = 0 then
                           Output(Curr_R - 1, Curr_C - 1) := Current_Lbl; Push(Curr_R - 1, Curr_C - 1);
                        end if;
                        if Curr_R > Input'First(1) and then Curr_C < Input'Last(2) and then Input(Curr_R - 1, Curr_C + 1) and then Output(Curr_R - 1, Curr_C + 1) = 0 then
                           Output(Curr_R - 1, Curr_C + 1) := Current_Lbl; Push(Curr_R - 1, Curr_C + 1);
                        end if;
                        if Curr_R < Input'Last(1) and then Curr_C > Input'First(2) and then Input(Curr_R + 1, Curr_C - 1) and then Output(Curr_R + 1, Curr_C - 1) = 0 then
                           Output(Curr_R + 1, Curr_C - 1) := Current_Lbl; Push(Curr_R + 1, Curr_C - 1);
                        end if;
                        if Curr_R < Input'Last(1) and then Curr_C < Input'Last(2) and then Input(Curr_R + 1, Curr_C + 1) and then Output(Curr_R + 1, Curr_C + 1) = 0 then
                           Output(Curr_R + 1, Curr_C + 1) := Current_Lbl; Push(Curr_R + 1, Curr_C + 1);
                        end if;
                     end if;
                  end;
               end loop;
               Current_Lbl := Current_Lbl + 1;
            end if;
         end loop;
      end loop;
   end BFS_Labeling;

   -----------------------------------------------------------------------------
   -- Helper: Count unique components
   -----------------------------------------------------------------------------
   function Count_Components (Output : Label_Image) return Natural is
      Max_Found : Natural := 0;
   begin
      for R in Output'Range(1) loop
         for C in Output'Range(2) loop
            if Output(R, C) > Max_Found then
               Max_Found := Output(R, C);
            end if;
         end loop;
      end loop;
      return Max_Found;
   end Count_Components;

end Connected_Components;
