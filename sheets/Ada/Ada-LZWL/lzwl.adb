-- lzwl.adb
with Ada.Containers.Indefinite_Ordered_Maps;
with Ada.Containers.Indefinite_Vectors;
with Ada.Containers.Indefinite_Holders;

package body LZWL is

   -- A phrase is a sequence of syllables. Used as the Dictionary Key.
   type Phrase is array (Positive range <>) of Unbounded_String;
   
   -- Less-than operator to allow usage in Ordered_Maps
   function "<" (L, R : Phrase) return Boolean is
   begin
      for I in 0 .. Natural'Min(L'Length, R'Length) - 1 loop
         if L(L'First + I) < R(R'First + I) then
            return True;
         elsif L(L'First + I) > R(R'First + I) then
            return False;
         end if;
      end loop;
      return L'Length < R'Length;
   end "<";
   
   package Phrase_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type     => Phrase,
      Element_Type => Code);
      
   package Code_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type   => Natural,
      Element_Type => Phrase);

   package Phrase_Holders is new Ada.Containers.Indefinite_Holders (Element_Type => Phrase);
   
   Empty_Phrase : constant Phrase(1..0) := (others => Null_Unbounded_String);

   -- =========================================================================
   -- Shared Helper: Initializes the dictionaries with alphabet baseline
   -- =========================================================================
   procedure Init_Dict (
      Alphabet  : in Syllable_Array;
      Dict_P2C  : out Phrase_Maps.Map;
      Dict_C2P  : out Code_Vectors.Vector;
      Next_Code : out Code) 
   is
      Empty_P : constant Phrase(1..1) := (1 => Null_Unbounded_String);
   begin
      Dict_P2C.Clear;
      Dict_C2P.Clear;
      
      -- Code_Vectors index aligns dynamically with appended order
      Dict_C2P.Append(Empty_P); -- Dummy insert for Index 0
      
      Next_Code := 1;
      
      -- Per LZWL spec: Initialize with Empty Syllable
      Dict_P2C.Insert(Empty_P, Next_Code);
      Dict_C2P.Append(Empty_P);
      Next_Code := Next_Code + 1;
      
      -- Initialize explicit Alphabet
      for I in Alphabet'Range loop
         declare
            P : constant Phrase(1..1) := (1 => Alphabet(I));
         begin
            if not Dict_P2C.Contains(P) then
               Dict_P2C.Insert(P, Next_Code);
               Dict_C2P.Append(P);
               Next_Code := Next_Code + 1;
            end if;
         end;
      end loop;
   end Init_Dict;

   procedure Init_Dict_Expanded (
      Alphabet  : in Syllable_Array;
      Dict_P2C  : out Phrase_Maps.Map;
      Dict_C2P  : out Code_Vectors.Vector;
      Next_Code : out Code) 
   is
   begin
      Init_Dict(Alphabet, Dict_P2C, Dict_C2P, Next_Code);
      
      -- Expansion variant: Pre-populate all 2-syllable combinations.
      -- This significantly boosts initial compression ratio on dense payloads
      -- and elegantly eliminates mathematical irreversibility issues.
      for I in Alphabet'Range loop
         for J in Alphabet'Range loop
            declare
               P : constant Phrase(1..2) := (1 => Alphabet(I), 2 => Alphabet(J));
            begin
               if not Dict_P2C.Contains(P) then
                  Dict_P2C.Insert(P, Next_Code);
                  Dict_C2P.Append(P);
                  Next_Code := Next_Code + 1;
               end if;
            end;
         end loop;
      end loop;
   end Init_Dict_Expanded;

   -- =========================================================================
   -- Basic Syllable-Based Adaptation Implementations
   -- =========================================================================
   procedure Encode_Basic (
      Alphabet   : in Syllable_Array;
      Input      : in Syllable_Array;
      Output     : out Code_Array;
      Output_Len : out Natural)
   is
      Dict_P2C   : Phrase_Maps.Map;
      Dict_C2P   : Code_Vectors.Vector;
      Next_Code  : Code;
      S          : Phrase_Holders.Holder := Phrase_Holders.To_Holder(Empty_Phrase);
      Out_Offset : Natural := 0;
   begin
      Output_Len := 0;
      if Input'Length = 0 then return; end if;
      
      Init_Dict(Alphabet, Dict_P2C, Dict_C2P, Next_Code);
      
      for I in Input'Range loop
         declare
            C : constant Phrase(1..1) := (1 => Input(I));
         begin
            if not Dict_P2C.Contains(C) then
               raise LZWL_Error with "Syllable not in alphabet: " & To_String(Input(I));
            end if;
            
            declare
               Current_S : constant Phrase := S.Element;
               Combined  : constant Phrase := Current_S & C;
            begin
               if Dict_P2C.Contains(Combined) then
                  S.Replace_Element(Combined);
               else
                  if Out_Offset >= Output'Length then
                     raise LZWL_Error with "Output buffer overflow";
                  end if;
                  Output(Output'First + Out_Offset) := Dict_P2C.Element(Current_S);
                  Out_Offset := Out_Offset + 1;
                  
                  Dict_P2C.Insert(Combined, Next_Code);
                  Dict_C2P.Append(Combined);
                  Next_Code := Next_Code + 1;
                  
                  S.Replace_Element(C);
               end if;
            end;
         end;
      end loop;
      
      if S.Element'Length > 0 then
         if Out_Offset >= Output'Length then
            raise LZWL_Error with "Output buffer overflow";
         end if;
         Output(Output'First + Out_Offset) := Dict_P2C.Element(S.Element);
         Out_Offset := Out_Offset + 1;
      end if;
      
      Output_Len := Out_Offset;
   end Encode_Basic;

   procedure Decode_Basic (
      Alphabet   : in Syllable_Array;
      Input      : in Code_Array;
      Output     : out Syllable_Array;
      Output_Len : out Natural)
   is
      Dict_P2C   : Phrase_Maps.Map;
      Dict_C2P   : Code_Vectors.Vector;
      Next_Code  : Code;
      Prev_S     : Phrase_Holders.Holder := Phrase_Holders.To_Holder(Empty_Phrase);
      S1         : Phrase_Holders.Holder := Phrase_Holders.To_Holder(Empty_Phrase);
      Out_Offset : Natural := 0;
   begin
      Output_Len := 0;
      if Input'Length = 0 then return; end if;
      
      Init_Dict(Alphabet, Dict_P2C, Dict_C2P, Next_Code);
      
      for I in Input'Range loop
         declare
            K : constant Code := Input(I);
         begin
            if I = Input'First then
               if Natural(K) >= Natural(Next_Code) then
                  raise LZWL_Error with "Invalid data: Bad initial code";
               end if;
               S1.Replace_Element(Dict_C2P.Element(Natural(K)));
            else
               if Natural(K) >= Natural(Next_Code) then
                  declare
                     Prev_Phrase    : constant Phrase := Prev_S.Element;
                     First_Syllable : constant Phrase(1..1) := (1 => Prev_Phrase(Prev_Phrase'First));
                  begin
                     S1.Replace_Element(Prev_Phrase & First_Syllable);
                  end;
               else
                  S1.Replace_Element(Dict_C2P.Element(Natural(K)));
               end if;
            end if;
            
            declare
               Current_S1 : constant Phrase := S1.Element;
            begin
               for J in Current_S1'Range loop
                  if Current_S1(J) /= Null_Unbounded_String then
                     if Out_Offset >= Output'Length then
                        raise LZWL_Error with "Output array too small";
                     end if;
                     Output(Output'First + Out_Offset) := Current_S1(J);
                     Out_Offset := Out_Offset + 1;
                  end if;
               end loop;
               
               if Prev_S.Element'Length > 0 then
                  declare
                     Prev_Phrase    : constant Phrase := Prev_S.Element;
                     First_Syllable : constant Phrase(1..1) := (1 => Current_S1(Current_S1'First));
                     New_Phrase     : constant Phrase := Prev_Phrase & First_Syllable;
                  begin
                     if not Dict_P2C.Contains(New_Phrase) then
                        Dict_P2C.Insert(New_Phrase, Next_Code);
                        Dict_C2P.Append(New_Phrase);
                        Next_Code := Next_Code + 1;
                     end if;
                  end;
               end if;
            end;
            
            Prev_S.Replace_Element(S1.Element);
         end;
      end loop;
      
      Output_Len := Out_Offset;
   end Decode_Basic;

   -- =========================================================================
   -- Dictionary Expansion Variant Implementations
   -- =========================================================================
   procedure Encode_Expanded (
      Alphabet   : in Syllable_Array;
      Input      : in Syllable_Array;
      Output     : out Code_Array;
      Output_Len : out Natural)
   is
      Dict_P2C   : Phrase_Maps.Map;
      Dict_C2P   : Code_Vectors.Vector;
      Next_Code  : Code;
      S          : Phrase_Holders.Holder := Phrase_Holders.To_Holder(Empty_Phrase);
      Out_Offset : Natural := 0;
   begin
      Output_Len := 0;
      if Input'Length = 0 then return; end if;
      
      Init_Dict_Expanded(Alphabet, Dict_P2C, Dict_C2P, Next_Code);
      
      for I in Input'Range loop
         declare
            C : constant Phrase(1..1) := (1 => Input(I));
         begin
            if not Dict_P2C.Contains(C) then
               raise LZWL_Error with "Syllable not in alphabet";
            end if;
            
            declare
               Current_S : constant Phrase := S.Element;
               Combined  : constant Phrase := Current_S & C;
            begin
               if Dict_P2C.Contains(Combined) then
                  S.Replace_Element(Combined);
               else
                  if Out_Offset >= Output'Length then
                     raise LZWL_Error with "Output buffer overflow";
                  end if;
                  Output(Output'First + Out_Offset) := Dict_P2C.Element(Current_S);
                  Out_Offset := Out_Offset + 1;
                  
                  Dict_P2C.Insert(Combined, Next_Code);
                  Dict_C2P.Append(Combined);
                  Next_Code := Next_Code + 1;
                  
                  S.Replace_Element(C);
               end if;
            end;
         end;
      end loop;
      
      if S.Element'Length > 0 then
         if Out_Offset >= Output'Length then
            raise LZWL_Error with "Output buffer overflow";
         end if;
         Output(Output'First + Out_Offset) := Dict_P2C.Element(S.Element);
         Out_Offset := Out_Offset + 1;
      end if;
      
      Output_Len := Out_Offset;
   end Encode_Expanded;

   procedure Decode_Expanded (
      Alphabet   : in Syllable_Array;
      Input      : in Code_Array;
      Output     : out Syllable_Array;
      Output_Len : out Natural)
   is
      Dict_P2C   : Phrase_Maps.Map;
      Dict_C2P   : Code_Vectors.Vector;
      Next_Code  : Code;
      Prev_S     : Phrase_Holders.Holder := Phrase_Holders.To_Holder(Empty_Phrase);
      S1         : Phrase_Holders.Holder := Phrase_Holders.To_Holder(Empty_Phrase);
      Out_Offset : Natural := 0;
   begin
      Output_Len := 0;
      if Input'Length = 0 then return; end if;
      
      Init_Dict_Expanded(Alphabet, Dict_P2C, Dict_C2P, Next_Code);
      
      for I in Input'Range loop
         declare
            K : constant Code := Input(I);
         begin
            if I = Input'First then
               if Natural(K) >= Natural(Next_Code) then
                  raise LZWL_Error with "Invalid code detected";
               end if;
               S1.Replace_Element(Dict_C2P.Element(Natural(K)));
            else
               if Natural(K) >= Natural(Next_Code) then
                  declare
                     Prev_Phrase    : constant Phrase := Prev_S.Element;
                     First_Syllable : constant Phrase(1..1) := (1 => Prev_Phrase(Prev_Phrase'First));
                  begin
                     S1.Replace_Element(Prev_Phrase & First_Syllable);
                  end;
               else
                  S1.Replace_Element(Dict_C2P.Element(Natural(K)));
               end if;
            end if;
            
            declare
               Current_S1 : constant Phrase := S1.Element;
            begin
               for J in Current_S1'Range loop
                  if Current_S1(J) /= Null_Unbounded_String then
                     if Out_Offset >= Output'Length then
                        raise LZWL_Error with "Output buffer overflow";
                     end if;
                     Output(Output'First + Out_Offset) := Current_S1(J);
                     Out_Offset := Out_Offset + 1;
                  end if;
               end loop;
               
               if Prev_S.Element'Length > 0 then
                  declare
                     Prev_Phrase    : constant Phrase := Prev_S.Element;
                     First_Syllable : constant Phrase(1..1) := (1 => Current_S1(Current_S1'First));
                     New_Phrase     : constant Phrase := Prev_Phrase & First_Syllable;
                  begin
                     if not Dict_P2C.Contains(New_Phrase) then
                        Dict_P2C.Insert(New_Phrase, Next_Code);
                        Dict_C2P.Append(New_Phrase);
                        Next_Code := Next_Code + 1;
                     end if;
                  end;
               end if;
            end;
            
            Prev_S.Replace_Element(S1.Element);
         end;
      end loop;
      
      Output_Len := Out_Offset;
   end Decode_Expanded;

end LZWL;
