package body Region_Growing is

   package Point_Lists is new Ada.Containers.Doubly_Linked_Lists (Element_Type => Point);
   use Point_Lists;

   -- Helper Function: Get valid neighbors for a given point
   procedure Get_Neighbors (
      P            : Point;
      Max_X, Max_Y : Positive;
      Connectivity : Connectivity_Type;
      Neighbors    : out Point_Array;
      Count        : out Natural
   ) is
      Current_Index : Natural := 0;

      procedure Add_If_Valid (NX, NY : Integer) is
      begin
         if NX >= 1 and NX <= Max_X and NY >= 1 and NY <= Max_Y then
            Current_Index := Current_Index + 1;
            Neighbors (Current_Index) := (X => NX, Y => NY);
         end if;
      end Add_If_Valid;
   begin
      Count := 0;
      -- 4-Connected Neighbors (Top, Bottom, Left, Right)
      Add_If_Valid (P.X, P.Y - 1);
      Add_If_Valid (P.X, P.Y + 1);
      Add_If_Valid (P.X - 1, P.Y);
      Add_If_Valid (P.X + 1, P.Y);

      -- 8-Connected Neighbors (Diagonals)
      if Connectivity = Eight_Connected then
         Add_If_Valid (P.X - 1, P.Y - 1);
         Add_If_Valid (P.X + 1, P.Y - 1);
         Add_If_Valid (P.X - 1, P.Y + 1);
         Add_If_Valid (P.X + 1, P.Y + 1);
      end if;
      Count := Current_Index;
   end Get_Neighbors;

   -- Implementation for Variant 1: Seeded Local
   function Seeded_Local (
      Input_Image  : Image;
      Seeds        : Point_Array;
      Threshold    : Natural;
      Connectivity : Connectivity_Type := Four_Connected
   ) return Mask is
      Result    : Mask (Input_Image'Range(1), Input_Image'Range(2)) := (others => (others => False));
      Queue     : List;
      Current_P : Point;
      Neighbors : Point_Array (1 .. 8);
      N_Count   : Natural;
   begin
      -- Validate and enqueue seeds
      for I in Seeds'Range loop
         if Seeds(I).X not in Input_Image'Range(1) or else Seeds(I).Y not in Input_Image'Range(2) then
            raise Invalid_Seed_Error;
         end if;
         Result (Seeds(I).X, Seeds(I).Y) := True;
         Queue.Append (Seeds(I));
      end loop;

      -- Process frontier queue
      while not Queue.Is_Empty loop
         Current_P := Queue.First_Element;
         Queue.Delete_First;

         Get_Neighbors (Current_P, Input_Image'Last(1), Input_Image'Last(2), Connectivity, Neighbors, N_Count);

         for I in 1 .. N_Count loop
            declare
               N : Point := Neighbors(I);
               Diff : Integer := Integer (Input_Image (N.X, N.Y)) - Integer (Input_Image (Current_P.X, Current_P.Y));
            begin
               -- Edge condition: Check if already visited and if similarity constraint holds
               if not Result (N.X, N.Y) and then abs (Diff) <= Threshold then
                  Result (N.X, N.Y) := True;
                  Queue.Append (N);
               end if;
            end;
         end loop;
      end loop;

      return Result;
   end Seeded_Local;

   -- Implementation for Variant 2: Seeded Average
   function Seeded_Average (
      Input_Image  : Image;
      Seeds        : Point_Array;
      Threshold    : Natural;
      Connectivity : Connectivity_Type := Four_Connected
   ) return Mask is
      Result       : Mask (Input_Image'Range(1), Input_Image'Range(2)) := (others => (others => False));
      Queue        : List;
      Current_P    : Point;
      Neighbors    : Point_Array (1 .. 8);
      N_Count      : Natural;
      Region_Sum   : Long_Integer := 0;
      Region_Count : Long_Integer := 0;
      Average      : Integer;
   begin
      if Seeds'Length = 0 then
         return Result;
      end if;

      for I in Seeds'Range loop
         if Seeds(I).X not in Input_Image'Range(1) or else Seeds(I).Y not in Input_Image'Range(2) then
            raise Invalid_Seed_Error;
         end if;
         if not Result (Seeds(I).X, Seeds(I).Y) then
            Result (Seeds(I).X, Seeds(I).Y) := True;
            Queue.Append (Seeds(I));
            Region_Sum := Region_Sum + Long_Integer (Input_Image (Seeds(I).X, Seeds(I).Y));
            Region_Count := Region_Count + 1;
         end if;
      end loop;

      while not Queue.Is_Empty loop
         Current_P := Queue.First_Element;
         Queue.Delete_First;

         Get_Neighbors (Current_P, Input_Image'Last(1), Input_Image'Last(2), Connectivity, Neighbors, N_Count);

         Average := Integer (Region_Sum / Region_Count);

         for I in 1 .. N_Count loop
            declare
               N : Point := Neighbors(I);
               Diff : Integer := Integer (Input_Image (N.X, N.Y)) - Average;
            begin
               if not Result (N.X, N.Y) and then abs (Diff) <= Threshold then
                  Result (N.X, N.Y) := True;
                  Queue.Append (N);
                  Region_Sum := Region_Sum + Long_Integer (Input_Image (N.X, N.Y));
                  Region_Count := Region_Count + 1;
               end if;
            end;
         end loop;
      end loop;

      return Result;
   end Seeded_Average;

   -- Implementation for Variant 3: Unseeded
   function Unseeded (
      Input_Image  : Image;
      Threshold    : Natural;
      Connectivity : Connectivity_Type := Four_Connected
   ) return Region_Map is
      Result       : Region_Map (Input_Image'Range(1), Input_Image'Range(2)) := (others => (others => 0));
      Current_ID   : Natural := 0;
      Queue        : List;
      Current_P    : Point;
      Neighbors    : Point_Array (1 .. 8);
      N_Count      : Natural;
   begin
      -- Scan entire image for unassigned pixels
      for X in Input_Image'Range(1) loop
         for Y in Input_Image'Range(2) loop
            if Result (X, Y) = 0 then
               Current_ID := Current_ID + 1;
               Result (X, Y) := Current_ID;
               Queue.Append ((X, Y));

               -- Grow region from this implicit seed
               while not Queue.Is_Empty loop
                  Current_P := Queue.First_Element;
                  Queue.Delete_First;

                  Get_Neighbors (Current_P, Input_Image'Last(1), Input_Image'Last(2), Connectivity, Neighbors, N_Count);

                  for I in 1 .. N_Count loop
                     declare
                        N : Point := Neighbors(I);
                        Diff : Integer := Integer (Input_Image (N.X, N.Y)) - Integer (Input_Image (Current_P.X, Current_P.Y));
                     begin
                        if Result (N.X, N.Y) = 0 and then abs (Diff) <= Threshold then
                           Result (N.X, N.Y) := Current_ID;
                           Queue.Append (N);
                        end if;
                     end;
                  end loop;
               end loop;
            end if;
         end loop;
      end loop;

      return Result;
   end Unseeded;

end Region_Growing;
