--  Entropy_Encoding body: Shannon-Fano (top-down) and Huffman (bottom-up) prefix codes.
--  The upstream folder shipped a copy of the spec as the body; this body implements the spec
--  without access types (at most 256 symbols, so a Huffman tree has at most 511 nodes).
package body Entropy_Encoding is

   subtype Symbol_Count is Natural range 0 .. 256;
   type Symbol_List is array (Positive range <>) of Character;

   function Calculate_Frequencies (Text : String) return Frequency_Map is
      F : Frequency_Map := (others => 0);
   begin
      if Text'Length = 0 then
         raise Empty_Input_Error with "empty input";
      end if;
      for C of Text loop
         F (C) := F (C) + 1;
      end loop;
      return F;
   end Calculate_Frequencies;

   --  Symbols with a non-zero frequency, by decreasing frequency (ties: character order).
   function Present (Freqs : Frequency_Map) return Symbol_List is
      L : Symbol_List (1 .. 256);
      N : Symbol_Count := 0;
   begin
      for C in Character loop
         if Freqs (C) > 0 then
            N := N + 1;
            L (N) := C;
            for I in reverse 2 .. N loop        --  insertion sort, stable
               exit when Freqs (L (I - 1)) >= Freqs (L (I));
               declare
                  T : constant Character := L (I);
               begin
                  L (I) := L (I - 1);
                  L (I - 1) := T;
               end;
            end loop;
         end if;
      end loop;
      if N = 0 then
         raise Empty_Input_Error with "no symbol has a non-zero frequency";
      end if;
      return L (1 .. N);
   end Present;

   function Generate_Shannon_Fano (Freqs : Frequency_Map) return Dictionary is
      Syms : constant Symbol_List := Present (Freqs);
      D    : Dictionary;

      --  Assign Prefix & "0"/"1" to the two halves of Syms (Lo .. Hi), split where the
      --  difference between the two frequency sums is smallest (first such point).
      procedure Split (Lo, Hi : Positive; Prefix : Unbounded_String) is
         Total, Left : Long_Long_Integer := 0;
         Best_Diff   : Long_Long_Integer := Long_Long_Integer'Last;
         Cut         : Positive := Lo;
      begin
         if Lo = Hi then
            D (Syms (Lo)) := (Is_Valid => True, Code => Prefix);
            return;
         end if;
         for I in Lo .. Hi loop
            Total := Total + Long_Long_Integer (Freqs (Syms (I)));
         end loop;
         for I in Lo .. Hi - 1 loop
            Left := Left + Long_Long_Integer (Freqs (Syms (I)));
            if abs (Total - 2 * Left) < Best_Diff then
               Best_Diff := abs (Total - 2 * Left);
               Cut := I;
            end if;
         end loop;
         Split (Lo, Cut, Prefix & "0");
         Split (Cut + 1, Hi, Prefix & "1");
      end Split;
   begin
      if Syms'Length = 1 then
         D (Syms (1)) := (Is_Valid => True, Code => To_Unbounded_String ("0"));
      else
         Split (Syms'First, Syms'Last, Null_Unbounded_String);
      end if;
      return D;
   end Generate_Shannon_Fano;

   function Generate_Huffman (Freqs : Frequency_Map) return Dictionary is
      Syms : constant Symbol_List := Present (Freqs);
      Max  : constant Positive := 2 * Syms'Length - 1;
      type Node is record
         Weight      : Long_Long_Integer := 0;
         Left, Right : Natural := 0;            --  0 for a leaf
         Sym         : Character := ' ';
         Used        : Boolean := False;        --  already merged into a parent
      end record;
      Nodes : array (1 .. Max) of Node;
      Count : Natural := Syms'Length;
      D     : Dictionary;

      --  Unused node of least weight (ties: lowest index, so leaves before merged nodes).
      function Take_Min return Positive is
         Best : Natural := 0;
      begin
         for I in 1 .. Count loop
            if not Nodes (I).Used and then (Best = 0 or else Nodes (I).Weight < Nodes (Best).Weight) then
               Best := I;
            end if;
         end loop;
         Nodes (Best).Used := True;
         return Best;
      end Take_Min;

      procedure Assign (N : Positive; Prefix : Unbounded_String) is
      begin
         if Nodes (N).Left = 0 then
            D (Nodes (N).Sym) := (Is_Valid => True, Code => Prefix);
         else
            Assign (Nodes (N).Left, Prefix & "0");
            Assign (Nodes (N).Right, Prefix & "1");
         end if;
      end Assign;
   begin
      if Syms'Length = 1 then
         D (Syms (1)) := (Is_Valid => True, Code => To_Unbounded_String ("0"));
         return D;
      end if;
      for I in Syms'Range loop
         Nodes (I) := (Weight => Long_Long_Integer (Freqs (Syms (I))), Left => 0, Right => 0,
                       Sym => Syms (I), Used => False);
      end loop;
      while Count < Max loop
         declare
            A : constant Positive := Take_Min;
            B : constant Positive := Take_Min;
         begin
            Count := Count + 1;
            Nodes (Count) := (Weight => Nodes (A).Weight + Nodes (B).Weight, Left => A, Right => B,
                              Sym => ' ', Used => False);
         end;
      end loop;
      Assign (Max, Null_Unbounded_String);
      return D;
   end Generate_Huffman;

   function Encode (Text : String; Dict : Dictionary) return String is
      R : Unbounded_String;
   begin
      for C of Text loop
         if not Dict (C).Is_Valid then
            raise Invalid_Data_Error with "symbol " & Character'Image (C) & " is not in the dictionary";
         end if;
         Append (R, Dict (C).Code);
      end loop;
      return To_String (R);
   end Encode;

end Entropy_Encoding;
