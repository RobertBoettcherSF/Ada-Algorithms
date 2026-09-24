package body BWT is

   type Index_Array is array (Positive range <>) of Positive;

   -- Helper Function: Compares two string rotations lexicographically
   function Compare_Rotations (I, J : Positive; S : String) return Boolean is
      Len : constant Natural := S'Length;
      Idx_I, Idx_J : Positive;
   begin
      for K in 0 .. Len - 1 loop
         Idx_I := S'First + ((I - 1 + K) mod Len);
         Idx_J := S'First + ((J - 1 + K) mod Len);
         if S(Idx_I) /= S(Idx_J) then
            return S(Idx_I) < S(Idx_J);
         end if;
      end loop;
      return False;
   end Compare_Rotations;

   -- Helper Procedure: QuickSort for Rotation Indices
   procedure Sort_Indices (Indices : in out Index_Array; S : String) is
      procedure Sort (Left, Right : Integer) is
         I : Integer := Left;
         J : Integer := Right;
         Pivot : constant Positive := Indices ((Left + Right) / 2);
         Temp : Positive;
      begin
         if Left >= Right then return; end if;
         loop
            while Compare_Rotations(Indices(I), Pivot, S) loop
               I := I + 1;
            end loop;
            while Compare_Rotations(Pivot, Indices(J), S) loop
               J := J - 1;
            end loop;
            exit when I > J;
            
            Temp := Indices(I);
            Indices(I) := Indices(J);
            Indices(J) := Temp;
            
            I := I + 1;
            J := J - 1;
         end loop;
         if Left < J then Sort (Left, J); end if;
         if I < Right then Sort (I, Right); end if;
      end Sort;
   begin
      if Indices'Length > 1 then
         Sort (Indices'First, Indices'Last);
      end if;
   end Sort_Indices;

   ----------------------------------------------------------------------------
   -- Variant 1: Index Transform
   ----------------------------------------------------------------------------
   function Transform (Input : String) return BWT_Result is
      N : constant Natural := Input'Length;
      Res : BWT_Result := (To_Unbounded_String(""), 0);
   begin
      if N = 0 then
         return Res;
      end if;

      declare
         Indices : Index_Array (1 .. N);
         L : String (1 .. N);
         Last_Char_Idx : Positive;
      begin
         -- Initialize starting indices
         for I in 1 .. N loop
            Indices(I) := I;
         end loop;

         -- Sort cyclic rotations lexicographically
         Sort_Indices(Indices, Input);

         -- Extract last column and locate primary index
         for I in 1 .. N loop
            if Indices(I) = 1 then
               Last_Char_Idx := N;
               Res.Primary_Index := Index_Type(I);
            else
               Last_Char_Idx := Indices(I) - 1;
            end if;
            L(I) := Input(Input'First + Last_Char_Idx - 1);
         end loop;

         Res.Transformed_String := To_Unbounded_String(L);
         return Res;
      end;
   end Transform;

   function Inverse_Transform (Input : String; Primary_Index : Index_Type) return String is
      N : constant Natural := Input'Length;
      Count : array (Character) of Natural := (others => 0);
      Rank  : array (1 .. N) of Natural;
      T     : array (1 .. N) of Positive;
      Curr  : Positive;
      Accum : Natural := 0;
      Cum_Count : array (Character) of Natural := (others => 0);
   begin
      if N = 0 then return ""; end if;
      if Positive(Primary_Index) > N or Primary_Index = 0 then
         raise Invalid_Input;
      end if;

      declare
         Res : String (1 .. N);
      begin
         -- Calculate occurrences (Ranks) for each character
         for I in 1 .. N loop
            Rank(I) := Count(Input(Input'First + I - 1));
            Count(Input(Input'First + I - 1)) := Count(Input(Input'First + I - 1)) + 1;
         end loop;

         -- Cumulative counts for sorted first column (LF Mapping requirement)
         for C in Character loop
            Cum_Count(C) := Accum;
            Accum := Accum + Count(C);
         end loop;

         -- Build the LF Mapping array 'T'
         for I in 1 .. N loop
            T(I) := Cum_Count(Input(Input'First + I - 1)) + Rank(I) + 1;
         end loop;

         -- Reconstruct string working backwards from the Primary Index
         Curr := Positive(Primary_Index);
         for I in reverse 1 .. N loop
            Res(Res'First + I - 1) := Input(Input'First + Curr - 1);
            Curr := T(Curr);
         end loop;

         return Res;
      end;
   end Inverse_Transform;

   ----------------------------------------------------------------------------
   -- Variant 2: Marker Transform
   ----------------------------------------------------------------------------
   function Transform_Marker (Input : String; Marker : Character := '$') return String is
   begin
      -- Validate marker does not exist in source text
      for I in Input'Range loop
         if Input(I) = Marker then
            raise Invalid_Marker;
         end if;
      end loop;

      declare
         Marked_Input : constant String := Input & Marker;
         Res : constant BWT_Result := Transform (Marked_Input);
      begin
         return To_String(Res.Transformed_String);
      end;
   end Transform_Marker;

   function Inverse_Transform_Marker (Input : String; Marker : Character := '$') return String is
      Marker_Pos : Integer := 0;
      N : constant Natural := Input'Length;
   begin
      if N = 0 then return ""; end if;
      
      -- Locate EOF marker and validate uniqueness
      for I in Input'Range loop
         if Input(I) = Marker then
            if Marker_Pos /= 0 then
               raise Invalid_Input; -- Multiple markers found
            end if;
            Marker_Pos := I - Input'First + 1;
         end if;
      end loop;

      if Marker_Pos = 0 then
         raise Marker_Not_Found;
      end if;
      
      if N = 1 then return ""; end if;

      declare
         Count : array (Character) of Natural := (others => 0);
         Rank  : array (1 .. N) of Natural;
         T     : array (1 .. N) of Positive;
         Res   : String (1 .. N - 1);
         Curr  : Positive;
         Accum : Natural := 0;
         Cum_Count : array (Character) of Natural := (others => 0);
      begin
         -- LF Mapping setup (same as index variant)
         for I in 1 .. N loop
            Rank(I) := Count(Input(Input'First + I - 1));
            Count(Input(Input'First + I - 1)) := Count(Input(Input'First + I - 1)) + 1;
         end loop;

         for C in Character loop
            Cum_Count(C) := Accum;
            Accum := Accum + Count(C);
         end loop;

         for I in 1 .. N loop
            T(I) := Cum_Count(Input(Input'First + I - 1)) + Rank(I) + 1;
         end loop;

         -- Reconstruct string backwards starting from Marker position
         Curr := Marker_Pos;
         for I in reverse 1 .. N loop
            if I < N then
               Res(Res'First + I - 1) := Input(Input'First + Curr - 1);
            end if;
            Curr := T(Curr);
         end loop;

         return Res;
      end;
   end Inverse_Transform_Marker;

end BWT;
