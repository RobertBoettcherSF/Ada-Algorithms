package body Data_Encryption_Standard is

   --  Internal Strong Types to prevent accidental slice mismatches
   type Index_64 is new Integer range 1 .. 64;
   type Index_56 is new Integer range 1 .. 56;
   type Index_48 is new Integer range 1 .. 48;
   type Index_32 is new Integer range 1 .. 32;
   type Index_28 is new Integer range 1 .. 28;

   type Block_56 is array (Index_56) of Boolean with Pack;
   type Block_48 is array (Index_48) of Boolean with Pack;
   type Block_32 is array (Index_32) of Boolean with Pack;
   type Block_28 is array (Index_28) of Boolean with Pack;

   type Subkey_Array is array (1 .. 16) of Block_48;

   --  Permutation Table Types
   type Perm_64_64_Table is array (Index_64) of Index_64;
   type Perm_56_64_Table is array (Index_56) of Index_64;
   type Perm_48_56_Table is array (Index_48) of Index_56;
   type Perm_48_32_Table is array (Index_48) of Index_32;
   type Perm_32_32_Table is array (Index_32) of Index_32;

   --  S-Box Types
   type S_Box_Value is mod 16;
   type S_Box_Row is range 0 .. 3;
   type S_Box_Col is range 0 .. 15;
   type S_Box_Table is array (1 .. 8, S_Box_Row, S_Box_Col) of S_Box_Value;

   --  Constants / Lookup Tables 
   IP_Table : constant Perm_64_64_Table :=
     [58, 50, 42, 34, 26, 18, 10, 2, 60, 52, 44, 36, 28, 20, 12, 4,
      62, 54, 46, 38, 30, 22, 14, 6, 64, 56, 48, 40, 32, 24, 16, 8,
      57, 49, 41, 33, 25, 17, 9, 1, 59, 51, 43, 35, 27, 19, 11, 3,
      61, 53, 45, 37, 29, 21, 13, 5, 63, 55, 47, 39, 31, 23, 15, 7];

   FP_Table : constant Perm_64_64_Table :=
     [40, 8, 48, 16, 56, 24, 64, 32, 39, 7, 47, 15, 55, 23, 63, 31,
      38, 6, 46, 14, 54, 22, 62, 30, 37, 5, 45, 13, 53, 21, 61, 29,
      36, 4, 44, 12, 52, 20, 60, 28, 35, 3, 43, 11, 51, 19, 59, 27,
      34, 2, 42, 10, 50, 18, 58, 26, 33, 1, 41, 9, 49, 17, 57, 25];

   PC1_Table : constant Perm_56_64_Table :=
     [57, 49, 41, 33, 25, 17, 9, 1, 58, 50, 42, 34, 26, 18,
      10, 2, 59, 51, 43, 35, 27, 19, 11, 3, 60, 52, 44, 36,
      63, 55, 47, 39, 31, 23, 15, 7, 62, 54, 46, 38, 30, 22,
      14, 6, 61, 53, 45, 37, 29, 21, 13, 5, 28, 20, 12, 4];

   PC2_Table : constant Perm_48_56_Table :=
     [14, 17, 11, 24, 1, 5, 3, 28, 15, 6, 21, 10,
      23, 19, 12, 4, 26, 8, 16, 7, 27, 20, 13, 2,
      41, 52, 31, 37, 47, 55, 30, 40, 51, 45, 33, 48,
      44, 49, 39, 56, 34, 53, 46, 42, 50, 36, 29, 32];

   E_Table : constant Perm_48_32_Table :=
     [32, 1, 2, 3, 4, 5, 4, 5, 6, 7, 8, 9,
      8, 9, 10, 11, 12, 13, 12, 13, 14, 15, 16, 17,
      16, 17, 18, 19, 20, 21, 20, 21, 22, 23, 24, 25,
      24, 25, 26, 27, 28, 29, 28, 29, 30, 31, 32, 1];

   P_Table : constant Perm_32_32_Table :=
     [16, 7, 20, 21, 29, 12, 28, 17, 1, 15, 23, 26, 5, 18, 31, 10,
      2, 8, 24, 14, 32, 27, 3, 9, 19, 13, 30, 6, 22, 11, 4, 25];

   Shift_Table : constant array (1 .. 16) of Natural :=
     [1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1];

   S_Boxes : constant S_Box_Table :=
     [1 => [0 => [14, 4, 13, 1, 2, 15, 11, 8, 3, 10, 6, 12, 5, 9, 0, 7],
            1 => [0, 15, 7, 4, 14, 2, 13, 1, 10, 6, 12, 11, 9, 5, 3, 8],
            2 => [4, 1, 14, 8, 13, 6, 2, 11, 15, 12, 9, 7, 3, 10, 5, 0],
            3 => [15, 12, 8, 2, 4, 9, 1, 7, 5, 11, 3, 14, 10, 0, 6, 13]],
      2 => [0 => [15, 1, 8, 14, 6, 11, 3, 4, 9, 7, 2, 13, 12, 0, 5, 10],
            1 => [3, 13, 4, 7, 15, 2, 8, 14, 12, 0, 1, 10, 6, 9, 11, 5],
            2 => [0, 14, 7, 11, 10, 4, 13, 1, 5, 8, 12, 6, 9, 3, 2, 15],
            3 => [13, 8, 10, 1, 3, 15, 4, 2, 11, 6, 7, 12, 0, 5, 14, 9]],
      3 => [0 => [10, 0, 9, 14, 6, 3, 15, 5, 1, 13, 12, 7, 11, 4, 2, 8],
            1 => [13, 7, 0, 9, 3, 4, 6, 10, 2, 8, 5, 14, 12, 11, 15, 1],
            2 => [13, 6, 4, 9, 8, 15, 3, 0, 11, 1, 2, 12, 5, 10, 14, 7],
            3 => [1, 10, 13, 0, 6, 9, 8, 7, 4, 15, 14, 3, 11, 5, 2, 12]],
      4 => [0 => [7, 13, 14, 3, 0, 6, 9, 10, 1, 2, 8, 5, 11, 12, 4, 15],
            1 => [13, 8, 11, 5, 6, 15, 0, 3, 4, 7, 2, 12, 1, 10, 14, 9],
            2 => [10, 6, 9, 0, 12, 11, 7, 13, 15, 1, 3, 14, 5, 2, 8, 4],
            3 => [3, 15, 0, 6, 10, 1, 13, 8, 9, 4, 5, 11, 12, 7, 2, 14]],
      5 => [0 => [2, 12, 4, 1, 7, 10, 11, 6, 8, 5, 3, 15, 13, 0, 14, 9],
            1 => [14, 11, 2, 12, 4, 7, 13, 1, 5, 0, 15, 10, 3, 9, 8, 6],
            2 => [4, 2, 1, 11, 10, 13, 7, 8, 15, 9, 12, 5, 6, 3, 0, 14],
            3 => [11, 8, 12, 7, 1, 14, 2, 13, 6, 15, 0, 9, 10, 4, 5, 3]],
      6 => [0 => [12, 1, 10, 15, 9, 2, 6, 8, 0, 13, 3, 4, 14, 7, 5, 11],
            1 => [10, 15, 4, 2, 7, 12, 9, 5, 6, 1, 13, 14, 0, 11, 3, 8],
            2 => [9, 14, 15, 5, 2, 8, 12, 3, 7, 0, 4, 10, 1, 13, 11, 6],
            3 => [4, 3, 2, 12, 9, 5, 15, 10, 11, 14, 1, 7, 6, 0, 8, 13]],
      7 => [0 => [4, 11, 2, 14, 15, 0, 8, 13, 3, 12, 9, 7, 5, 10, 6, 1],
            1 => [13, 0, 11, 7, 4, 9, 1, 10, 14, 3, 5, 12, 2, 15, 8, 6],
            2 => [1, 4, 11, 13, 12, 3, 7, 14, 10, 15, 6, 8, 0, 5, 9, 2],
            3 => [6, 11, 13, 8, 1, 4, 10, 7, 9, 5, 0, 15, 14, 2, 3, 12]],
      8 => [0 => [13, 2, 8, 4, 6, 15, 11, 1, 10, 9, 3, 14, 5, 0, 12, 7],
            1 => [1, 15, 13, 8, 10, 3, 7, 4, 12, 5, 6, 11, 0, 14, 9, 2],
            2 => [7, 11, 4, 1, 9, 12, 14, 2, 0, 6, 10, 13, 15, 3, 5, 8],
            3 => [2, 1, 14, 7, 4, 10, 8, 13, 15, 12, 9, 0, 3, 5, 6, 11]]];

   --  Overloaded Strongly-Typed Permutations
   function Permute (Input : Block_Type; Table : Perm_64_64_Table) return Block_Type is
      Output : Block_Type := [others => False];
   begin
      for I in Index_64 loop
         Output(Integer(I)) := Input(Integer(Table(I)));
      end loop;
      return Output;
   end Permute;

   function Permute (Input : Key_Type; Table : Perm_56_64_Table) return Block_56 is
      Output : Block_56 := [others => False];
   begin
      for I in Index_56 loop
         Output(I) := Input(Integer(Table(I)));
      end loop;
      return Output;
   end Permute;

   function Permute (Input : Block_56; Table : Perm_48_56_Table) return Block_48 is
      Output : Block_48 := [others => False];
   begin
      for I in Index_48 loop
         Output(I) := Input(Table(I));
      end loop;
      return Output;
   end Permute;

   function Permute (Input : Block_32; Table : Perm_48_32_Table) return Block_48 is
      Output : Block_48 := [others => False];
   begin
      for I in Index_48 loop
         Output(I) := Input(Table(I));
      end loop;
      return Output;
   end Permute;

   function Permute (Input : Block_32; Table : Perm_32_32_Table) return Block_32 is
      Output : Block_32 := [others => False];
   begin
      for I in Index_32 loop
         Output(I) := Input(Table(I));
      end loop;
      return Output;
   end Permute;

   --  Key Schedule Circular Left Shift
   function Left_Shift (B : Block_28; N : Natural) return Block_28 is
      Result : Block_28 := [others => False];
   begin
      for I in Index_28 loop
         Result(I) := B(Index_28((Integer(I) - 1 + N) mod 28 + 1));
      end loop;
      return Result;
   end Left_Shift;

   --  Generates all 16 round subkeys
   function Generate_Subkeys (Key : Key_Type) return Subkey_Array is
      Subkeys : Subkey_Array;
      C, D    : Block_28;
      PC1_Key : constant Block_56 := Permute(Key, PC1_Table);
   begin
      for I in Index_28 loop
         C(I) := PC1_Key(Index_56(I));
         D(I) := PC1_Key(Index_56(Integer(I) + 28));
      end loop;

      for I in 1 .. 16 loop
         C := Left_Shift(C, Shift_Table(I));
         D := Left_Shift(D, Shift_Table(I));
         
         declare
            Combined : Block_56;
         begin
            for J in Index_28 loop
               Combined(Index_56(J)) := C(J);
               Combined(Index_56(Integer(J) + 28)) := D(J);
            end loop;
            Subkeys(I) := Permute(Combined, PC2_Table);
         end;
      end loop;
      return Subkeys;
   end Generate_Subkeys;

   --  The Feistel Core Function
   function F (R : Block_32; K : Block_48) return Block_32 is
      ER : constant Block_48 := Permute(R, E_Table);
      X  : constant Block_48 := ER xor K;
      Output : Block_32 := [others => False];
      
      Val_Row, Val_Col : Integer;
      Row : S_Box_Row;
      Col : S_Box_Col;
      Val : S_Box_Value;
      Offset_48 : Integer;
      Offset_32 : Integer;
   begin
      for I in 1 .. 8 loop
         Offset_48 := (I - 1) * 6;
         
         Val_Row := (if X(Index_48(Offset_48 + 1)) then 2 else 0) +
                    (if X(Index_48(Offset_48 + 6)) then 1 else 0);
                    
         Val_Col := (if X(Index_48(Offset_48 + 2)) then 8 else 0) +
                    (if X(Index_48(Offset_48 + 3)) then 4 else 0) +
                    (if X(Index_48(Offset_48 + 4)) then 2 else 0) +
                    (if X(Index_48(Offset_48 + 5)) then 1 else 0);
                    
         Row := S_Box_Row(Val_Row);
         Col := S_Box_Col(Val_Col);
         Val := S_Boxes(I, Row, Col);

         Offset_32 := (I - 1) * 4;
         Output(Index_32(Offset_32 + 1)) := (Val and 8) /= 0;
         Output(Index_32(Offset_32 + 2)) := (Val and 4) /= 0;
         Output(Index_32(Offset_32 + 3)) := (Val and 2) /= 0;
         Output(Index_32(Offset_32 + 4)) := (Val and 1) /= 0;
      end loop;
      return Permute(Output, P_Table);
   end F;

   --  Main processing engine for both encrypt and decrypt (controls schedule order)
   function Process_Block (Data : Block_Type; Subkeys : Subkey_Array; Do_Decrypt : Boolean) return Block_Type is
      IP_Data : constant Block_Type := Permute(Data, IP_Table);
      L, R, Next_L, Next_R : Block_32;
      K : Block_48;
      Pre_Output : Block_Type;
   begin
      for I in Index_32 loop
         L(I) := IP_Data(Integer(I));
         R(I) := IP_Data(Integer(I) + 32);
      end loop;

      for I in 1 .. 16 loop
         if Do_Decrypt then
            K := Subkeys(17 - I);
         else
            K := Subkeys(I);
         end if;
         Next_L := R;
         Next_R := L xor F(R, K);
         L := Next_L;
         R := Next_R;
      end loop;

      --  Note: The 32-bit halves are swapped before Final Permutation
      for I in Index_32 loop
         Pre_Output(Integer(I))      := R(I);
         Pre_Output(Integer(I) + 32) := L(I);
      end loop;

      return Permute(Pre_Output, FP_Table);
   end Process_Block;

   -------------------------------------------------------------------------
   --  Public API
   -------------------------------------------------------------------------

   function Encrypt (Data : Block_Type; Key : Key_Type) return Block_Type is
   begin
      return Process_Block(Data, Generate_Subkeys(Key), False);
   end Encrypt;

   function Decrypt (Data : Block_Type; Key : Key_Type) return Block_Type is
   begin
      return Process_Block(Data, Generate_Subkeys(Key), True);
   end Decrypt;

   function Triple_DES_Encrypt (Data : Block_Type; Keys : Key_3_Type) return Block_Type is
   begin
      return Encrypt (Decrypt (Encrypt (Data, Keys(1)), Keys(2)), Keys(3));
   end Triple_DES_Encrypt;

   function Triple_DES_Decrypt (Data : Block_Type; Keys : Key_3_Type) return Block_Type is
   begin
      return Decrypt (Encrypt (Decrypt (Data, Keys(3)), Keys(2)), Keys(1));
   end Triple_DES_Decrypt;

   function Is_Weak_Key (Key : Key_Type) return Boolean is
      Subkeys : constant Subkey_Array := Generate_Subkeys (Key);
   begin
      for I in 2 .. 16 loop
         if Subkeys(I) /= Subkeys(1) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Weak_Key;

   function Adjust_Parity (Key : Key_Type) return Key_Type is
      Result : Key_Type := Key;
      Count  : Natural;
   begin
      for Byte in 0 .. 7 loop
         Count := 0;
         for Bit in 1 .. 7 loop
            if Result(Byte * 8 + Bit) then
               Count := Count + 1;
            end if;
         end loop;
         Result(Byte * 8 + 8) := (Count mod 2 = 0);
      end loop;
      return Result;
   end Adjust_Parity;

   function Assert_Valid_Parity (Key : Key_Type) return Boolean is
      Count : Natural;
   begin
      for Byte in 0 .. 7 loop
         Count := 0;
         for Bit in 1 .. 8 loop
            if Key(Byte * 8 + Bit) then
               Count := Count + 1;
            end if;
         end loop;
         if Count mod 2 = 0 then
            raise Parity_Error;
         end if;
      end loop;
      return True;
   end Assert_Valid_Parity;

end Data_Encryption_Standard;
