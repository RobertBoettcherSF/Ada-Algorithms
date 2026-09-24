-- lzx_algorithm.adb
-- Implementation of the LZX Compression engine

package body LZX_Algorithm is

   -- Helper: Minimum of two Naturals
   function Min (A, B : Natural) return Natural is
   begin
      if A < B then return A; else return B; end if;
   end Min;

   -------------------------------------------------------------------------
   -- Create_Config
   -- Validates and constructs the configuration based on Variant rules
   -------------------------------------------------------------------------
   function Create_Config (Variant : LZX_Variant; Window : Natural) return LZX_Configuration is
      Result : LZX_Configuration;
   begin
      Result.Variant := Variant;
      Result.Max_Match_Len := 256; -- Standard maximum match length for LZX
      
      case Variant is
         when Xbox_LZX =>
            -- Xbox variant forces exactly 32KB window
            Result.Window_Size := 32768; 
         when CAB_LZX | CHM_LZX =>
            -- CAB/CHM typically powers of 2 up to 2MB. We clamp for safety.
            if Window > 2_097_152 then
               Result.Window_Size := 2_097_152;
            else
               Result.Window_Size := Window;
            end if;
         when others =>
            Result.Window_Size := Window;
      end case;
      
      return Result;
   end Create_Config;

   -------------------------------------------------------------------------
   -- Compress
   -- Performs LZ77 sliding window matching with LZX R0, R1, R2 offset queues
   -------------------------------------------------------------------------
   procedure Compress (
      Config     : in  LZX_Configuration;
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   ) is
      Cursor : Natural := Input'First;
      Out_Idx : Natural := Output'First;
      
      -- LZX Repeated Offset Queues (initialized to 1 per spec)
      R0, R1, R2 : Natural := 1;
      
      Best_Len    : Natural;
      Best_Offset : Natural;
      Match_Len   : Natural;
      Max_Look    : Natural;
      Max_Search  : Natural;
      Search_Base : Natural;
   begin
      Output_Len := 0;
      if Input'Length = 0 then
         return;
      end if;

      while Cursor <= Input'Last loop
         Best_Len := 0;
         Best_Offset := 0;
         
         Max_Look := Min(Config.Max_Match_Len, Input'Last - Cursor + 1);
         Max_Search := Min(Cursor - Input'First, Config.Window_Size);
         
         -- Search for the longest match in the sliding window
         if Max_Search > 0 and Max_Look >= 2 then
            Search_Base := Cursor - Max_Search;
            for I in Search_Base .. Cursor - 1 loop
               Match_Len := 0;
               while Match_Len < Max_Look and then 
                     Input(I + Match_Len) = Input(Cursor + Match_Len) loop
                  Match_Len := Match_Len + 1;
               end loop;
               
               if Match_Len > Best_Len and Match_Len >= 2 then
                  Best_Len := Match_Len;
                  Best_Offset := Cursor - I;
               end if;
            end loop;
         end if;
         
         -- Ensure output buffer is large enough
         if Out_Idx + 5 > Output'Last then
            raise Buffer_Overflow;
         end if;

         -- LZX Output Serialization Strategy
         if Best_Len < 2 then
            -- Token: Literal (0x00)
            Output(Out_Idx) := 0;
            Output(Out_Idx + 1) := Input(Cursor);
            Out_Idx := Out_Idx + 2;
            Cursor := Cursor + 1;
         else
            -- Token: Match. Check Repeated Offsets (R0, R1, R2)
            if Best_Offset = R0 then
               -- R0 Match (0x02)
               Output(Out_Idx) := 2;
               Output(Out_Idx + 1) := Byte(Best_Len mod 256);
               Out_Idx := Out_Idx + 2;
            elsif Best_Offset = R1 then
               -- R1 Match (0x03)
               Output(Out_Idx) := 3;
               Output(Out_Idx + 1) := Byte(Best_Len mod 256);
               Out_Idx := Out_Idx + 2;
               -- LZX R1 swap rule: R1 becomes R0, old R0 becomes R1
               R1 := R0;
               R0 := Best_Offset;
            elsif Best_Offset = R2 then
               -- R2 Match (0x04)
               Output(Out_Idx) := 4;
               Output(Out_Idx + 1) := Byte(Best_Len mod 256);
               Out_Idx := Out_Idx + 2;
               -- LZX R2 swap rule: R2->R1, R1->R0, old R0->R2 (R0 is new)
               R2 := R1;
               R1 := R0;
               R0 := Best_Offset;
            else
               -- Standard Match (0x01)
               Output(Out_Idx) := 1;
               Output(Out_Idx + 1) := Byte((Best_Offset / 256) mod 256);
               Output(Out_Idx + 2) := Byte(Best_Offset mod 256);
               Output(Out_Idx + 3) := Byte(Best_Len mod 256);
               Out_Idx := Out_Idx + 4;
               
               -- Update R-Queues for standard match
               R2 := R1;
               R1 := R0;
               R0 := Best_Offset;
            end if;
            
            Cursor := Cursor + Best_Len;
         end if;
      end loop;
      
      Output_Len := Out_Idx - Output'First;
   end Compress;

   -------------------------------------------------------------------------
   -- Decompress
   -- Rebuilds data using Literal / Match tokens and maintains LZX R-Queues
   -------------------------------------------------------------------------
   procedure Decompress (
      Config     : in  LZX_Configuration;
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   ) is
      In_Idx  : Natural := Input'First;
      Out_Idx : Natural := Output'First;
      
      R0, R1, R2 : Natural := 1;
      Token      : Byte;
      Offset     : Natural;
      Length     : Natural;
      Temp       : Natural;
   begin
      Output_Len := 0;
      if Input'Length = 0 then
         return;
      end if;

      while In_Idx <= Input'Last loop
         Token := Input(In_Idx);
         In_Idx := In_Idx + 1;
         
         case Token is
            when 0 => -- Literal
               if In_Idx > Input'Last or Out_Idx > Output'Last then raise LZX_Error; end if;
               Output(Out_Idx) := Input(In_Idx);
               Out_Idx := Out_Idx + 1;
               In_Idx := In_Idx + 1;
               
            when 1 => -- Standard Match
               if In_Idx + 2 > Input'Last then raise LZX_Error; end if;
               Offset := Natural(Input(In_Idx)) * 256 + Natural(Input(In_Idx + 1));
               Length := Natural(Input(In_Idx + 2));
               In_Idx := In_Idx + 3;
               
               if Out_Idx + Length - 1 > Output'Last or else Offset > Out_Idx - Output'First then
                  raise LZX_Error;
               end if;
               
               -- R-Queue Update
               R2 := R1; R1 := R0; R0 := Offset;
               
               -- Copy data
               for I in 1 .. Length loop
                  Output(Out_Idx) := Output(Out_Idx - Offset);
                  Out_Idx := Out_Idx + 1;
               end loop;
               
            when 2 => -- R0 Match
               if In_Idx > Input'Last then raise LZX_Error; end if;
               Length := Natural(Input(In_Idx));
               In_Idx := In_Idx + 1;
               Offset := R0;
               -- R queues unchanged for R0 match
               for I in 1 .. Length loop
                  Output(Out_Idx) := Output(Out_Idx - Offset);
                  Out_Idx := Out_Idx + 1;
               end loop;
               
            when 3 => -- R1 Match
               if In_Idx > Input'Last then raise LZX_Error; end if;
               Length := Natural(Input(In_Idx));
               In_Idx := In_Idx + 1;
               Offset := R1;
               
               -- R-Queue Update
               R1 := R0; R0 := Offset;
               
               for I in 1 .. Length loop
                  Output(Out_Idx) := Output(Out_Idx - Offset);
                  Out_Idx := Out_Idx + 1;
               end loop;

            when 4 => -- R2 Match
               if In_Idx > Input'Last then raise LZX_Error; end if;
               Length := Natural(Input(In_Idx));
               In_Idx := In_Idx + 1;
               Offset := R2;
               
               -- R-Queue Update
               Temp := R2; R2 := R1; R1 := R0; R0 := Temp;
               
               for I in 1 .. Length loop
                  Output(Out_Idx) := Output(Out_Idx - Offset);
                  Out_Idx := Out_Idx + 1;
               end loop;
               
            when others =>
               raise LZX_Error;
         end case;
      end loop;
      
      Output_Len := Out_Idx - Output'First;
   end Decompress;

end LZX_Algorithm;
