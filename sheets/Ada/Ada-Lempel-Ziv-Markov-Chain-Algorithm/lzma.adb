-- lzma.adb
-- Body implementing the LZMA logic, state transitions, and dictionary encoding.

package body LZMA is

   -----------------------------------------------------------------------------
   -- Update_State: Implements the exact 12-state Markov transition matrix
   -- described in the LZMA specification for probability modeling.
   -----------------------------------------------------------------------------
   procedure Update_State (State : in out LZMA_State; Kind : Packet_Kind) is
   begin
      case Kind is
         when LIT =>
            if State < 4 then
               State := 0;
            elsif State < 10 then
               State := State - 3;
            else
               State := State - 6;
            end if;
         when MATCH =>
            if State < 7 then
               State := 7;
            else
               State := 10;
            end if;
         when LONGREP =>
            if State < 7 then
               State := 8;
            else
               State := 11;
            end if;
         when SHORTREP =>
            if State < 7 then
               State := 9;
            else
               State := 11;
            end if;
      end case;
   end Update_State;

   -----------------------------------------------------------------------------
   -- Compress: Evaluates input using a sliding window dictionary and emits
   -- LZMA Tokens (LIT, MATCH). Note: Range Encoding is abstracted to Tokens.
   -----------------------------------------------------------------------------
   function Compress (Input : String; Config : LZMA_Config) return Token_List is
      Result   : Token_List (Input'Length * 2); -- Worst-case sizing
      Pos      : Positive := Input'First;
      State    : LZMA_State := 0;
      
      Best_Len  : Natural;
      Best_Dist : Natural;
      
      Max_Match : constant Natural := 273; -- Max LZMA match length
   begin
      if Input'Length = 0 then
         return Result;
      end if;

      while Pos <= Input'Last loop
         Best_Len  := 0;
         Best_Dist := 0;
         
         -- Search backward in the dictionary window for the longest match
         declare
            Limit : constant Positive := 
              (if Pos - Config.Dict_Size > Input'First then Pos - Config.Dict_Size else Input'First);
         begin
            for I in Limit .. Pos - 1 loop
               declare
                  Curr_Len : Natural := 0;
               begin
                  while Curr_Len < Max_Match 
                        and then Pos + Curr_Len <= Input'Last 
                        and then Input (I + Curr_Len) = Input (Pos + Curr_Len) 
                  loop
                     Curr_Len := Curr_Len + 1;
                  end loop;
                  
                  if Curr_Len > Best_Len then
                     Best_Len  := Curr_Len;
                     Best_Dist := Pos - I;
                  end if;
               end;
            end loop;
         end;
         
         -- Decide whether to emit a Literal or a Match
         if Best_Len >= 2 then
            -- Match token emitted
            Result.Len := Result.Len + 1;
            Result.Data (Result.Len) := (Kind => MATCH, Literal => ASCII.NUL, Distance => Best_Dist, Length => Best_Len);
            Update_State (State, MATCH);
            Pos := Pos + Best_Len;
         else
            -- Literal token emitted
            Result.Len := Result.Len + 1;
            Result.Data (Result.Len) := (Kind => LIT, Literal => Input (Pos), Distance => 0, Length => 0);
            Update_State (State, LIT);
            Pos := Pos + 1;
         end if;
      end loop;
      
      return Result;
   end Compress;

   -----------------------------------------------------------------------------
   -- Decompress: Reconstructs the string using sliding dictionary states
   -----------------------------------------------------------------------------
   function Decompress (Tokens : Token_Array; Config : LZMA_Config) return String is
      Output : String (1 .. 10_000); -- Arbitrary buffer for demonstration
      Out_Pos : Natural := 0;
      State  : LZMA_State := 0;
   begin
      for I in Tokens'Range loop
         case Tokens (I).Kind is
            when LIT =>
               Out_Pos := Out_Pos + 1;
               Output (Out_Pos) := Tokens (I).Literal;
               Update_State (State, LIT);
               
            when MATCH | LONGREP | SHORTREP =>
               if Tokens (I).Distance = 0 or else Tokens (I).Distance > Out_Pos then
                  raise LZMA_Error with "Invalid dictionary distance in stream";
               end if;
               
               if Tokens (I).Length = 0 then
                  raise LZMA_Error with "Invalid match length in stream";
               end if;

               declare
                  Start_Copy : constant Natural := Out_Pos - Tokens (I).Distance + 1;
               begin
                  for J in 0 .. Tokens (I).Length - 1 loop
                     Out_Pos := Out_Pos + 1;
                     Output (Out_Pos) := Output (Start_Copy + J);
                  end loop;
               end;
               Update_State (State, Tokens (I).Kind);
         end case;
      end loop;
      
      return Output (1 .. Out_Pos);
   end Decompress;

end LZMA;
