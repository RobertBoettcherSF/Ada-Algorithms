package body Watershed_Algorithm is

   type Point is record
      R, C : Integer; -- Changed from Positive to Integer to prevent Constraint_Error on edge neighbors
   end record;
   
   type Offset is record
      DR, DC : Integer;
   end record;
   
   -- 4-way connectivity
   Neighbors : constant array (1 .. 4) of Offset := 
     (( -1, 0 ), ( 1, 0 ), ( 0, -1 ), ( 0, 1 ));

   package Point_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Point);
     
   type Priority_Queue is array (Pixel_Value) of Point_Vectors.Vector;

   -- Helper: Check bounds
   function Is_Valid (P : Point; Image : Image_Grid) return Boolean is
   begin
      return P.R >= Image'First(1) and then P.R <= Image'Last(1) and then
             P.C >= Image'First(2) and then P.C <= Image'Last(2);
   end Is_Valid;

   -----------------------------------------------------
   -- 1. Meyer's Marker-Based Algorithm
   -----------------------------------------------------
   procedure Meyer_Watershed (
      Image   : in     Image_Grid;
      Markers : in     Label_Grid;
      Result  :    out Label_Grid
   ) is
      PQ : Priority_Queue;
      In_Queue : array (Image'Range(1), Image'Range(2)) of Boolean := (others => (others => False));
      Current, N_Pt : Point;
      Adj_Label : Label_Type;
      Diff_Label_Found : Boolean;
   begin
      if Image'Length(1) /= Markers'Length(1) or Image'Length(2) /= Markers'Length(2) or
         Image'Length(1) /= Result'Length(1)  or Image'Length(2) /= Result'Length(2) then
         raise Dimension_Mismatch;
      end if;
      
      if Image'Length(1) = 0 or Image'Length(2) = 0 then
         raise Empty_Image;
      end if;

      Result := Markers;

      -- Initialize Priority Queue with unlabeled pixels next to markers
      for R in Image'Range(1) loop
         for C in Image'Range(2) loop
            if Result(R, C) = UNLABELED then
               for N of Neighbors loop
                  N_Pt := (R + N.DR, C + N.DC);
                  if Is_Valid (N_Pt, Image) and then Result(N_Pt.R, N_Pt.C) > UNLABELED then
                     PQ(Image(R, C)).Append((R, C));
                     In_Queue(R, C) := True;
                     exit;
                  end if;
               end loop;
            end if;
         end loop;
      end loop;

      -- Process Priority Queue
      for Level in Pixel_Value loop
         while not PQ(Level).Is_Empty loop
            Current := PQ(Level).Last_Element;
            PQ(Level).Delete_Last;
            In_Queue(Current.R, Current.C) := False;
            
            Adj_Label := UNLABELED;
            Diff_Label_Found := False;
            
            -- Check neighbors to decide label or watershed line
            for N of Neighbors loop
               N_Pt := (Current.R + N.DR, Current.C + N.DC);
               if Is_Valid (N_Pt, Image) then
                  if Result(N_Pt.R, N_Pt.C) > UNLABELED then
                     if Adj_Label = UNLABELED then
                        Adj_Label := Result(N_Pt.R, N_Pt.C);
                     elsif Adj_Label /= Result(N_Pt.R, N_Pt.C) then
                        Diff_Label_Found := True;
                     end if;
                  end if;
               end if;
            end loop;

            if Diff_Label_Found then
               Result(Current.R, Current.C) := WATERSHED_LINE;
            elsif Adj_Label > UNLABELED then
               Result(Current.R, Current.C) := Adj_Label;
               -- Enqueue unlabeled neighbors
               for N of Neighbors loop
                  N_Pt := (Current.R + N.DR, Current.C + N.DC);
                  if Is_Valid(N_Pt, Image) and then Result(N_Pt.R, N_Pt.C) = UNLABELED and then not In_Queue(N_Pt.R, N_Pt.C) then
                     PQ(Image(N_Pt.R, N_Pt.C)).Append(N_Pt);
                     In_Queue(N_Pt.R, N_Pt.C) := True;
                  end if;
               end loop;
            end if;
         end loop;
      end loop;
   end Meyer_Watershed;

   -----------------------------------------------------
   -- 2. Immersion Algorithm (Vincent & Soille style)
   -----------------------------------------------------
   procedure Immersion_Watershed (
      Image  : in     Image_Grid;
      Result :    out Label_Grid
   ) is
      Current_Label : Label_Type := 0;
      Next_Label    : Label_Type;
      N_Pt          : Point;
   begin
      if Image'Length(1) /= Result'Length(1) or Image'Length(2) /= Result'Length(2) then
         raise Dimension_Mismatch;
      end if;
      
      if Image'Length(1) = 0 or Image'Length(2) = 0 then
         raise Empty_Image;
      end if;

      Result := (others => (others => UNLABELED));

      -- Simplified pass: level sets processing from 0 to 255
      for Lvl in Pixel_Value loop
         for R in Image'Range(1) loop
            for C in Image'Range(2) loop
               if Image(R, C) = Lvl and then Result(R, C) = UNLABELED then
                  Next_Label := UNLABELED;
                  for N of Neighbors loop
                     N_Pt := (R + N.DR, C + N.DC);
                     if Is_Valid(N_Pt, Image) and then Result(N_Pt.R, N_Pt.C) > UNLABELED then
                        if Next_Label = UNLABELED then
                           Next_Label := Result(N_Pt.R, N_Pt.C);
                        elsif Next_Label /= Result(N_Pt.R, N_Pt.C) then
                           Next_Label := WATERSHED_LINE;
                        end if;
                     end if;
                  end loop;
                  
                  if Next_Label = UNLABELED then
                     Current_Label := Current_Label + 1;
                     Result(R, C) := Current_Label;
                  else
                     Result(R, C) := Next_Label;
                  end if;
               end if;
            end loop;
         end loop;
      end loop;
   end Immersion_Watershed;

   -----------------------------------------------------
   -- 3. Topological Algorithm (Drop of Water)
   -----------------------------------------------------
   procedure Topological_Watershed (
      Image  : in     Image_Grid;
      Result :    out Label_Grid
   ) is
      Current_Label : Label_Type := 0;
      Lowest_Val    : Pixel_Value;
      Lowest_Pt     : Point;
      N_Pt          : Point;
      Path_Vec      : Point_Vectors.Vector;
      Curr_Pt       : Point;
   begin
      if Image'Length(1) /= Result'Length(1) or Image'Length(2) /= Result'Length(2) then
         raise Dimension_Mismatch;
      end if;
      
      if Image'Length(1) = 0 or Image'Length(2) = 0 then
         raise Empty_Image;
      end if;

      Result := (others => (others => UNLABELED));

      for R in Image'Range(1) loop
         for C in Image'Range(2) loop
            if Result(R, C) = UNLABELED then
               Path_Vec.Clear;
               Curr_Pt := (R, C);
               
               -- Steepest descent to minimum
               loop
                  Path_Vec.Append(Curr_Pt);
                  Lowest_Val := Image(Curr_Pt.R, Curr_Pt.C);
                  Lowest_Pt := Curr_Pt;
                  
                  for N of Neighbors loop
                     N_Pt := (Curr_Pt.R + N.DR, Curr_Pt.C + N.DC);
                     if Is_Valid(N_Pt, Image) and then Image(N_Pt.R, N_Pt.C) < Lowest_Val then
                        Lowest_Val := Image(N_Pt.R, N_Pt.C);
                        Lowest_Pt := N_Pt;
                     end if;
                  end loop;
                  
                  exit when Lowest_Pt.R = Curr_Pt.R and Lowest_Pt.C = Curr_Pt.C;
                  
                  Curr_Pt := Lowest_Pt;
                  if Result(Curr_Pt.R, Curr_Pt.C) /= UNLABELED then
                     exit;
                  end if;
               end loop;

               -- Assign labels to path
               declare
                  Target_Label : Label_Type;
               begin
                  if Result(Curr_Pt.R, Curr_Pt.C) = UNLABELED then
                     Current_Label := Current_Label + 1;
                     Target_Label := Current_Label;
                  else
                     Target_Label := Result(Curr_Pt.R, Curr_Pt.C);
                  end if;
                  
                  for Pt of Path_Vec loop
                     Result(Pt.R, Pt.C) := Target_Label;
                  end loop;
               end;
            end if;
         end loop;
      end loop;
   end Topological_Watershed;

end Watershed_Algorithm;
