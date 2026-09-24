-- hough_transform.adb
-- Implementation of Hough Transform variants.
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Hough_Transform is

   -----------------------
   -- Transform_Lines   --
   -----------------------
   function Transform_Lines (Image : Binary_Image) return Line_Accumulator is
      -- Calculate max possible Rho (diagonal length of the image)
      W : Float := Float (Image'Length(1));
      H : Float := Float (Image'Length(2));
      Max_Rho_Float : Float := Sqrt (W**2.0 + H**2.0);
      Max_Rho : Rho_Distance := Rho_Distance (Max_Rho_Float + 1.0);
      
      -- Initialize accumulator with zeros
      Acc : Line_Accumulator (-Max_Rho .. Max_Rho, Theta_Angle'Range) := (others => (others => 0));
      
      Theta_Rad : Float;
      Rho_Calc  : Integer;
   begin
      -- Edge case: Empty image bounds
      if Image'Length(1) = 0 or Image'Length(2) = 0 then
         return Acc;
      end if;

      for X in Image'Range(1) loop
         for Y in Image'Range(2) loop
            if Image (X, Y) then
               -- For every edge pixel, vote for all possible lines passing through it
               for Theta in Theta_Angle'Range loop
                  Theta_Rad := Float (Theta) * Ada.Numerics.Pi / 180.0;
                  
                  -- Hough Line Equation: rho = x*cos(theta) + y*sin(theta)
                  Rho_Calc := Integer (Float(X) * Cos(Theta_Rad) + Float(Y) * Sin(Theta_Rad));
                  
                  -- Increment the vote safely within bounds
                  if Rho_Distance(Rho_Calc) in Acc'Range(1) then
                     Acc (Rho_Distance(Rho_Calc), Theta) := Acc (Rho_Distance(Rho_Calc), Theta) + 1;
                  end if;
               end loop;
            end if;
         end loop;
      end loop;
      
      return Acc;
   end Transform_Lines;

   -----------------------
   -- Transform_Circles --
   -----------------------
   function Transform_Circles (Image : Binary_Image; Radii : Radius_Array) return Circle_Accumulator is
      -- Accumulator covers the image space + radii index
      Acc : Circle_Accumulator (Image'Range(1), Image'Range(2), Radii'Range) := 
            (others => (others => (others => 0)));
            
      Theta_Rad : Float;
      Xc, Yc    : Pixel_Coord;
   begin
      -- Edge case validation
      if Image'Length(1) = 0 or Image'Length(2) = 0 or Radii'Length = 0 then
         return Acc;
      end if;

      for X in Image'Range(1) loop
         for Y in Image'Range(2) loop
            if Image (X, Y) then
               -- For every edge pixel, cast a vote in a circle around it for each radius
               for R_Idx in Radii'Range loop
                  for Angle in 0 .. 359 loop
                     Theta_Rad := Float (Angle) * Ada.Numerics.Pi / 180.0;
                     
                     -- Calculate center coordinate
                     Xc := Pixel_Coord (Float(X) - Float(Radii(R_Idx)) * Cos(Theta_Rad));
                     Yc := Pixel_Coord (Float(Y) - Float(Radii(R_Idx)) * Sin(Theta_Rad));
                     
                     -- Cast vote if center is within image bounds
                     if Xc in Acc'Range(1) and then Yc in Acc'Range(2) then
                        Acc (Xc, Yc, R_Idx) := Acc (Xc, Yc, R_Idx) + 1;
                     end if;
                  end loop;
               end loop;
            end if;
         end loop;
      end loop;
      
      return Acc;
   end Transform_Circles;

   ---------------------------
   -- Transform_Generalized --
   ---------------------------
   function Transform_Generalized (Image : Binary_Image) return General_Accumulator is
   begin
      -- Documented Placeholder: Requires user-supplied template geometry (R-Table).
      raise Not_Implemented with "Generalized HT requires external R-Table template initialization.";
      return (Image'Range(1) => (Image'Range(2) => 0));
   end Transform_Generalized;

end Hough_Transform;
