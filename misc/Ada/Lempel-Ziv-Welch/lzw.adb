with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Containers.Vectors;
with Ada.Strings.Hash;
with Ada.Strings.Unbounded;

package body LZW is

   use Ada.Strings.Unbounded; -- Makes "=" visible for Vectors instantiation

   -- Map: String -> Code (used for compression)
   package String_To_Code_Maps is new Ada.Containers.Indefinite_Hashed_Maps
     (Key_Type        => String,
      Element_Type    => Code_Type,
      Hash            => Ada.Strings.Hash,
      Equivalent_Keys => "=");

   -- Vector: Code -> String (used for decompression)
   package Code_To_String_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Code_Type,
      Element_Type => Unbounded_String);

   -- Helper: Initialize dictionary with base alphabet (0 to 255)
   procedure Init_Compress_Dict (Map : in out String_To_Code_Maps.Map) is
   begin
      Map.Clear;
      for I in 0 .. 255 loop
         Map.Insert (Key      => (1 => Character'Val (I)),
                     New_Item => Code_Type (I));
      end loop;
   end Init_Compress_Dict;

   procedure Init_Decompress_Dict (Vec : in out Code_To_String_Vectors.Vector) is
   begin
      Vec.Clear;
      for I in 0 .. 255 loop
         Vec.Append (To_Unbounded_String ((1 => Character'Val (I))));
      end loop;
   end Init_Decompress_Dict;


   function Compress (Input    : String;
                      Strategy : Dictionary_Strategy := Freeze;
                      Max_Bits : Positive := 12) return Code_Array is
      
      Map         : String_To_Code_Maps.Map;
      Output      : Code_Array (1 .. Input'Length * 2); -- Safe upper bound for allocation
      Out_Index   : Natural := 0;
      W           : Unbounded_String;
      WK          : Unbounded_String;
      K           : Character;
      Next_Code   : Code_Type := 256;
      Max_Size    : constant Code_Type := 2 ** Max_Bits;
      
   begin
      if Max_Bits < 9 then
         raise LZW_Error with "Max_Bits must be at least 9.";
      end if;

      if Input'Length = 0 then
         return (1 .. 0 => 0);
      end if;

      Init_Compress_Dict (Map);
      W := To_Unbounded_String ((1 => Input (Input'First)));

      for I in Input'First + 1 .. Input'Last loop
         K := Input (I);
         WK := W & K;

         if Map.Contains (To_String (WK)) then
            W := WK;
         else
            Out_Index := Out_Index + 1;
            Output (Out_Index) := Map.Element (To_String (W));

            if Next_Code < Max_Size then
               Map.Insert (To_String (WK), Next_Code);
               Next_Code := Next_Code + 1;
            else
               if Strategy = Clear then
                  Init_Compress_Dict (Map);
                  Next_Code := 256;
               end if;
            end if;
            W := To_Unbounded_String ((1 => K));
         end if;
      end loop;

      Out_Index := Out_Index + 1;
      Output (Out_Index) := Map.Element (To_String (W));

      return Output (1 .. Out_Index);
   end Compress;


   function Decompress (Input    : Code_Array;
                        Strategy : Dictionary_Strategy := Freeze;
                        Max_Bits : Positive := 12) return String is
      
      Vec          : Code_To_String_Vectors.Vector;
      Result       : Unbounded_String;
      Old_Code     : Code_Type;
      New_Code     : Code_Type;
      S            : Unbounded_String;
      Next_Code    : Code_Type := 256;
      Max_Size     : constant Code_Type := 2 ** Max_Bits;
      Just_Cleared : Boolean := False;
      
   begin
      if Max_Bits < 9 then
         raise LZW_Error with "Max_Bits must be at least 9.";
      end if;

      if Input'Length = 0 then
         return "";
      end if;

      Init_Decompress_Dict (Vec);

      Old_Code := Input (Input'First);
      if Old_Code >= 256 then
         raise LZW_Error with "Invalid first code";
      end if;

      S := Vec.Element (Old_Code);
      Append (Result, S);

      for I in Input'First + 1 .. Input'Last loop
         New_Code := Input (I);

         if Just_Cleared then
            Just_Cleared := False;
            Old_Code := New_Code;
            S := Vec.Element (New_Code);
            Append (Result, S);
            goto Continue_Loop; 
         end if;

         if Integer(New_Code) < Integer(Vec.Length) then
            S := Vec.Element (New_Code);
         elsif New_Code = Next_Code then
            S := Vec.Element (Old_Code) & Element (Vec.Element (Old_Code), 1);
         else
            raise LZW_Error with "Invalid LZW code sequence.";
         end if;

         Append (Result, S);

         if Next_Code < Max_Size then
            Vec.Append (Vec.Element (Old_Code) & Element (S, 1));
            Next_Code := Next_Code + 1;
         else
            if Strategy = Clear then
               Init_Decompress_Dict (Vec);
               Next_Code := 256;
               Just_Cleared := True;
            end if;
         end if;
         
         Old_Code := New_Code;
         
         <<Continue_Loop>> null;
      end loop;

      return To_String (Result);
   end Decompress;

end LZW;
