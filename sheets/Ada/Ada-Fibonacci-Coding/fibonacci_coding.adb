package body Fibonacci_Coding is

   -- Pre-compute Fibonacci sequence up to a practical limit for 32-bit integers
   Max_Fib_Index : constant := 45;
   type Fib_Array is array (1 .. Max_Fib_Index) of Positive_Integer;
   
   function Generate_Fibonacci return Fib_Array is
      F : Fib_Array;
   begin
      F (1) := 1;
      F (2) := 2;
      for I in 3 .. Max_Fib_Index loop
         F (I) := F (I - 1) + F (I - 2);
      end loop;
      return F;
   end Generate_Fibonacci;

   Fib : constant Fib_Array := Generate_Fibonacci;

   ------------------------------------------------------
   -- Variant 1: Standard Fibonacci Coding             --
   ------------------------------------------------------

   function Encode_Fibonacci (N : Positive_Integer) return String is
      Current : Natural := N;
      K       : Positive_Integer := 1;
   begin
      -- 1. Find largest Fibonacci number <= N
      for I in Fib'Range loop
         if Fib (I) <= N then
            K := I;
         else
            exit;
         end if;
      end loop;
      
      declare
         -- 2. Allocate exact string length
         Result : String (1 .. K) := (others => '0');
      begin
         -- 3. Greedy subtraction based on Zeckendorf's theorem
         for I in reverse 1 .. K loop
            if Fib (I) <= Current then
               Result (I) := '1';
               Current := Current - Fib (I);
            end if;
         end loop;
         
         -- 4. Standard Fibonacci codes end with an additional padding '1'
         return Result & '1';
      end;
   end Encode_Fibonacci;

   function Decode_Fibonacci (Code : String) return Positive_Integer is
      Sum : Natural := 0;
   begin
      -- Edge Case Validation: must safely end with "11"
      if Code'Length < 2 or else Code (Code'Last - 1 .. Code'Last) /= "11" then
         raise Invalid_Code with "Standard Fibonacci code must end with 11";
      end if;
      
      -- Edge Case Validation: no "11" allowed before the terminator
      for I in Code'First .. Code'Last - 2 loop
         if Code (I) = '1' and then Code (I + 1) = '1' then
            raise Invalid_Code with "Code contains consecutive 1s before the end";
         end if;
      end loop;
      
      -- Calculate dot product of bits and Fibonacci weights
      for I in Code'First .. Code'Last - 1 loop
         if Code (I) = '1' then
            Sum := Sum + Fib (I - Code'First + 1);
         end if;
      end loop;
      
      if Sum = 0 then
         raise Invalid_Code with "Invalid zero sum string";
      end if;
      
      return Sum;
   end Decode_Fibonacci;

   ------------------------------------------------------
   -- Variant 2: Generalized Fibonacci Coding          --
   ------------------------------------------------------

   -- Helper: Generates the next binary string in length-lexicographical order
   function Next_Binary_String (S : String) return String is
      Result : String (1 .. S'Length) := S;
   begin
      if S = "" then
         return "0";
      end if;
      
      for I in reverse Result'Range loop
         if Result (I) = '0' then
            Result (I) := '1';
            return Result;
         else
            Result (I) := '0';
         end if;
      end loop;
      
      -- Overflow: string was all '1's. Next string is all '0's but one character longer.
      declare
         New_Result : String (1 .. S'Length + 1) := (others => '0');
      begin
         return New_Result;
      end;
   end Next_Binary_String;

   -- Helper: Checks if a string exactly conforms to N-Step structural rules
   function Is_Valid_Generalized (S : String; Order : Positive_Integer) return Boolean is
      Target_String : constant String (1 .. Order) := (others => '1');
      Occurrences   : Natural := 0;
   begin
      if S'Length < Order then return False; end if;
      
      -- Must strictly end with N consecutive 1s
      if S (S'Last - Order + 1 .. S'Last) /= Target_String then
         return False;
      end if;
      
      -- Count instances of N consecutive 1s (must be exactly 1, at the end)
      for I in S'First .. S'Last - Order + 1 loop
         if S (I .. I + Order - 1) = Target_String then
            Occurrences := Occurrences + 1;
         end if;
      end loop;
      
      return Occurrences = 1;
   end Is_Valid_Generalized;

   function Encode_Generalized (N : Positive_Integer; Order : Positive_Integer := 3) return String is
      Target_String : constant String (1 .. Order) := (others => '1');
      Count         : Natural := 0;
      Max_Len       : constant := 100;
      Current_Str   : String (1 .. Max_Len) := (others => '0');
      Current_Len   : Natural := 0;
   begin
      -- Lexicographical generation accurately maps values to N-step encodings
      loop
         declare
            Prefix     : String := Current_Str (1 .. Current_Len);
            Candidate  : String := Prefix & Target_String;
         begin
            if Is_Valid_Generalized (Candidate, Order) then
               Count := Count + 1;
               if Count = N then return Candidate; end if;
            end if;
            
            declare
               Next_Prefix : String := Next_Binary_String (Prefix);
            begin
               Current_Len := Next_Prefix'Length;
               Current_Str (1 .. Current_Len) := Next_Prefix;
            end;
         end;
      end loop;
   end Encode_Generalized;

   function Decode_Generalized (Code : String; Order : Positive_Integer := 3) return Positive_Integer is
      Target_String : constant String (1 .. Order) := (others => '1');
      Count         : Natural := 0;
      Max_Len       : constant := 100;
      Current_Str   : String (1 .. Max_Len) := (others => '0');
      Current_Len   : Natural := 0;
   begin
      if not Is_Valid_Generalized (Code, Order) then
         raise Invalid_Code with "String is not a valid Generalized Fibonacci code";
      end if;

      loop
         declare
            Prefix     : String := Current_Str (1 .. Current_Len);
            Candidate  : String := Prefix & Target_String;
         begin
            if Is_Valid_Generalized (Candidate, Order) then
               Count := Count + 1;
               if Candidate = Code then return Count; end if;
            end if;
            
            declare
               Next_Prefix : String := Next_Binary_String (Prefix);
            begin
               Current_Len := Next_Prefix'Length;
               Current_Str (1 .. Current_Len) := Next_Prefix;
               
               if Current_Len > Code'Length then
                  raise Invalid_Code with "Structural sequence bounds exceeded";
               end if;
            end;
         end;
      end loop;
   end Decode_Generalized;

end Fibonacci_Coding;
