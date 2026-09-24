with Ada.Unchecked_Deallocation;

package body Entropy_Encoding is

   -- Helper: Generate Frequencies
   function Generate_Frequencies (Text : String) return Frequency_Map is
      Freqs : Frequency_Map := (others => 0);
   begin
      if Text'Length = 0 then
         raise Empty_Input_Error with "Input text cannot be empty.";
      end if;

      for I in Text'Range loop
         Freqs (Text (I)) := Freqs (Text (I)) + 1;
      end loop;
      return Freqs;
   end Generate_Frequencies;

   -- ========================================================================
   -- Huffman Coding Implementation
   -- ========================================================================
   type Node;
   type Node_Access is access Node;
   type Node is record
      Sym   : Character := ASCII.NUL;
      Freq  : Natural := 0;
      Left  : Node_Access := null;
      Right : Node_Access := null;
   end record;

   procedure Free is new Ada.Unchecked_Deallocation (Node, Node_Access);

   procedure Generate_Huffman_Codes (Freqs : in Frequency_Map; Codes : out Encoding_Map) is
      Pool : array (1 .. 256) of Node_Access;
      Pool_Size : Natural := 0;
      
      -- Find the two nodes with the lowest frequency
      procedure Find_Two_Mins (Min1, Min2 : out Natural) is
         Idx1, Idx2 : Natural := 0;
         Val1, Val2 : Natural := Natural'Last;
      begin
         for I in 1 .. Pool_Size loop
            if Pool (I) /= null then
               if Pool (I).Freq < Val1 then
                  Val2 := Val1;
                  Idx2 := Idx1;
                  Val1 := Pool (I).Freq;
                  Idx1 := I;
               elsif Pool (I).Freq < Val2 then
                  Val2 := Pool (I).Freq;
                  Idx2 := I;
               end if;
            end if;
         end loop;
         Min1 := Idx1;
         Min2 := Idx2;
      end Find_Two_Mins;

      -- Recursively extract codes from the tree
      procedure Extract_Codes (Root : Node_Access; Current_Code : String) is
      begin
         if Root = null then return; end if;

         if Root.Left = null and Root.Right = null then
            -- Single symbol edge case handling
            if Current_Code = "" then
               Codes (Root.Sym) := (To_Unbounded_String ("0"), 1);
            else
               Codes (Root.Sym) := (To_Unbounded_String (Current_Code), Current_Code'Length);
            end if;
         else
            Extract_Codes (Root.Left, Current_Code & "0");
            Extract_Codes (Root.Right, Current_Code & "1");
         end if;
      end Extract_Codes;
      
      Min1, Min2 : Natural;
      Root : Node_Access := null;
   begin
      -- Initialize Codes to empty
      for C in Character loop
         Codes (C) := (To_Unbounded_String (""), 0);
      end loop;

      -- Populate initial pool
      for C in Character loop
         if Freqs (C) > 0 then
            Pool_Size := Pool_Size + 1;
            Pool (Pool_Size) := new Node'(Sym => C, Freq => Freqs (C), Left => null, Right => null);
         end if;
      end loop;

      if Pool_Size = 0 then return; end if;

      -- Build Tree
      declare
         Active_Nodes : Natural := Pool_Size;
      begin
         while Active_Nodes > 1 loop
            Find_Two_Mins (Min1, Min2);
            declare
               Parent : Node_Access := new Node'(
                  Sym => ASCII.NUL,
                  Freq => Pool (Min1).Freq + Pool (Min2).Freq,
                  Left => Pool (Min1),
                  Right => Pool (Min2)
               );
            begin
               Pool (Min1) := Parent;
               Pool (Min2) := null;
               Active_Nodes := Active_Nodes - 1;
            end;
         end loop;
         
         -- Find Root
         for I in 1 .. Pool_Size loop
            if Pool (I) /= null then
               Root := Pool (I);
               exit;
            end if;
         end loop;
      end;

      Extract_Codes (Root, "");
      -- Clean up tree (simplified for brevity, a real system needs full tree traversal deallocation)
   end Generate_Huffman_Codes;

   -- ========================================================================
   -- Shannon-Fano Coding Implementation
   -- ========================================================================
   type Symbol_Freq is record
      Sym  : Character;
      Freq : Natural;
   end record;
   type SF_Array is array (Positive range <>) of Symbol_Freq;

   procedure Generate_Shannon_Fano_Codes (Freqs : in Frequency_Map; Codes : out Encoding_Map) is
      Arr : SF_Array (1 .. 256);
      Count : Natural := 0;

      -- Sort array descending based on frequency
      procedure Sort_Descending (A : in out SF_Array) is
         Temp : Symbol_Freq;
      begin
         for I in A'First .. A'Last - 1 loop
            for J in I + 1 .. A'Last loop
               if A (J).Freq > A (I).Freq then
                  Temp := A (I);
                  A (I) := A (J);
                  A (J) := Temp;
               end if;
            end loop;
         end loop;
      end Sort_Descending;

      -- Top-down recursive splitting
      procedure Split (L, R : Positive) is
         Sum_Total, Sum_Left, Best_Diff, Current_Diff : Natural;
         Split_Index : Positive := L;
      begin
         if L >= R then return; end if;
         if L + 1 = R then
            Codes (Arr (L).Sym).Bit_Code := Codes (Arr (L).Sym).Bit_Code & "0";
            Codes (Arr (R).Sym).Bit_Code := Codes (Arr (R).Sym).Bit_Code & "1";
            return;
         end if;

         Sum_Total := 0;
         for I in L .. R loop
            Sum_Total := Sum_Total + Arr (I).Freq;
         end loop;

         Sum_Left := 0;
         Best_Diff := Natural'Last;

         for I in L .. R - 1 loop
            Sum_Left := Sum_Left + Arr (I).Freq;
            Current_Diff := abs (Sum_Total - 2 * Sum_Left);
            if Current_Diff < Best_Diff then
               Best_Diff := Current_Diff;
               Split_Index := I;
            end if;
         end loop;

         for I in L .. Split_Index loop
            Codes (Arr (I).Sym).Bit_Code := Codes (Arr (I).Sym).Bit_Code & "0";
         end loop;
         for I in Split_Index + 1 .. R loop
            Codes (Arr (I).Sym).Bit_Code := Codes (Arr (I).Sym).Bit_Code & "1";
         end loop;

         Split (L, Split_Index);
         Split (Split_Index + 1, R);
      end Split;

   begin
      -- Init
      for C in Character loop
         Codes (C) := (To_Unbounded_String (""), 0);
      end loop;

      -- Collect non-zero
      for C in Character loop
         if Freqs (C) > 0 then
            Count := Count + 1;
            Arr (Count) := (Sym => C, Freq => Freqs (C));
         end if;
      end loop;

      if Count = 0 then return; end if;
      if Count = 1 then
         Codes (Arr (1).Sym) := (To_Unbounded_String ("0"), 1);
         return;
      end if;

      Sort_Descending (Arr (1 .. Count));
      Split (1, Count);
      
      -- Update lengths
      for I in 1 .. Count loop
         Codes (Arr (I).Sym).Length := Length (Codes (Arr (I).Sym).Bit_Code);
      end loop;
   end Generate_Shannon_Fano_Codes;

   -- ========================================================================
   -- Arithmetic Coding
   -- ========================================================================
   function Arithmetic_Encode (Text : String; Freqs : Frequency_Map) return Long_Float is
      Low, High, Range_Size : Long_Float;
      Total_Freq : Natural := 0;
      Cum_Prob : Long_Float := 0.0;
      
      type Prob_Range is record
         Low, High : Long_Float;
      end record;
      Probs : array (Character) of Prob_Range;
   begin
      if Text'Length = 0 then
         raise Empty_Input_Error;
      end if;

      for C in Character loop
         Total_Freq := Total_Freq + Freqs (C);
      end loop;

      for C in Character loop
         if Freqs (C) > 0 then
            Probs (C).Low := Cum_Prob;
            Cum_Prob := Cum_Prob + Long_Float (Freqs (C)) / Long_Float (Total_Freq);
            Probs (C).High := Cum_Prob;
         end if;
      end loop;

      Low := 0.0;
      High := 1.0;

      for I in Text'Range loop
         Range_Size := High - Low;
         -- Protect against underflow in this simple float variant
         if Range_Size < 0.0000000001 then
            raise Arithmetic_Overflow with "Text too long for floating point precision bounds.";
         end if;
         
         High := Low + Range_Size * Probs (Text (I)).High;
         Low  := Low + Range_Size * Probs (Text (I)).Low;
      end loop;

      return (Low + High) / 2.0;
   end Arithmetic_Encode;

   -- ========================================================================
   -- General Encode / Decode for Prefix Codes
   -- ========================================================================
   function Encode (Text : String; Codes : Encoding_Map) return String is
      Result : Unbounded_String := Null_Unbounded_String;
   begin
      if Text'Length = 0 then raise Empty_Input_Error; end if;
      for I in Text'Range loop
         if Codes (Text (I)).Length = 0 then
            raise Invalid_Encoding_Error with "Character missing in code map";
         end if;
         Append (Result, Codes (Text (I)).Bit_Code);
      end loop;
      return To_String (Result);
   end Encode;

   function Decode (Bitstream : String; Codes : Encoding_Map) return String is
      Result : Unbounded_String := Null_Unbounded_String;
      Current_Bit_Buffer : Unbounded_String := Null_Unbounded_String;
      Found : Boolean;
   begin
      if Bitstream'Length = 0 then raise Empty_Input_Error; end if;
      for I in Bitstream'Range loop
         if Bitstream (I) /= '0' and Bitstream (I) /= '1' then
            raise Invalid_Encoding_Error with "Bitstream contains non-binary values";
         end if;
         
         Append (Current_Bit_Buffer, Bitstream (I));
         Found := False;
         
         for C in Character loop
            if Codes (C).Length > 0 and then Codes (C).Bit_Code = Current_Bit_Buffer then
               Append (Result, C);
               Current_Bit_Buffer := Null_Unbounded_String;
               Found := True;
               exit;
            end if;
         end loop;
      end loop;
      
      if Length (Current_Bit_Buffer) > 0 then
         raise Invalid_Encoding_Error with "Bitstream ends abruptly without completing a symbol map";
      end if;

      return To_String (Result);
   end Decode;

end Entropy_Encoding;
