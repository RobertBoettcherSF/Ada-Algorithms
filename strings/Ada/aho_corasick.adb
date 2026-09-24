--  Aho_Corasick body — trie + failure links + output links (BFS).
--  After Aho & Corasick (1975); see also the Wikipedia construction with
--  black child arcs, blue suffix arcs, and green dictionary-suffix arcs.

pragma Ada_2022;

package body Aho_Corasick is

   function Ord (C : Character) return Alphabet_Index is
   begin
      return Character'Pos (C);
   end Ord;

   function Patterns (P1 : String) return Pattern_Array is
   begin
      return [To_Unbounded_String (P1)];
   end Patterns;

   function Patterns (P1, P2 : String) return Pattern_Array is
   begin
      return [To_Unbounded_String (P1), To_Unbounded_String (P2)];
   end Patterns;

   function Patterns (P1, P2, P3 : String) return Pattern_Array is
   begin
      return
        [To_Unbounded_String (P1),
         To_Unbounded_String (P2),
         To_Unbounded_String (P3)];
   end Patterns;

   function Patterns (P1, P2, P3, P4 : String) return Pattern_Array is
   begin
      return
        [To_Unbounded_String (P1),
         To_Unbounded_String (P2),
         To_Unbounded_String (P3),
         To_Unbounded_String (P4)];
   end Patterns;

   function Patterns (P1, P2, P3, P4, P5 : String) return Pattern_Array is
   begin
      return
        [To_Unbounded_String (P1),
         To_Unbounded_String (P2),
         To_Unbounded_String (P3),
         To_Unbounded_String (P4),
         To_Unbounded_String (P5)];
   end Patterns;

   function Patterns
     (P1, P2, P3, P4, P5, P6 : String) return Pattern_Array
   is
   begin
      return
        [To_Unbounded_String (P1),
         To_Unbounded_String (P2),
         To_Unbounded_String (P3),
         To_Unbounded_String (P4),
         To_Unbounded_String (P5),
         To_Unbounded_String (P6)];
   end Patterns;

   function Patterns
     (P1, P2, P3, P4, P5, P6, P7 : String) return Pattern_Array
   is
   begin
      return
        [To_Unbounded_String (P1),
         To_Unbounded_String (P2),
         To_Unbounded_String (P3),
         To_Unbounded_String (P4),
         To_Unbounded_String (P5),
         To_Unbounded_String (P6),
         To_Unbounded_String (P7)];
   end Patterns;

   procedure Check_Patterns (Patterns : Pattern_Array) is
   begin
      if Patterns'Length = 0 then
         raise Invalid_Argument with "empty pattern list";
      end if;
      if Patterns'Length > Max_Patterns then
         raise Invalid_Argument with "too many patterns";
      end if;
      for I in Patterns'Range loop
         if Length (Patterns (I)) = 0 then
            raise Invalid_Argument with "empty pattern";
         end if;
         if Length (Patterns (I)) > Max_Pattern_Len then
            raise Invalid_Argument with "pattern too long";
         end if;
      end loop;
   end Check_Patterns;

   procedure Add_Output
     (A           : in out Automaton;
      Node        : Node_Id;
      Pattern_Idx : Positive)
   is
      Slot : Natural;
   begin
      A.Output_Slots := A.Output_Slots + 1;
      Slot := A.Output_Slots;
      A.Output_Pat (Slot) := Pattern_Idx;
      A.Output_Next (Slot) := A.Output_Head (Node);
      A.Output_Head (Node) := Slot;
   end Add_Output;

   function New_Node (A : in out Automaton) return Node_Id is
   begin
      if A.Nodes = Max_Nodes then
         raise Invalid_Argument with "too many trie nodes";
      end if;
      A.Nodes := A.Nodes + 1;
      return A.Nodes;
   end New_Node;

   ---------------------------------------------------------------------------
   -- Build
   ---------------------------------------------------------------------------

   function Build (Patterns : Pattern_Array) return Automaton is
      A : Automaton;
   begin
      Check_Patterns (Patterns);

      A.Patterns := Patterns'Length;

      for P in Patterns'Range loop
         declare
            Pat   : constant String := To_String (Patterns (P));
            Idx   : constant Positive := P - Patterns'First + 1;
            State : Node_Id := 1;
            C     : Alphabet_Index;
            Next  : Node_Id;
         begin
            A.Lengths (Idx) := Pat'Length;
            for K in Pat'Range loop
               C := Ord (Pat (K));
               Next := A.Goto_Table (State) (C);
               if Next = 0 then
                  Next := New_Node (A);
                  A.Goto_Table (State) (C) := Next;
               end if;
               State := Next;
            end loop;
            Add_Output (A, State, Idx);
         end;
      end loop;

      declare
         type Queue_Array is array (1 .. Max_Nodes) of Node_Id;
         Q    : Queue_Array;
         Head : Natural := 1;
         Tail : Natural := 0;

         procedure Enqueue (N : Node_Id) is
         begin
            Tail := Tail + 1;
            Q (Tail) := N;
         end Enqueue;

         function Dequeue return Node_Id is
            N : constant Node_Id := Q (Head);
         begin
            Head := Head + 1;
            return N;
         end Dequeue;

         function Empty return Boolean is
         begin
            return Head > Tail;
         end Empty;

         U, V, F : Node_Id;
      begin
         A.Fail (1) := 1;
         A.Out_Link (1) := 0;

         for C in Alphabet_Index loop
            V := A.Goto_Table (1) (C);
            if V /= 0 then
               A.Fail (V) := 1;
               A.Out_Link (V) := 0;
               Enqueue (V);
            end if;
         end loop;

         while not Empty loop
            U := Dequeue;
            for C in Alphabet_Index loop
               V := A.Goto_Table (U) (C);
               if V /= 0 then
                  F := A.Fail (U);
                  while F /= 1 and then A.Goto_Table (F) (C) = 0 loop
                     F := A.Fail (F);
                  end loop;
                  if A.Goto_Table (F) (C) /= 0 then
                     A.Fail (V) := A.Goto_Table (F) (C);
                  else
                     A.Fail (V) := 1;
                  end if;

                  if A.Output_Head (A.Fail (V)) /= 0 then
                     A.Out_Link (V) := A.Fail (V);
                  else
                     A.Out_Link (V) := A.Out_Link (A.Fail (V));
                  end if;

                  Enqueue (V);
               end if;
            end loop;
         end loop;
      end;

      return A;
   end Build;

   function Pattern_Count (A : Automaton) return Natural is
   begin
      return A.Patterns;
   end Pattern_Count;

   function Node_Count (A : Automaton) return Positive is
   begin
      return Positive (A.Nodes);
   end Node_Count;

   function Pattern_Length (A : Automaton; Index : Positive) return Positive is
   begin
      if Index > A.Patterns then
         raise Invalid_Argument with "pattern index out of range";
      end if;
      return Positive (A.Lengths (Index));
   end Pattern_Length;

   ---------------------------------------------------------------------------
   -- Emit / sort helpers
   ---------------------------------------------------------------------------

   type Match_Buffer is array (1 .. Max_Matches) of Match;

   procedure Emit_At
     (A       : Automaton;
      State   : Node_Id;
      End_Pos : Positive;
      Buf     : in out Match_Buffer;
      Count   : in out Natural)
   is
      procedure Emit_Node (N : Node_Id) is
         Slot  : Natural := A.Output_Head (N);
         Pat   : Positive;
         Len   : Positive;
         Start : Positive;
      begin
         while Slot /= 0 loop
            Pat := A.Output_Pat (Slot);
            Len := Positive (A.Lengths (Pat));
            if End_Pos >= Len then
               Start := End_Pos - Len + 1;
               if Count >= Max_Matches then
                  raise Invalid_Argument with "too many matches";
               end if;
               Count := Count + 1;
               Buf (Count) :=
                 (Pattern_Index  => Pat,
                  Start_Position => Start,
                  End_Position   => End_Pos);
            end if;
            Slot := A.Output_Next (Slot);
         end loop;
      end Emit_Node;

      N : Node_Id := State;
   begin
      Emit_Node (N);
      N := A.Out_Link (N);
      while N /= 0 loop
         Emit_Node (N);
         N := A.Out_Link (N);
      end loop;
   end Emit_At;

   procedure Sort_Matches (Buf : in out Match_Buffer; Count : Natural) is
      Tmp : Match;
      J   : Natural;
   begin
      for I in 2 .. Count loop
         Tmp := Buf (I);
         J := I - 1;
         while J >= 1
           and then
             (Buf (J).End_Position > Tmp.End_Position
              or else
                (Buf (J).End_Position = Tmp.End_Position
                 and then Buf (J).Pattern_Index > Tmp.Pattern_Index))
         loop
            Buf (J + 1) := Buf (J);
            J := J - 1;
         end loop;
         Buf (J + 1) := Tmp;
      end loop;
   end Sort_Matches;

   function Copy_Matches
     (Buf   : Match_Buffer;
      Count : Natural) return Match_List
   is
   begin
      if Count = 0 then
         return Match_List'(1 .. 0 => <>);
      end if;
      declare
         Result : Match_List (1 .. Count);
      begin
         for I in 1 .. Count loop
            Result (I) := Buf (I);
         end loop;
         return Result;
      end;
   end Copy_Matches;

   ---------------------------------------------------------------------------
   -- Search
   ---------------------------------------------------------------------------

   function Search (A : Automaton; Text : String) return Match_List is
      Buf   : Match_Buffer;
      Count : Natural := 0;
      State : Node_Id := 1;
      C     : Alphabet_Index;
      Next  : Node_Id;
      Pos   : Positive;
   begin
      if Text'Length > Max_Text_Length then
         raise Invalid_Argument with "text too long";
      end if;
      if Text'Length = 0 then
         return Match_List'(1 .. 0 => <>);
      end if;

      for K in Text'Range loop
         C := Ord (Text (K));
         while State /= 1 and then A.Goto_Table (State) (C) = 0 loop
            State := A.Fail (State);
         end loop;
         Next := A.Goto_Table (State) (C);
         if Next /= 0 then
            State := Next;
         else
            State := 1;
         end if;

         Pos := K - Text'First + 1;
         if A.Output_Head (State) /= 0 or else A.Out_Link (State) /= 0 then
            Emit_At (A, State, Pos, Buf, Count);
         end if;
      end loop;

      Sort_Matches (Buf, Count);
      return Copy_Matches (Buf, Count);
   end Search;

   ---------------------------------------------------------------------------
   -- Naive oracle
   ---------------------------------------------------------------------------

   function Naive_Search
     (Patterns : Pattern_Array;
      Text     : String) return Match_List
   is
      Buf   : Match_Buffer;
      Count : Natural := 0;
   begin
      Check_Patterns (Patterns);
      if Text'Length > Max_Text_Length then
         raise Invalid_Argument with "text too long";
      end if;

      for P in Patterns'Range loop
         declare
            Pat : constant String := To_String (Patterns (P));
            Idx : constant Positive := P - Patterns'First + 1;
            M   : constant Positive := Pat'Length;
         begin
            if Text'Length >= M then
               for Start in 0 .. Text'Length - M loop
                  declare
                     Ok : Boolean := True;
                  begin
                     for J in 0 .. M - 1 loop
                        if Text (Text'First + Start + J) /=
                          Pat (Pat'First + J)
                        then
                           Ok := False;
                           exit;
                        end if;
                     end loop;
                     if Ok then
                        if Count >= Max_Matches then
                           raise Invalid_Argument with "too many matches";
                        end if;
                        Count := Count + 1;
                        Buf (Count) :=
                          (Pattern_Index  => Idx,
                           Start_Position => Start + 1,
                           End_Position   => Start + M);
                     end if;
                  end;
               end loop;
            end if;
         end;
      end loop;

      Sort_Matches (Buf, Count);
      return Copy_Matches (Buf, Count);
   end Naive_Search;

end Aho_Corasick;
