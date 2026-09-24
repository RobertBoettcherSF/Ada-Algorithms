with Ada.Numerics; use Ada.Numerics;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Generalised_Hough_Transform is

   -- Helper to convert Radians to Discretized Degrees (0-359)
   function To_Degree_Index (Rad : Angle_Radian) return Angle_Degree is
      Normalized_Rad : Float := Float (Rad);
      Deg            : Integer;
   begin
      -- Normalize to [0, 2Pi)
      while Normalized_Rad < 0.0 loop
         Normalized_Rad := Normalized_Rad + 2.0 * Pi;
      end loop;
      while Normalized_Rad >= 2.0 * Pi loop
         Normalized_Rad := Normalized_Rad - 2.0 * Pi;
      end loop;
      
      Deg := Integer (Float'Rounding (Normalized_Rad * 180.0 / Pi));
      return Angle_Degree (Deg mod 360);
   end To_Degree_Index;

   -----------------------------------------------------------------------------
   -- Build_R_Table
   -----------------------------------------------------------------------------
   function Build_R_Table
     (Template_Edges  : Edge_Point_Array;
      Reference_Point : Point) return R_Table
   is
      Result : R_Table;
      Dx, Dy : Float;
      R      : Coordinate;
      Alpha  : Angle_Radian;
      Idx    : Angle_Degree;
   begin
      if Template_Edges'Length = 0 then
         raise Invalid_Data_Error with "Template_Edges cannot be empty.";
      end if;

      for E of Template_Edges loop
         Dx := Float (E.Location.X - Reference_Point.X);
         Dy := Float (E.Location.Y - Reference_Point.Y);
         
         R     := Coordinate (Sqrt (Dx**2 + Dy**2));
         Alpha := Angle_Radian (Arctan (Y => Dy, X => Dx));
         Idx   := To_Degree_Index (E.Gradient_Direction);
         
         Result.Entries (Idx).Append ((Radius => R, Alpha => Alpha));
      end loop;
      
      return Result;
   end Build_R_Table;

   -----------------------------------------------------------------------------
   -- Detect_Translation (Non-Preemptive / Spatial Translation Only)
   -----------------------------------------------------------------------------
   function Detect_Translation
     (Target_Edges : Edge_Point_Array;
      Table        : R_Table;
      Min_X, Max_X : Integer;
      Min_Y, Max_Y : Integer) return Detection_Result
   is
   begin
      -- Hand off to Extended transform with fixed scale 1.0 and rotation 0.0
      -- This ensures DRY modular design while preserving the interface.
      return Detect_Extended
        (Target_Edges => Target_Edges,
         Table        => Table,
         Min_X        => Min_X, Max_X => Max_X,
         Min_Y        => Min_Y, Max_Y => Max_Y,
         Scales       => (1 => 1.0),
         Rotations    => (1 => 0.0));
   end Detect_Translation;

   -----------------------------------------------------------------------------
   -- Detect_Extended (Translation, Scaling, and Rotation)
   -----------------------------------------------------------------------------
   function Detect_Extended
     (Target_Edges : Edge_Point_Array;
      Table        : R_Table;
      Min_X, Max_X : Integer;
      Min_Y, Max_Y : Integer;
      Scales       : Scale_Array;
      Rotations    : Rotation_Array) return Detection_Result
   is
      type Accumulator_Grid is array (Integer range Min_X .. Max_X, 
                                      Integer range Min_Y .. Max_Y) of Natural;
      
      Global_Best : Detection_Result := (Reference_Point => (0.0, 0.0), 
                                         Votes => 0, Scale => 1.0, Rotation => 0.0);
                                         
      Idx            : Angle_Degree;
      Alpha_Prime    : Float;
      Xc, Yc         : Integer;
      Current_Radius : Float;
   begin
      if Min_X > Max_X or Min_Y > Max_Y then
         raise Invalid_Bounds_Error with "Min bounds must be <= Max bounds.";
      end if;
      
      if Target_Edges'Length = 0 or Scales'Length = 0 or Rotations'Length = 0 then
         raise Invalid_Data_Error with "Input arrays cannot be empty.";
      end if;

      -- Iterate through all requested Scaling and Rotation parameters
      for S of Scales loop
         for Theta of Rotations loop
            declare
               -- Accumulator resets for every Scale/Rotation pair
               Acc : Accumulator_Grid := (others => (others => 0));
            begin
               -- Vote mapping
               for E of Target_Edges loop
                  
                  -- [BUG FIX]: In GHT, if a shape is rotated by Theta, the gradient rotates by Theta. 
                  -- To look up the original angle in the R-Table, we MUST subtract Theta.
                  Idx := To_Degree_Index (E.Gradient_Direction - Theta);
                  
                  for Item of Table.Entries (Idx) loop
                     Alpha_Prime := Float (Item.Alpha) + Float (Theta);
                     Current_Radius := Float (Item.Radius) * Float (S);
                     
                     -- Compute candidate reference point
                     Xc := Integer (Float'Rounding (Float (E.Location.X) - Current_Radius * Cos (Alpha_Prime)));
                     Yc := Integer (Float'Rounding (Float (E.Location.Y) - Current_Radius * Sin (Alpha_Prime)));
                     
                     -- Increment Accumulator if inside target image bounds
                     if Xc in Min_X .. Max_X and then Yc in Min_Y .. Max_Y then
                        Acc (Xc, Yc) := Acc (Xc, Yc) + 1;
                        
                        -- Update Global Maximum on the fly
                        if Acc (Xc, Yc) > Global_Best.Votes then
                           Global_Best.Votes := Acc (Xc, Yc);
                           Global_Best.Reference_Point := (Coordinate (Xc), Coordinate (Yc));
                           Global_Best.Scale := S;
                           Global_Best.Rotation := Theta;
                        end if;
                     end if;
                  end loop;
               end loop;
            end;
         end loop;
      end loop;

      return Global_Best;
   end Detect_Extended;

end Generalised_Hough_Transform;
