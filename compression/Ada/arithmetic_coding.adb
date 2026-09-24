-- arithmetic_coding.adb
-- Implementation of the Arithmetic Coding algorithms.

with Ada.Containers.Vectors;

package body Arithmetic_Coding is

   -- Internal vector for dynamic bit stream growth
   package Bit_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Bit);

   -- Helper: Extract cumulative frequencies for a symbol
   procedure Get_Cum_Freq (Freq      : in Frequency_Table;
                           Target    : in Character;
                           Cum_Low   : out Natural;
                           Cum_High  : out Natural) is
      Current_Sum : Natural := 0;
   begin
      for C in Character'First .. Character'Last loop
         if C = Target then
            Cum_Low  := Current_Sum;
            Cum_High := Current_Sum + Freq (C);
            return;
         end if;
         Current_Sum := Current_Sum + Freq (C);
      end loop;
   end Get_Cum_Freq;

   -- Helper: Find symbol given a scaled value
   function Find_Symbol (Freq         : Frequency_Table;
                         Scaled_Value : Unsigned_32) return Character is
      Cum_Low  : Natural := 0;
      Cum_High : Natural := 0;
   begin
      for C in Character'First .. Character'Last loop
         Cum_High := Cum_Low + Freq (C);
         if Cum_High > Cum_Low then
            if Scaled_Value >= Unsigned_32 (Cum_Low) and then Scaled_Value < Unsigned_32 (Cum_High) then
               return C;
            end if;
         end if;
         Cum_Low := Cum_High;
      end loop;
      raise Stream_Corrupt_Error with "Scaled value does not match any symbol";
   end Find_Symbol;

   -- Helper: Update Adaptive Model and prevent frequency overflow
   procedure Update_Adaptive_Model (M : in out Adaptive_Model; C : Character) is
      Max_Total : constant Natural := 16#3FFF_FFFF#; 
   begin
      M.Freq (C) := M.Freq (C) + 1;
      M.Total    := M.Total + 1;

      -- If total frequency risks overflow, halve all frequencies
      if M.Total >= Max_Total then
         M.Total := 0;
         for Char in Character'First .. Character'Last loop
            M.Freq (Char) := (M.Freq (Char) / 2) + 1; -- Ensure no zero frequencies
            M.Total := M.Total + M.Freq (Char);
         end loop;
      end if;
   end Update_Adaptive_Model;

   -- =========================================================================
   -- Static Implementation
   -- =========================================================================

   function Build_Static_Model (Data : String) return Static_Model is
      M : Static_Model;
   begin
      if Data'Length = 0 then
         raise Empty_Input_Error with "Cannot build model from empty input";
      end if;
      
      for I in Data'Range loop
         M.Freq (Data (I)) := M.Freq (Data (I)) + 1;
         M.Total := M.Total + 1;
      end loop;
      return M;
   end Build_Static_Model;

   function Static_Encode (Data : String; M : Static_Model) return Bit_Stream is
      Low          : Unsigned_32 := 0;
      High         : Unsigned_32 := Max_Code;
      Pending_Bits : Natural := 0;
      Out_Stream   : Bit_Vectors.Vector;

      procedure Output_Bit (B : Bit) is
      begin
         Out_Stream.Append (B);
      end Output_Bit;

      procedure Rescale is
      begin
         loop
            if High < One_Half then
               Output_Bit (0);
               for I in 1 .. Pending_Bits loop Output_Bit (1); end loop;
               Pending_Bits := 0;
            elsif Low >= One_Half then
               Output_Bit (1);
               for I in 1 .. Pending_Bits loop Output_Bit (0); end loop;
               Pending_Bits := 0;
               Low  := Low - One_Half;
               High := High - One_Half;
            elsif Low >= One_Quarter and then High < Three_Quarters then
               Pending_Bits := Pending_Bits + 1;
               Low  := Low - One_Quarter;
               High := High - One_Quarter;
            else
               exit;
            end if;
            Low  := Low * 2;
            High := High * 2 + 1;
         end loop;
      end Rescale;

   begin
      if Data'Length = 0 then
         return (1 .. 0 => 0);
      end if;

      for I in Data'Range loop
         declare
            C : constant Character := Data (I);
            Cum_Low, Cum_High : Natural;
            Range_Val : Unsigned_64;
         begin
            if M.Freq (C) = 0 then
               raise Invalid_Symbol_Error with "Symbol not in model";
            end if;

            Get_Cum_Freq (M.Freq, C, Cum_Low, Cum_High);
            Range_Val := Unsigned_64 (High) - Unsigned_64 (Low) + 1;
            
            declare
               -- Calculate in 64-bit space to prevent intermediate overflow
               Calc_High : constant Unsigned_64 := (Range_Val * Unsigned_64 (Cum_High)) / Unsigned_64 (M.Total);
               Calc_Low  : constant Unsigned_64 := (Range_Val * Unsigned_64 (Cum_Low)) / Unsigned_64 (M.Total);
            begin
               -- Explicit modulo 2^32 guarantees we satisfy strict Compiler range checks before casting
               High := Low + Unsigned_32 (Calc_High mod 16#1_0000_0000#) - 1;
               Low  := Low + Unsigned_32 (Calc_Low mod 16#1_0000_0000#);
            end;
            
            Rescale;
         end;
      end loop;

      -- Flush remaining bits
      Pending_Bits := Pending_Bits + 1;
      if Low < One_Quarter then
         Output_Bit (0);
         for I in 1 .. Pending_Bits loop Output_Bit (1); end loop;
      else
         Output_Bit (1);
         for I in 1 .. Pending_Bits loop Output_Bit (0); end loop;
      end if;

      declare
         Result : Bit_Stream (1 .. Positive (Out_Stream.Length));
      begin
         for I in Result'Range loop
            Result (I) := Out_Stream.Element (I);
         end loop;
         return Result;
      end;
   end Static_Encode;

   function Static_Decode (Bits : Bit_Stream; M : Static_Model; Output_Length : Natural) return String is
      Low          : Unsigned_32 := 0;
      High         : Unsigned_32 := Max_Code;
      Value        : Unsigned_32 := 0;
      Stream_Idx   : Positive := Bits'First;
      Result       : String (1 .. Output_Length);

      function Read_Bit return Unsigned_32 is
         B : Bit;
      begin
         if Stream_Idx <= Bits'Last then
            B := Bits (Stream_Idx);
            Stream_Idx := Stream_Idx + 1;
            return Unsigned_32 (B);
         else
            return 0; -- Padding with 0s if stream ends
         end if;
      end Read_Bit;

      procedure Rescale is
      begin
         loop
            if High < One_Half then
               null;
            elsif Low >= One_Half then
               Value := Value - One_Half;
               Low   := Low - One_Half;
               High  := High - One_Half;
            elsif Low >= One_Quarter and then High < Three_Quarters then
               Value := Value - One_Quarter;
               Low   := Low - One_Quarter;
               High  := High - One_Quarter;
            else
               exit;
            end if;
            Low   := Low * 2;
            High  := High * 2 + 1;
            Value := Value * 2 + Read_Bit;
         end loop;
      end Rescale;

   begin
      if Output_Length = 0 then
         return "";
      end if;

      -- Initialization
      for I in 1 .. 32 loop
         Value := Value * 2 + Read_Bit;
      end loop;

      for I in 1 .. Output_Length loop
         declare
            Range_Val    : Unsigned_64;
            Scaled_Value : Unsigned_32;
            C            : Character;
            Cum_Low, Cum_High : Natural;
         begin
            Range_Val    := Unsigned_64 (High) - Unsigned_64 (Low) + 1;
            Scaled_Value := Unsigned_32 (((Unsigned_64 (Value) - Unsigned_64 (Low) + 1) * Unsigned_64 (M.Total) - 1) / Range_Val);
            
            C := Find_Symbol (M.Freq, Scaled_Value);
            Result (I) := C;
            
            Get_Cum_Freq (M.Freq, C, Cum_Low, Cum_High);
            declare
               Calc_High : constant Unsigned_64 := (Range_Val * Unsigned_64 (Cum_High)) / Unsigned_64 (M.Total);
               Calc_Low  : constant Unsigned_64 := (Range_Val * Unsigned_64 (Cum_Low)) / Unsigned_64 (M.Total);
            begin
               High := Low + Unsigned_32 (Calc_High mod 16#1_0000_0000#) - 1;
               Low  := Low + Unsigned_32 (Calc_Low mod 16#1_0000_0000#);
            end;
            
            Rescale;
         end;
      end loop;

      return Result;
   end Static_Decode;

   -- =========================================================================
   -- Adaptive Implementation
   -- =========================================================================

   function Adaptive_Encode (Data : String) return Bit_Stream is
      M : Adaptive_Model; -- Starts with 1 for all chars
      Low          : Unsigned_32 := 0;
      High         : Unsigned_32 := Max_Code;
      Pending_Bits : Natural := 0;
      Out_Stream   : Bit_Vectors.Vector;

      procedure Output_Bit (B : Bit) is
      begin
         Out_Stream.Append (B);
      end Output_Bit;
      
      -- Rescale identical to static
      procedure Rescale is
      begin
         loop
            if High < One_Half then
               Output_Bit (0);
               for I in 1 .. Pending_Bits loop Output_Bit (1); end loop;
               Pending_Bits := 0;
            elsif Low >= One_Half then
               Output_Bit (1);
               for I in 1 .. Pending_Bits loop Output_Bit (0); end loop;
               Pending_Bits := 0;
               Low  := Low - One_Half;
               High := High - One_Half;
            elsif Low >= One_Quarter and then High < Three_Quarters then
               Pending_Bits := Pending_Bits + 1;
               Low  := Low - One_Quarter;
               High := High - One_Quarter;
            else
               exit;
            end if;
            Low  := Low * 2;
            High := High * 2 + 1;
         end loop;
      end Rescale;
   begin
      if Data'Length = 0 then
         return (1 .. 0 => 0);
      end if;

      for I in Data'Range loop
         declare
            C : constant Character := Data (I);
            Cum_Low, Cum_High : Natural;
            Range_Val : Unsigned_64;
         begin
            Get_Cum_Freq (M.Freq, C, Cum_Low, Cum_High);
            Range_Val := Unsigned_64 (High) - Unsigned_64 (Low) + 1;
            
            declare
               Calc_High : constant Unsigned_64 := (Range_Val * Unsigned_64 (Cum_High)) / Unsigned_64 (M.Total);
               Calc_Low  : constant Unsigned_64 := (Range_Val * Unsigned_64 (Cum_Low)) / Unsigned_64 (M.Total);
            begin
               High := Low + Unsigned_32 (Calc_High mod 16#1_0000_0000#) - 1;
               Low  := Low + Unsigned_32 (Calc_Low mod 16#1_0000_0000#);
            end;
            
            Rescale;
            Update_Adaptive_Model (M, C);
         end;
      end loop;

      Pending_Bits := Pending_Bits + 1;
      if Low < One_Quarter then
         Output_Bit (0);
         for I in 1 .. Pending_Bits loop Output_Bit (1); end loop;
      else
         Output_Bit (1);
         for I in 1 .. Pending_Bits loop Output_Bit (0); end loop;
      end if;

      declare
         Result : Bit_Stream (1 .. Positive (Out_Stream.Length));
      begin
         for I in Result'Range loop Result (I) := Out_Stream.Element (I); end loop;
         return Result;
      end;
   end Adaptive_Encode;

   function Adaptive_Decode (Bits : Bit_Stream; Output_Length : Natural) return String is
      M            : Adaptive_Model;
      Low          : Unsigned_32 := 0;
      High         : Unsigned_32 := Max_Code;
      Value        : Unsigned_32 := 0;
      Stream_Idx   : Positive := Bits'First;
      Result       : String (1 .. Output_Length);

      function Read_Bit return Unsigned_32 is
      begin
         if Stream_Idx <= Bits'Last then
            declare B : constant Bit := Bits (Stream_Idx);
            begin Stream_Idx := Stream_Idx + 1; return Unsigned_32 (B); end;
         else return 0; end if;
      end Read_Bit;

      procedure Rescale is
      begin
         loop
            if High < One_Half then null;
            elsif Low >= One_Half then
               Value := Value - One_Half; Low := Low - One_Half; High := High - One_Half;
            elsif Low >= One_Quarter and then High < Three_Quarters then
               Value := Value - One_Quarter; Low := Low - One_Quarter; High := High - One_Quarter;
            else exit; end if;
            Low   := Low * 2;
            High  := High * 2 + 1;
            Value := Value * 2 + Read_Bit;
         end loop;
      end Rescale;
   begin
      if Output_Length = 0 then return ""; end if;
      
      for I in 1 .. 32 loop Value := Value * 2 + Read_Bit; end loop;

      for I in 1 .. Output_Length loop
         declare
            Range_Val    : Unsigned_64;
            Scaled_Value : Unsigned_32;
            C            : Character;
            Cum_Low, Cum_High : Natural;
         begin
            Range_Val    := Unsigned_64 (High) - Unsigned_64 (Low) + 1;
            Scaled_Value := Unsigned_32 (((Unsigned_64 (Value) - Unsigned_64 (Low) + 1) * Unsigned_64 (M.Total) - 1) / Range_Val);
            
            C := Find_Symbol (M.Freq, Scaled_Value);
            Result (I) := C;
            
            Get_Cum_Freq (M.Freq, C, Cum_Low, Cum_High);
            declare
               Calc_High : constant Unsigned_64 := (Range_Val * Unsigned_64 (Cum_High)) / Unsigned_64 (M.Total);
               Calc_Low  : constant Unsigned_64 := (Range_Val * Unsigned_64 (Cum_Low)) / Unsigned_64 (M.Total);
            begin
               High := Low + Unsigned_32 (Calc_High mod 16#1_0000_0000#) - 1;
               Low  := Low + Unsigned_32 (Calc_Low mod 16#1_0000_0000#);
            end;
            
            Rescale;
            Update_Adaptive_Model (M, C);
         end;
      end loop;
      return Result;
   end Adaptive_Decode;

end Arithmetic_Coding;
