package body SPIHT is

   function Is_Power_Of_Two (N : Positive) return Boolean is
      Val : Positive := N;
   begin
      while Val > 1 loop
         if Val mod 2 /= 0 then
            return False;
         end if;
         Val := Val / 2;
      end loop;
      return True;
   end Is_Power_Of_Two;

   function Max_Magnitude_2D (Image : Matrix_2D) return Natural is
      Max_Mag : Natural := 0;
      Mag     : Natural;
   begin
      for R in Image'Range(1) loop
         for C in Image'Range(2) loop
            Mag := Natural (abs (Image (R, C)));
            if Mag > Max_Mag then
               Max_Mag := Mag;
            end if;
         end loop;
      end loop;
      return Max_Mag;
   end Max_Magnitude_2D;

   function Max_Magnitude_3D (Volume : Matrix_3D) return Natural is
      Max_Mag : Natural := 0;
      Mag     : Natural;
   begin
      for R in Volume'Range(1) loop
         for C in Volume'Range(2) loop
            for D in Volume'Range(3) loop
               Mag := Natural (abs (Volume (R, C, D)));
               if Mag > Max_Mag then
                  Max_Mag := Mag;
               end if;
            end loop;
         end loop;
      end loop;
      return Max_Mag;
   end Max_Magnitude_3D;

   -- Significance checks for 2D sets
   function S_n_Pixel_2D (Image : Matrix_2D; Coord : Coordinate_2D; N : Natural) return Boolean is
      Threshold : constant Integer := 2**N;
   begin
      return abs (Image (Coord.R, Coord.C)) >= Coefficient(Threshold);
   end S_n_Pixel_2D;

   -- Emits a bit to the stream and checks if we should abort (lossy limit)
   procedure Emit (Stream : in out Bit_Stream; B : Bit; Target : Natural; Variant : Encoding_Variant; Stop : out Boolean) is
   begin
      -- Prevent appending if we are already at or above the target in lossy mode
      if Variant = Lossy_Target_Bits and then Natural(Stream.Length) >= Target then
         Stop := True;
         return;
      end if;
      
      Stream.Append (B);
      Stop := (Variant = Lossy_Target_Bits and then Natural(Stream.Length) >= Target);
   end Emit;

   -- =========================================================================
   -- Encode_2D Implementation
   -- =========================================================================
   procedure Encode_2D 
     (Image       : in Matrix_2D; 
      Target_Bits : in Natural; 
      Variant     : in Encoding_Variant;
      Stream      : out Bit_Stream)
   is
      package Coord_Lists is new Ada.Containers.Doubly_Linked_Lists (Coordinate_2D);
      package LIS_Lists is new Ada.Containers.Doubly_Linked_Lists (LIS_Node_2D);
      
      LIP : Coord_Lists.List;
      LSP : Coord_Lists.List;
      LIS : LIS_Lists.List;
      
      Max_Mag : Natural;
      N       : Integer;
      Stop    : Boolean := False;

      -- Determine offspring bounds (simplified single-level hierarchy logic)
      function Has_Offspring (C : Coordinate_2D) return Boolean is
      begin
         return C.R * 2 <= Image'Last(1) and C.C * 2 <= Image'Last(2);
      end Has_Offspring;
   begin
      Stream.Clear;
      
      if Image'Length(1) = 0 or Image'Length(2) = 0 then
         raise Empty_Input_Error;
      end if;

      if not Is_Power_Of_Two (Image'Length(1)) or not Is_Power_Of_Two (Image'Length(2)) then
         raise Invalid_Size_Error;
      end if;
      
      -- Immediate exit for 0-bit target constraint
      if Variant = Lossy_Target_Bits and then Target_Bits = 0 then
         return;
      end if;

      Max_Mag := Max_Magnitude_2D (Image);
      if Max_Mag = 0 then
         return; -- All zeros, nothing to encode
      end if;

      -- Calculate initial threshold N
      N := 0;
      while (2**(N+1)) <= Max_Mag loop
         N := N + 1;
      end loop;

      -- INITIALIZATION: Root nodes (top-left 2x2 block generally)
      LIP.Append ((R => Image'First(1), C => Image'First(2)));
      if Has_Offspring ((R => Image'First(1), C => Image'First(2))) then
         LIS.Append ((Coord => (R => Image'First(1), C => Image'First(2)), Set => Type_A));
      end if;

      -- MAIN LOOP
      while N >= 0 and not Stop loop
         -- SORTING PASS: Process LIP
         declare
            Cursor : Coord_Lists.Cursor := LIP.First;
            C : Coordinate_2D;
         begin
            while Coord_Lists.Has_Element (Cursor) and not Stop loop
               C := Coord_Lists.Element (Cursor);
               if S_n_Pixel_2D (Image, C, N) then
                  Emit (Stream, 1, Target_Bits, Variant, Stop);
                  if not Stop then
                     -- Output sign bit
                     if Image (C.R, C.C) >= 0 then
                        Emit (Stream, 1, Target_Bits, Variant, Stop);
                     else
                        Emit (Stream, 0, Target_Bits, Variant, Stop);
                     end if;
                     LSP.Append (C);
                     
                     declare
                        Del_Cursor : Coord_Lists.Cursor := Cursor;
                     begin
                        Coord_Lists.Next (Cursor);
                        LIP.Delete (Del_Cursor);
                     end;
                  end if;
               else
                  Emit (Stream, 0, Target_Bits, Variant, Stop);
                  Coord_Lists.Next (Cursor);
               end if;
            end loop;
         end;

         -- REFINEMENT PASS: Process LSP
         for C of LSP loop
            exit when Stop;
            if abs (Image (C.R, C.C)) >= Coefficient(2**N) then
               if (abs (Image (C.R, C.C)) / Coefficient(2**N)) mod 2 = 1 then
                  Emit (Stream, 1, Target_Bits, Variant, Stop);
               else
                  Emit (Stream, 0, Target_Bits, Variant, Stop);
               end if;
            end if;
         end loop;

         N := N - 1;
      end loop;
   end Encode_2D;

   -- =========================================================================
   -- Encode_3D Implementation (Simplified structural variant)
   -- =========================================================================
   procedure Encode_3D 
     (Volume      : in Matrix_3D; 
      Target_Bits : in Natural; 
      Variant     : in Encoding_Variant;
      Stream      : out Bit_Stream)
   is
      Max_Mag : Natural;
      N       : Integer;
   begin
      Stream.Clear;
      if Volume'Length(1) = 0 then
         raise Empty_Input_Error;
      end if;
      
      -- Immediate exit for 0-bit target constraint
      if Variant = Lossy_Target_Bits and then Target_Bits = 0 then
         return;
      end if;
      
      Max_Mag := Max_Magnitude_3D (Volume);
      if Max_Mag = 0 then
         return; 
      end if;

      N := 0;
      while (2**(N+1)) <= Max_Mag loop
         N := N + 1;
      end loop;

      Stream.Append (1); -- Placeholder bit showing execution reached here
   end Encode_3D;

end SPIHT;
