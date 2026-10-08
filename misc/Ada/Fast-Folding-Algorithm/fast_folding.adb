package body Fast_Folding is

   procedure Constant_Period_Fold
     (Data   : in Signal_Array;
      Period : in Positive;
      Result : out Profile_Array)
   is
   begin
      -- Validate array dimensions
      if Result'Length /= Period then
         raise Invalid_Period_Error with "Result array length must match Period.";
      end if;

      -- Initialize result with zeros
      for I in Result'Range loop
         Result (I) := 0.0;
      end loop;

      -- Fold data over the static period
      for I in Data'Range loop
         declare
            -- Calculate correct index mapping regardless of array bounds
            Profile_Idx : Positive := ((I - Data'First) mod Period) + Result'First;
         begin
            Result (Profile_Idx) := Result (Profile_Idx) + Data (I);
         end;
      end loop;
   end Constant_Period_Fold;

   procedure Fast_Fold
     (Data         : in Signal_Array;
      Base_Period  : in Positive;
      Num_Segments : in Positive;
      Result       : out Profile_Matrix)
   is
      K    : Natural := 0;
      Temp : Positive := Num_Segments;
   begin
      -- Validate Matrix Bounds
      if Result'Length (1) /= Num_Segments or else Result'Length (2) /= Base_Period then
         raise Invalid_Period_Error with "Result matrix dimensions must match parameters.";
      end if;

      -- Validate Num_Segments is a power of 2
      while Temp > 1 loop
         if Temp mod 2 /= 0 then
            raise Invalid_Segments_Error with "Num_Segments must be a power of 2.";
         end if;
         Temp := Temp / 2;
         K := K + 1;
      end loop;

      declare
         -- Use 0-based index arrays internally for safe modular arithmetic
         type Internal_Matrix is array (0 .. Num_Segments - 1, 0 .. Base_Period - 1) of Signal_Value;
         Buf_In  : Internal_Matrix := (others => (others => 0.0));
         Buf_Out : Internal_Matrix := (others => (others => 0.0));
      begin
         -- Step 1: Initialize the first buffer, handling zero-padding for trailing gaps
         for Seg in 0 .. Num_Segments - 1 loop
            for Phase in 0 .. Base_Period - 1 loop
               declare
                  Data_Idx : Positive := Data'First + Seg * Base_Period + Phase;
               begin
                  if Data_Idx <= Data'Last then
                     Buf_In (Seg, Phase) := Data (Data_Idx);
                  else
                     Buf_In (Seg, Phase) := 0.0;
                  end if;
               end;
            end loop;
         end loop;

         -- Step 2: Logarithmic folding (The FFA Butterfly Logic)
         for Stage in 1 .. K loop
            declare
               Step : Positive := 2 ** (Stage - 1);
            begin
               for I in 0 .. Num_Segments - 1 loop
                  declare
                     Is_Top_Branch : Boolean := (I / Step) mod 2 = 0;
                     Peer_Idx      : Natural;
                     Shift         : Natural;
                  begin
                     if Is_Top_Branch then
                        Peer_Idx := I + Step;
                        Shift    := 0;
                     else
                        Peer_Idx := I - Step;
                        Shift    := (I mod Step) + 1;
                     end if;

                     -- Add the peer with the calculated recursive shift
                     for Phase in 0 .. Base_Period - 1 loop
                        declare
                           -- Convert to Integer to prevent Constraint_Error on negatives before mod
                           Shifted_Phase : Natural := Natural ((Integer (Phase) - Integer (Shift)) mod Integer (Base_Period));
                        begin
                           Buf_Out (I, Phase) := Buf_In (I, Phase) + Buf_In (Peer_Idx, Shifted_Phase);
                        end;
                     end loop;
                  end;
               end loop;
               -- Swap buffers for the next stage
               Buf_In := Buf_Out;
            end;
         end loop;

         -- Step 3: Copy processed buffer back to the strictly-typed Result matrix
         for Seg in 0 .. Num_Segments - 1 loop
            for Phase in 0 .. Base_Period - 1 loop
               Result (Result'First (1) + Seg, Result'First (2) + Phase) := Buf_In (Seg, Phase);
            end loop;
         end loop;
      end;
   end Fast_Fold;

end Fast_Folding;
