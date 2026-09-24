with Ada.Numerics.Elementary_Functions;
with Ada.Unchecked_Deallocation;

package body Grabcut is
   use Ada.Numerics.Elementary_Functions;

   -- Internal Graph Types for Max-Flow/Min-Cut
   type Node_ID is new Natural;
   type Flow_Matrix is array (Node_ID range <>, Node_ID range <>) of Float;
   type Flow_Matrix_Access is access Flow_Matrix;
   
   procedure Free_Matrix is new Ada.Unchecked_Deallocation
     (Object => Flow_Matrix,
      Name   => Flow_Matrix_Access);

   type Boolean_Array is array (Node_ID range <>) of Boolean;
   type Integer_Array is array (Node_ID range <>) of Integer;
   type Node_Queue is array (Positive range <>) of Node_ID;

   -- Validates the bounding box against image dimensions.
   function Is_Valid_Box (Img : Image; Box : Bounding_Box) return Boolean is
   begin
      return Box.Min_X <= Box.Max_X and then
             Box.Min_Y <= Box.Max_Y and then
             Box.Min_X >= Img'First(1) and then
             Box.Max_X <= Img'Last(1) and then
             Box.Min_Y >= Img'First(2) and then
             Box.Max_Y <= Img'Last(2);
   end Is_Valid_Box;

   -- Creates a mask based on the bounding box constraint.
   function Initialize_Mask (Img : Image; Box : Bounding_Box) return Segmentation_Mask is
      Mask : Segmentation_Mask (Img'Range(1), Img'Range(2));
   begin
      if not Is_Valid_Box (Img, Box) then
         raise Invalid_Box_Error;
      end if;

      for X in Img'Range(1) loop
         for Y in Img'Range(2) loop
            if X >= Box.Min_X and then X <= Box.Max_X and then
               Y >= Box.Min_Y and then Y <= Box.Max_Y
            then
               Mask (X, Y) := Probable_Foreground;
            else
               Mask (X, Y) := Background;
            end if;
         end loop;
      end loop;
      return Mask;
   end Initialize_Mask;

   -- Simplifies Mask to absolute Foreground / Background.
   function To_Binary (Mask : Segmentation_Mask) return Segmentation_Mask is
      Result : Segmentation_Mask (Mask'Range(1), Mask'Range(2));
   begin
      for X in Mask'Range(1) loop
         for Y in Mask'Range(2) loop
            if Mask (X, Y) = Probable_Foreground or else Mask (X, Y) = Foreground then
               Result (X, Y) := Foreground;
            else
               Result (X, Y) := Background;
            end if;
         end loop;
      end loop;
      return Result;
   end To_Binary;

   -- Edmonds-Karp Max-Flow algorithm implementation.
   procedure Solve_Max_Flow
     (Nodes    : Natural;
      Capacity : in out Flow_Matrix;
      Source   : Node_ID;
      Sink     : Node_ID;
      Visited  : out Boolean_Array)
   is
      Parent    : Integer_Array (0 .. Node_ID (Nodes));
      Queue     : Node_Queue (1 .. Nodes + 2);
      Head, Tail: Positive;
      Current   : Node_ID;
      Path_Flow : Float;
      V         : Node_ID;
   begin
      loop
         -- Breadth-First Search to find augmenting path
         for I in Parent'Range loop
            Parent (I) := -1;
         end loop;
         
         Parent (Source) := Integer (Source);
         Head := 1;
         Tail := 2;
         Queue (1) := Source;

         BFS_Loop :
         while Head < Tail loop
            Current := Queue (Head);
            Head := Head + 1;

            for Next_Node in Node_ID (0) .. Node_ID (Nodes) loop
               if Parent (Next_Node) = -1 and then Capacity (Current, Next_Node) > 0.0 then
                  Parent (Next_Node) := Integer (Current);
                  Queue (Tail) := Next_Node;
                  Tail := Tail + 1;
                  if Next_Node = Sink then
                     exit BFS_Loop;
                  end if;
               end if;
            end loop;
         end loop BFS_Loop;

         -- If no path to sink, we are done
         exit when Parent (Sink) = -1;

         -- Find bottleneck capacity
         Path_Flow := Float'Last;
         V := Sink;
         while V /= Source loop
            if Capacity (Node_ID (Parent (V)), V) < Path_Flow then
               Path_Flow := Capacity (Node_ID (Parent (V)), V);
            end if;
            V := Node_ID (Parent (V));
         end loop;

         -- Augment flow and update residual graph
         V := Sink;
         while V /= Source loop
            Capacity (Node_ID (Parent (V)), V) := Capacity (Node_ID (Parent (V)), V) - Path_Flow;
            Capacity (V, Node_ID (Parent (V))) := Capacity (V, Node_ID (Parent (V))) + Path_Flow;
            V := Node_ID (Parent (V));
         end loop;
      end loop;

      -- Final BFS to find nodes connected to the Source (Foreground)
      for I in Visited'Range loop
         Visited (I) := False;
      end loop;
      
      Head := 1;
      Tail := 2;
      Queue (1) := Source;
      Visited (Source) := True;
      
      while Head < Tail loop
         Current := Queue (Head);
         Head := Head + 1;
         for Next_Node in Node_ID (0) .. Node_ID (Nodes) loop
            if not Visited (Next_Node) and then Capacity (Current, Next_Node) > 0.0 then
               Visited (Next_Node) := True;
               Queue (Tail) := Next_Node;
               Tail := Tail + 1;
            end if;
         end loop;
      end loop;
   end Solve_Max_Flow;

   -- Helper to calculate Data cost (Negative Log Likelihood)
   function Calc_Penalty (Val : Pixel_Value; Mean, Var : Float) return Float is
      Diff : Float := Float (Val) - Mean;
   begin
      return (Diff * Diff) / (2.0 * Var) + 0.5 * Log (Var);
   end Calc_Penalty;

   -- Performs one iteration of the GrabCut step (Stats + Graph Cut)
   function Segment_By_Mask
     (Img        : Image;
      Mask       : Segmentation_Mask;
      Iterations : Positive := 1) return Segmentation_Mask
   is
      Result     : Segmentation_Mask (Img'Range(1), Img'Range(2));
      Node_Count : constant Natural := Img'Length (1) * Img'Length (2) + 1;
      Source     : constant Node_ID := 0;
      Sink       : constant Node_ID := Node_ID (Node_Count);
      
      Capacity   : Flow_Matrix_Access;
      Visited    : Boolean_Array (0 .. Sink);

      Mean_F, Mean_B : Float := 0.0;
      Var_F, Var_B   : Float := 1.0;
      Sum_F, Sum_B   : Float;
      Cnt_F, Cnt_B   : Float;

      Beta, Total_Diff, Pair_Count : Float;
      Gamma     : constant Float := 50.0;
      Large_Cap : constant Float := 1.0e9;
      
      function Get_Node (X, Y : Positive) return Node_ID is
      begin
         return Node_ID ((Y - Img'First(2)) * Img'Length(1) + (X - Img'First(1)) + 1);
      end Get_Node;

   begin
      if Img'Length(1) = 0 or else Img'Length(2) = 0 then
         raise Invalid_Image_Error;
      end if;
      
      if Img'Length(1) /= Mask'Length(1) or else Img'Length(2) /= Mask'Length(2) then
         raise Invalid_Mask_Error;
      end if;

      Result := Mask;

      for Iter in 1 .. Iterations loop
         -- 1. Calculate simplified GMMs (1-component Gaussian)
         Sum_F := 0.0; Sum_B := 0.0;
         Cnt_F := 0.0; Cnt_B := 0.0;

         for Y in Img'Range(2) loop
            for X in Img'Range(1) loop
               if Result (X, Y) = Foreground or else Result (X, Y) = Probable_Foreground then
                  Sum_F := Sum_F + Float (Img (X, Y));
                  Cnt_F := Cnt_F + 1.0;
               else
                  Sum_B := Sum_B + Float (Img (X, Y));
                  Cnt_B := Cnt_B + 1.0;
               end if;
            end loop;
         end loop;

         Mean_F := (if Cnt_F > 0.0 then Sum_F / Cnt_F else 0.0);
         Mean_B := (if Cnt_B > 0.0 then Sum_B / Cnt_B else 0.0);

         Sum_F := 0.0; Sum_B := 0.0;
         for Y in Img'Range(2) loop
            for X in Img'Range(1) loop
               if Result (X, Y) = Foreground or else Result (X, Y) = Probable_Foreground then
                  Sum_F := Sum_F + (Float (Img (X, Y)) - Mean_F)**2;
               else
                  Sum_B := Sum_B + (Float (Img (X, Y)) - Mean_B)**2;
               end if;
            end loop;
         end loop;

         Var_F := Float'Max (1.0, (if Cnt_F > 0.0 then Sum_F / Cnt_F else 1.0));
         Var_B := Float'Max (1.0, (if Cnt_B > 0.0 then Sum_B / Cnt_B else 1.0));

         -- 2. Calculate Beta (Smoothness scalar)
         Total_Diff := 0.0;
         Pair_Count := 0.0;
         for Y in Img'Range(2) loop
            for X in Img'Range(1) loop
               if X < Img'Last(1) then
                  Total_Diff := Total_Diff + Float ((Integer (Img (X, Y)) - Integer (Img (X + 1, Y)))**2);
                  Pair_Count := Pair_Count + 1.0;
               end if;
               if Y < Img'Last(2) then
                  Total_Diff := Total_Diff + Float ((Integer (Img (X, Y)) - Integer (Img (X, Y + 1)))**2);
                  Pair_Count := Pair_Count + 1.0;
               end if;
            end loop;
         end loop;
         
         Beta := (if Pair_Count > 0.0 and then Total_Diff > 0.0 then 1.0 / (2.0 * (Total_Diff / Pair_Count)) else 0.0);

         -- 3. Construct Graph
         Capacity := new Flow_Matrix (0 .. Sink, 0 .. Sink);
         for I in 0 .. Sink loop
            for J in 0 .. Sink loop
               Capacity.all (I, J) := 0.0;
            end loop;
         end loop;

         for Y in Img'Range(2) loop
            for X in Img'Range(1) loop
               declare
                  U   : constant Node_ID := Get_Node (X, Y);
                  D_F : constant Float   := Calc_Penalty (Img (X, Y), Mean_F, Var_F);
                  D_B : constant Float   := Calc_Penalty (Img (X, Y), Mean_B, Var_B);
               begin
                  -- T-links
                  if Result (X, Y) = Foreground then
                     Capacity.all (Source, U) := Large_Cap;
                     Capacity.all (U, Sink)   := 0.0;
                  elsif Result (X, Y) = Background then
                     Capacity.all (Source, U) := 0.0;
                     Capacity.all (U, Sink)   := Large_Cap;
                  else
                     Capacity.all (Source, U) := D_B;
                     Capacity.all (U, Sink)   := D_F;
                  end if;

                  -- N-links
                  if X < Img'Last(1) then
                     declare
                        V   : constant Node_ID := Get_Node (X + 1, Y);
                        Wgt : constant Float   := Gamma * Exp (-Beta * Float ((Integer (Img (X, Y)) - Integer (Img (X + 1, Y)))**2));
                     begin
                        Capacity.all (U, V) := Capacity.all (U, V) + Wgt;
                        Capacity.all (V, U) := Capacity.all (V, U) + Wgt;
                     end;
                  end if;
                  
                  if Y < Img'Last(2) then
                     declare
                        V   : constant Node_ID := Get_Node (X, Y + 1);
                        Wgt : constant Float   := Gamma * Exp (-Beta * Float ((Integer (Img (X, Y)) - Integer (Img (X, Y + 1)))**2));
                     begin
                        Capacity.all (U, V) := Capacity.all (U, V) + Wgt;
                        Capacity.all (V, U) := Capacity.all (V, U) + Wgt;
                     end;
                  end if;
               end;
            end loop;
         end loop;

         -- 4. Execute Min-Cut
         Solve_Max_Flow (Node_Count, Capacity.all, Source, Sink, Visited);
         Free_Matrix (Capacity);

         -- 5. Update Mask
         for Y in Img'Range(2) loop
            for X in Img'Range(1) loop
               if Result (X, Y) = Probable_Foreground or else Result (X, Y) = Probable_Background then
                  if Visited (Get_Node (X, Y)) then
                     Result (X, Y) := Probable_Foreground;
                  else
                     Result (X, Y) := Probable_Background;
                  end if;
               end if;
            end loop;
         end loop;
      end loop;

      return Result;
   end Segment_By_Mask;

   -- Box-based initialization and execution
   function Segment_By_Box
     (Img        : Image;
      Box        : Bounding_Box;
      Iterations : Positive := 1) return Segmentation_Mask
   is
      Initial_Mask : Segmentation_Mask (Img'Range(1), Img'Range(2));
   begin
      Initial_Mask := Initialize_Mask (Img, Box);
      return Segment_By_Mask (Img, Initial_Mask, Iterations);
   end Segment_By_Box;

   -- Runs the algorithm until convergence
   function Segment_One_Shot
     (Img : Image;
      Box : Bounding_Box) return Segmentation_Mask
   is
      Mask, Prev_Mask : Segmentation_Mask (Img'Range(1), Img'Range(2));
      Max_Iters : constant Positive := 10;
   begin
      Mask := Initialize_Mask (Img, Box);
      for I in 1 .. Max_Iters loop
         Prev_Mask := Mask;
         Mask := Segment_By_Mask (Img, Mask, 1);
         if Mask = Prev_Mask then
            exit;
         end if;
      end loop;
      return Mask;
   end Segment_One_Shot;

end Grabcut;
